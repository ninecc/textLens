#!/bin/zsh
set -euo pipefail

APP=$("$(dirname "$0")/build_app.sh" | tail -n 1)
open "$APP"
