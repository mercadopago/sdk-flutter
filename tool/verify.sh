#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
readonly HOST_OS="$(uname -s)"

native_mode="auto"

usage() {
  cat <<'EOF'
Usage: ./tool/verify.sh [option]

Runs the package's complete local verification gate. Native release builds are
enabled by default: Android is built on Linux and macOS, while iOS is also built
on macOS.

Options:
  --with-native     Build every native target supported by this host (default).
  --without-native  Skip Android and iOS release builds.
  --android-only    Build only the Android release APK.
  --ios-only        Build only the iOS no-codesign release app (macOS only).
  -h, --help        Show this help message.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 2
}

run_step() {
  local description="$1"
  shift
  printf '\n==> %s\n' "${description}"
  "$@"
}

run_in_example() {
  (
    cd "${REPO_ROOT}/example"
    "$@"
  )
}

run_in_example_android() {
  (
    cd "${REPO_ROOT}/example/android"
    "$@"
  )
}

while (($# > 0)); do
  case "$1" in
    --with-native)
      native_mode="auto"
      ;;
    --without-native)
      native_mode="none"
      ;;
    --android-only)
      native_mode="android"
      ;;
    --ios-only)
      native_mode="ios"
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

build_android=false
build_ios=false

case "${native_mode}" in
  auto)
    case "${HOST_OS}" in
      Darwin)
        build_android=true
        build_ios=true
        ;;
      Linux)
        build_android=true
        ;;
      *)
        die "native builds are unsupported on ${HOST_OS}; use --without-native"
        ;;
    esac
    ;;
  android)
    build_android=true
    ;;
  ios)
    [[ "${HOST_OS}" == "Darwin" ]] || die "iOS builds require macOS"
    build_ios=true
    ;;
  none) ;;
esac

for command_name in dart flutter python3; do
  command -v "${command_name}" >/dev/null 2>&1 ||
    die "required command not found: ${command_name}"
done

if [[ "${build_android}" == true ]] && ! java -version >/dev/null 2>&1; then
  readonly ANDROID_STUDIO_JBR="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
  if [[ "${HOST_OS}" == "Darwin" && -x "${ANDROID_STUDIO_JBR}/bin/java" ]]; then
    export JAVA_HOME="${ANDROID_STUDIO_JBR}"
    export PATH="${JAVA_HOME}/bin:${PATH}"
  else
    die "Android verification requires a Java runtime"
  fi
fi

cd "${REPO_ROOT}"

run_step "Resolve package dependencies" flutter pub get
run_step "Resolve example dependencies" run_in_example flutter pub get
run_step "Check Dart formatting" \
  dart format --output=none --set-exit-if-changed lib test example/lib
run_step "Analyze package" flutter analyze
run_step "Analyze example" run_in_example flutter analyze
run_step "Run tests with coverage" flutter test --coverage

printf '\n==> Enforce focused coverage\n'
python3 <<'PY'
from pathlib import Path

minimum = 80.0
markers = {
    "domain": "lib/src/domain/",
    "core_methods": "lib/src/core_methods/",
    # The PCI library holds the card-value boundary and tokenization request
    # assembly. It must stay gated independently from the other SDK layers.
    "pci": "lib/src/pci/",
}
totals = {name: {"found": 0, "hit": 0} for name in markers}
current = None

report = Path("coverage/lcov.info")
if not report.is_file():
    raise SystemExit("coverage/lcov.info was not generated")

for raw_line in report.read_text(encoding="utf-8").splitlines():
    if raw_line.startswith("SF:"):
        source = raw_line[3:].replace("\\", "/")
        current = next(
            (name for name, marker in markers.items() if marker in source),
            None,
        )
    elif current is not None and raw_line.startswith("DA:"):
        _, payload = raw_line.split(":", 1)
        _, hits, *_ = payload.split(",")
        totals[current]["found"] += 1
        totals[current]["hit"] += int(hits) > 0

failed = False
for name, counts in totals.items():
    found = counts["found"]
    if found == 0:
        print(f"error: no instrumented lines found for {markers[name]}")
        failed = True
        continue

    percent = counts["hit"] * 100 / found
    print(f"{name}: {percent:.2f}% ({counts['hit']}/{found})")
    if percent < minimum:
        print(
            f"error: {name} coverage {percent:.2f}% is below "
            f"the required {minimum:.0f}%"
        )
        failed = True

raise SystemExit(1 if failed else 0)
PY

run_step "Validate pub.dev archive" dart pub publish --dry-run

if [[ "${build_android}" == true ]]; then
  run_step "Run Android plugin unit tests" \
    run_in_example_android \
    ./gradlew :mercadopago:testDebugUnitTest --no-daemon --console=plain
  run_step "Build Android release APK" \
    run_in_example flutter build apk --release
fi

if [[ "${build_ios}" == true ]]; then
  run_step "Build iOS release app without codesigning" \
    run_in_example flutter build ios --release --no-codesign
fi

printf '\nVerification passed.\n'
