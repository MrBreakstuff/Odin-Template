#!/usr/bin/env bash

cd -- "$(dirname -- "${BASH_SOURCE[0]}")" || exit 1

OUT_DIR="build"
EXE_NAME="myapp"
SRC_DIR="src"
RAD_PROJ="myapp.linux.raddbg"

OPTIMIZATION="-o:none"
SYMBOLS=(-debug)
RELEASE=0
ACTION="build"

# Parse arguments
for ARG in "$@"; do
    case "$(printf '%s' "$ARG" | tr '[:upper:]' '[:lower:]')" in
        release)
            RELEASE=1
            ;;
        run)
            if [[ "$ACTION" == "debug" ]]; then
                echo "Cannot combine run and debug." >&2
                exit 1
            fi
            ACTION="run"
            ;;
        debug)
            if [[ "$ACTION" == "run" ]]; then
                echo "Cannot combine run and debug." >&2
                exit 1
            fi
            ACTION="debug"
            ;;
        *)
            echo "Unknown argument: $ARG" >&2
            exit 1
            ;;
    esac
done

# Configure build
if [[ "$RELEASE" -eq 1 ]]; then
    OPTIMIZATION="-o:speed"
    SYMBOLS=()
fi

if [[ "$ACTION" == "debug" ]]; then
    SYMBOLS=(-debug)
fi

# Build executable
mkdir -p "$OUT_DIR" || exit $?

odin build "$SRC_DIR" \
    -out:"$OUT_DIR/$EXE_NAME" \
    "$OPTIMIZATION" \
    "${SYMBOLS[@]}" \
    -vet \
    -strict-style || exit $?

# Post-build action
case "$ACTION" in
    build)
        exit 0
        ;;
    run)
        exec "$OUT_DIR/$EXE_NAME"
        ;;
    debug)
        ;;
esac

# Debugger selection
if [[ "$(uname -s)" == "Linux" ]] &&
   command -v raddbg >/dev/null 2>&1; then

    if [[ ! -f "$RAD_PROJ" ]]; then
        cat > "$RAD_PROJ" <<EOF
// raddbg project file
name: "Odin Project"
target: {
    executable: "$OUT_DIR/$EXE_NAME"
    working_directory: "."
    enabled: 1
}
EOF
        if [[ $? -ne 0 ]]; then
            exit 1
        fi
    fi

    raddbg "$RAD_PROJ" &
    exit $?

elif [[ "$(uname -s)" == "Darwin" ]] &&
     command -v lldb >/dev/null 2>&1; then

    exec lldb "$OUT_DIR/$EXE_NAME"

elif command -v gdb >/dev/null 2>&1; then

    exec gdb "$OUT_DIR/$EXE_NAME"

elif command -v lldb >/dev/null 2>&1; then

    exec lldb "$OUT_DIR/$EXE_NAME"

else
    echo "No supported debugger found in PATH." >&2
    exit 1
fi
