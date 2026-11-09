#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
SDK="$ROOT/.tooling/flutter"

# The stable-25_05 Nix Flutter SDK is older than this project's dependencies.
# Keep the compatible SDK cached locally and out of version control.
if [[ ! -x "$SDK/bin/flutter" ]]; then
  git clone --depth 1 --branch 3.47.9 https://github.com/flutter/flutter.git "$SDK"
fi

cd "$ROOT/Satark_2"
"$SDK/bin/flutter" pub get
"$SDK/bin/flutter" build web --no-pub --no-wasm-dry-run
exec python3 "$ROOT/scripts/serve.py"
