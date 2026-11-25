#!/bin/bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

if /usr/bin/pgrep -x DrumKey >/dev/null 2>&1; then
    printf 'Quit DrumKey before rebuilding its app bundle.\n' >&2
    exit 1
fi

export CLANG_MODULE_CACHE_PATH="$repo_dir/.build/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$repo_dir/.build/ModuleCache"

swift build --configuration release --disable-sandbox --cache-path "$repo_dir/.build/cache"
binary_dir="$(swift build --configuration release --disable-sandbox --cache-path "$repo_dir/.build/cache" --show-bin-path)"
app_bundle="$repo_dir/build/DrumKey.app"

mkdir -p "$app_bundle/Contents/MacOS"
cp "$binary_dir/DrumKey" "$app_bundle/Contents/MacOS/DrumKey"
cp "$repo_dir/Packaging/Info.plist" "$app_bundle/Contents/Info.plist"
chmod +x "$app_bundle/Contents/MacOS/DrumKey"

# Certificate signing preserves identity across updates. The local fallback
# has a content-hash identity, so a rebuild may need renewed permission.
signing_identity="${DRUMKEY_SIGNING_IDENTITY:--}"
codesign --force --sign "$signing_identity" --identifier local.drumkey.app "$app_bundle"
codesign --verify --strict "$app_bundle"
printf 'Built %s\n' "$app_bundle"
if [ "$signing_identity" = "-" ]; then
    printf 'Local ad-hoc build. Re-add this app in Input Monitoring if access stops after an update.\n'
fi
