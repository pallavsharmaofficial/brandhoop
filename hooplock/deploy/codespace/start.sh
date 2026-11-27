#!/usr/bin/env bash
# Starts the HoopLock test server every time the codespace starts, and prints the address + login.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SERVER="$HERE/../../server"
ENVF="$HERE/.env.local"
INFO="$HERE/../../../HOOPLOCK-TEST-SERVER.txt"

sudo service postgresql start > /dev/null

# Secrets are made once and kept in this codespace only (git-ignored).
if [ ! -f "$ENVF" ]; then
  {
    echo "JWT_SECRET=$(openssl rand -hex 32)"
    echo "ADMIN_PHONE=${HOOPLOCK_ADMIN_PHONE:-9999999999}"
    echo "ADMIN_PASSWORD=$(openssl rand -base64 12 | tr -dc 'A-Za-z0-9' | head -c 12)"
  } > "$ENVF"
fi
set -a; . "$ENVF"; set +a

DOMAIN="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
export PUBLIC_URL="https://${CODESPACE_NAME:-localhost}-8080.${DOMAIN}"
export DATABASE_URL="postgres://hooplock:hooplock@localhost:5432/hooplock"
export NODE_ENV=production PORT=8080
export AGENT_APK_URL="https://pallavsharmaofficial.github.io/hooplock/agent/hooplock-agent.apk"
export AGENT_SIGNATURE_CHECKSUM="yX2RBYc2wS6WHuSHBgmIHJNz1J3QSrScV4_Sdu-fRhA"

pkill -f "node dist/src/index.js" 2>/dev/null || true
cd "$SERVER"
nohup node dist/src/index.js > "$HERE/server.log" 2>&1 &

# Phones must reach the server without a GitHub login.
for i in 1 2 3 4 5; do
  sleep 3
  gh codespace ports visibility 8080:public -c "${CODESPACE_NAME:-}" > /dev/null 2>&1 && break
done

ok="no"
for i in $(seq 1 20); do curl -fs localhost:8080/healthz > /dev/null && ok="yes" && break; sleep 1; done

cat > "$INFO" <<TXT
HoopLock TEST server (this codespace)
=====================================
Server address : $PUBLIC_URL
Running        : $ok   (log: hooplock/deploy/codespace/server.log)

Shop app       : https://pallavsharmaofficial.github.io/hooplock/app/
                 Sign-in screen > "Connect to real server" > paste the server address above.

Admin login    : $ADMIN_PHONE
Admin password : $ADMIN_PASSWORD
                 (change both later in the app: Profile)

Keep this codespace open during the test. If it stops, open it again: the address,
data and phones stay the same.
TXT
cat "$INFO"
