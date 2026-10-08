#!/bin/zsh
set -eu
# Reproduce el identificador y los esquemas del anfitrión; restaura ambos archivos.
task_root="$(cd "$(dirname "$0")/.." && pwd)"
task_plist="$task_root/example/ios/Runner/Info.plist"
task_project="$task_root/example/ios/Runner.xcodeproj/project.pbxproj"
task_backup="$(mktemp -d /tmp/msal-production-host.XXXXXX)"
cp "$task_plist" "$task_backup/Info.plist"
cp "$task_project" "$task_backup/project.pbxproj"
trap 'cp "$task_backup/Info.plist" "$task_plist"; cp "$task_backup/project.pbxproj" "$task_project"; rm -rf "$task_backup"' EXIT
python3 - "$task_plist" "$task_project" <<'PY'
import plistlib, sys
from pathlib import Path
path = Path(sys.argv[1])
config = plistlib.loads(path.read_bytes())
config['CFBundleURLTypes'] = [{'CFBundleURLSchemes': [
    'msal701e9fb7-feb3-4832-a4d7-a706dbe54c40',
    'msauth.com.otis.es.schindlerSVT',
    'msal03afca2b-f47f-4d0b-9a25-d464aff5d351'
]}]
path.write_bytes(plistlib.dumps(config))
project = Path(sys.argv[2])
project.write_text(project.read_text().replace('com.example.a', 'com.otis.es.schindlerSVT'))
PY
cd "$task_root/example/ios"
xcodebuild test -workspace Runner.xcworkspace -scheme Runner -configuration Debug \
  -destination "${MSAL_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 14 Plus}" \
  -only-testing:RunnerTests -packageAuthorizationProvider netrc "$@"
