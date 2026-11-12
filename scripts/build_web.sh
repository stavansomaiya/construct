#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
SDK="$ROOT/.tooling/flutter"

# The built-in Nix Flutter package is too old for this project's dependencies.
# Deployment builds start clean, so install the same pinned SDK used in preview.
if [[ ! -x "$SDK/bin/flutter" ]]; then
  git clone --depth 1 --branch 3.47.9 https://github.com/flutter/flutter.git "$SDK"
fi

cd "$ROOT/Satark_2"
"$SDK/bin/flutter" pub get
"$SDK/bin/flutter" build web --release --base-href "/" --no-wasm-dry-run
touch build/web/.nojekyll
