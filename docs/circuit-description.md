# Circuit description

All values are nominal. Numbers marked (sim) come from the LTspice run; the rest are design calculations.

## 1. Power and actuator driver

- A 12 V DC adapter feeds the solenoid and a 7805 regulator, which supplies the 5 V logic and reference networks. The LM358 and LM339 run from 12 V; LM339 pull-ups go to 5 V. Bulk and local decoupling (100 µF, 10 µF, 100 nF) are used.
- An **IRLZ44N** switches the coil on the low side; its source returns through a **0.22 Ω / 1 W shunt**.
- A **1N5408 flyback diode** sits across the coil (cathode at the load positive terminal), so turn-off current circulates outside the shunt.
- Two 220 Ω resistors in parallel give about 110 Ω gate resistance; 100 kΩ holds the gate low.
- S4 selects the command (0 or 5 V). S5 can instead force the gate to 5 V with the command OFF (stuck-driver test). S1 opens the load for a genuine open-load test.

## 2. Current measurement

An LM358 non-inverting stage (150 kΩ / 10 kΩ) has gain 16. A 1 kΩ / 1 µF filter (τ = 1 ms, fc ≈ 159 Hz) removes short spikes.

```
Vshunt = 0.22 · Icoil
Vsense = (1 + 150k/10k) · Vshunt = 3.52 · Icoil
```

At 0.40 A: 88 mV across the shunt, 1.408 V at the amplifier output. The shunt dissipates about 35 mW. Simulated normal coil current is 0.39565 A with a filtered sense voltage of 1.42756 V (the model includes a 2 mV input offset, giving about 0.035 V residual at zero current).

## 3. Threshold comparators

Three LM339 channels compare the filtered voltage with references set by 10 kΩ trimpots (open-collector outputs, 10 kΩ pull-ups to 5 V):

| Reference | Rule | Example, 0.40 A coil | Equivalent current |
|---|---|---|---|
| LOW | 0.60 · VN | 0.845 V | 0.24 A |
| HIGH | 1.50 · VN | 2.112 V | 0.60 A |
| PRESENT | max(0.15 · VN, 0.20 V) | 0.211 V | 0.06 A |

VN is the measured warm normal sense voltage. There is no hysteresis on these three, so chatter is possible right at a threshold. A 2 mV input offset shifts a boundary by about 9 mA, so the boundaries are deliberately broad rather than precise.

## 4. Command qualification

A 100 kΩ / 1 µF network feeds a fourth LM339 channel with 10 kΩ input resistor, 470 kΩ positive feedback and a 2.5 V reference, giving a delayed command `D`.

- Ideal RC half-supply estimate: 69.3 ms.
- With comparator feedback loading: **79.08 ms** rising delay (sim); about 78.8 ms rising and 79.2 ms falling by calculation.

This delay applies to command transitions only. A current fault arising during an already qualified ON state is not delayed by it.

## 5. Fault logic

```
Q       = C AND D
OFF_ARM = NOT(C OR D)
FU      = Q AND LOW            undercurrent / open load
FO      = Q AND HIGH           overcurrent
FS      = OFF_ARM AND PRESENT  current while commanded OFF
NORMAL  = Q AND NOT(LOW OR HIGH)
FAULT   = FU OR FO OR FS
```

Gating on `C` and `D` agreeing suppresses indications while they disagree, so the current rise after turn-on and the decay after turn-off do not raise false alarms. Implemented with two 74HC08, one 74HC32 and one 74HC04. FAULT drives a 2N3904, which switches a 5 V active buzzer.

## 6. Low-power commissioning

Selector S2 swaps the comparator input between the amplifier output (NORMAL) and a test node (TEST). The test node is a divider from ground through 10 kΩ + 33 Ω, and from 5 V through 1 kΩ + 33 Ω (switch S3):

```
S3 open   -> about 0 V     (checks FU path)
S3 closed -> 5 · 10033 / 11066 = 4.533 V   (checks FO path)   (sim: 4.5317 V)
Itest = 0.452 mA, each 33 Ω resistor dissipates about 6.7 µW
```

This is why 1/4 W parts suffice. A single 33 Ω resistor across 12 V would dissipate 4.36 W, which is why the 33 Ω parts are not used as load fault resistors. The injected test checks the comparator, logic and alarm chain; it does not create real overcurrent and does not verify the amplifier transfer. During the high test, real coil current stays at 0.39560 A (sim).

## 7. Coil model used for analysis

For a stationary plunger, `i(t) = I∞ (1 − e^(−t/τL))` with `τL = L/RΣ`. With L = 0.1 H and RΣ ≈ 30.22 Ω, τL ≈ 3.3 ms and I∞ ≈ 0.397 A, so current reaches the 0.24 A LOW boundary in about 3.1 ms, well inside the qualification delay. Real inductance changes with plunger position, so this is not a general settling time.

## 8. What this does not cover

Plunger travel, flow, temperature rise, tolerance corners, fuse coordination, adapter current limiting, and current paths that bypass the shunt. An OFF-state mismatch indicates sensed conduction but does not uniquely identify a failed MOSFET, and low current cannot distinguish an open winding from every other cause.
