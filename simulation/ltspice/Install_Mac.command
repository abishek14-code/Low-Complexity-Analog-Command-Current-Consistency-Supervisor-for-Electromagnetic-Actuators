#!/bin/zsh
set -eu
task_dir="$(cd "$(dirname "$0")" && pwd)"
lt_library="$HOME/Library/Application Support/LTspice/lib"
mkdir -p "$lt_library/sym/UnifiedSupervisor20261028" "$lt_library/sub"
cp "$task_dir/UnifiedSupervisor20261028/"*.asy "$lt_library/sym/UnifiedSupervisor20261028/"
cp "$task_dir/UnifiedSupervisor20261028.lib" "$lt_library/sub/UnifiedSupervisor20261028.lib"
echo "Installed this project's symbols and models. Close and reopen LTspice, then open Unified_Supervisor.asc."
