#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
mkdir -p "$ROOT/Vendor"

if [ ! -d "$ROOT/Vendor/zsign/.git" ]; then
  git clone https://github.com/zhlynn/zsign.git "$ROOT/Vendor/zsign"
fi

cd "$ROOT/Vendor/zsign"
git fetch --depth 1 origin 614caa8d1ca949e260e5746144aa52d27a4b08d6
git checkout --detach 614caa8d1ca949e260e5746144aa52d27a4b08d6

echo "zsign pinned at $(git rev-parse HEAD)"
