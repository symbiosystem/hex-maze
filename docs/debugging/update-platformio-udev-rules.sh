#!/usr/bin/env bash
set -euo pipefail

RULES_URL="https://raw.githubusercontent.com/platformio/platformio-core/develop/platformio/assets/system/99-platformio-udev.rules"
RULES_PATH="/etc/udev/rules.d/99-platformio-udev.rules"

curl -fsSL "${RULES_URL}" | sudo tee "${RULES_PATH}" >/dev/null
sudo udevadm control --reload-rules
sudo udevadm trigger

cat <<'EOF'
PlatformIO udev rules updated.

Next steps:
1. Unplug and replug the Pico USB cable.
2. If serial/flash permissions still fail, run:
   sudo usermod -a -G dialout,plugdev "$USER"
3. If you changed groups, log out and back in before retrying.
EOF
