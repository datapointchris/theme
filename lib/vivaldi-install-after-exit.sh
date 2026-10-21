#!/usr/bin/env bash
# Install the staged theme into Vivaldi once the Vivaldi holding the given
# user-data dir has exited. Started detached by apply_vivaldi.
# Usage: vivaldi-install-after-exit.sh <user-data-dir>

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/vivaldi-preferences.sh"

vivaldi_install_after_exit "$1"
