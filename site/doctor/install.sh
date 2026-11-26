#!/bin/sh
# Installs the Brandhoop Phone Doctor bridge in Termux. Run it from Termux:
#   pkg update -y && pkg install -y python android-tools curl && curl -fsSL https://pallavsharmaofficial.github.io/brandhoop/doctor/install.sh | sh
set -e
D="$HOME/brandhoop-bridge"
mkdir -p "$D"
curl -fsSL https://pallavsharmaofficial.github.io/brandhoop/doctor/bridge.py -o "$D/bridge.py"
BIN="${PREFIX:-/usr/local}/bin"
printf '#!/bin/sh\nexec python3 "$HOME/brandhoop-bridge/bridge.py"\n' > "$BIN/bhdoctor"
chmod +x "$BIN/bhdoctor"
echo ""
echo "तैयार। अब चलाइए:  bhdoctor"
