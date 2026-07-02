#!/bin/zsh
set -euo pipefail

APP=$("$(dirname "$0")/build_app.sh")
open "$APP"
