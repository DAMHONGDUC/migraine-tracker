# Shared by every tool/ script.

cd "${MELOS_ROOT_PATH:-.}"

# Colour on unless `NO_COLOR` (no-color.org) says otherwise.
if [ -z "${NO_COLOR:-}" ]; then
  C_STEP=$(printf '\033[1;36m')
  C_WARN=$(printf '\033[1;33m')
  C_DONE=$(printf '\033[1;32m')
  C_OFF=$(printf '\033[0m')
else
  C_STEP=''
  C_WARN=''
  C_DONE=''
  C_OFF=''
fi

# `flutter` is a shell alias for `fvm flutter` on a dev machine, and aliases do not exist inside a script — resolve it or we run the wrong SDK.
if [ -f .fvmrc ] && command -v fvm >/dev/null 2>&1; then
  FL="fvm flutter"
  DT="fvm dart"
else
  FL="flutter"
  DT="dart"
fi

step() { printf '%s==> %s%s\n' "$C_STEP" "$1" "$C_OFF"; }
warn() { printf '%s    %s%s\n' "$C_WARN" "$1" "$C_OFF"; }
done_msg() { printf '%s%s%s\n' "$C_DONE" "$1" "$C_OFF"; }
