#!/bin/sh
# Downloads BeeWare's Python-Apple-support package for iOS and unpacks
# Python.xcframework into Frameworks/ (gitignored). The xcframework carries the
# standard library; the "Process Python libraries" build phase copies it into the
# app bundle. Idempotent: does nothing when the pinned build is already there.
#
# Usage: tools/fetch_python.sh [--force]

set -eu

PYTHON_VERSION="3.14"
SUPPORT_BUILD="b14"
SHA256="703ff822529f46edcbcd8b88096b2544f6990f3109ad38b4b4b61bb489a7c1ee"

TAG="$PYTHON_VERSION-$SUPPORT_BUILD"
ARCHIVE="Python-$PYTHON_VERSION-iOS-support.$SUPPORT_BUILD.tar.gz"
URL="https://github.com/beeware/Python-Apple-support/releases/download/$TAG/$ARCHIVE"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/Frameworks"
FRAMEWORK="$DEST/Python.xcframework"
STAMP="$FRAMEWORK/.support-version"

if [ "${1:-}" != "--force" ] && [ -f "$STAMP" ] && [ "$(cat "$STAMP")" = "$TAG" ]; then
    echo "Python.xcframework $TAG already in Frameworks/"
    exit 0
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/fetch_python.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

echo "Downloading $ARCHIVE"
curl --fail --location --silent --show-error --output "$WORK/$ARCHIVE" "$URL"

ACTUAL="$(shasum -a 256 "$WORK/$ARCHIVE" | cut -d ' ' -f 1)"
if [ "$ACTUAL" != "$SHA256" ]; then
    echo "error: checksum mismatch for $ARCHIVE" >&2
    echo "  expected $SHA256" >&2
    echo "  got      $ACTUAL" >&2
    exit 1
fi

mkdir -p "$WORK/unpacked"
tar -xzf "$WORK/$ARCHIVE" -C "$WORK/unpacked" Python.xcframework VERSIONS
rm "$WORK/$ARCHIVE"

mkdir -p "$DEST"
rm -rf "$FRAMEWORK"
mv "$WORK/unpacked/Python.xcframework" "$FRAMEWORK"
cp "$WORK/unpacked/VERSIONS" "$FRAMEWORK/VERSIONS"
echo "$TAG" > "$STAMP"

echo "Installed Python.xcframework $TAG ($(du -sh "$FRAMEWORK" | cut -f 1)) in Frameworks/"
