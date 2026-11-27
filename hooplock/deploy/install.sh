#!/usr/bin/env bash
# HoopLock permanent server, one command, on a fresh Ubuntu/Debian server (Oracle Cloud Always Free,
# Hostinger, DigitalOcean, ...). Open ports 80 and 443 first.
#
#   curl -fsSL https://raw.githubusercontent.com/pallavsharmaofficial/brandhoop/claude/keen-ptolemy-7q2r65/hooplock/deploy/install.sh | sudo bash
#
# Optional: DOMAIN=lock.yourshop.in ADMIN_PHONE=9xxxxxxxxx (before "sudo bash" use: sudo DOMAIN=... bash)
# Without a domain it uses <server-ip>.sslip.io, which works with HTTPS straight away.
set -euo pipefail
BRANCH="${BRANCH:-claude/keen-ptolemy-7q2r65}"
DIR=/opt/hooplock

echo "== Installing Docker"
if ! command -v docker >/dev/null; then curl -fsSL https://get.docker.com | sh; fi
apt-get install -y -qq git >/dev/null 2>&1 || true

echo "== Getting HoopLock"
if [ -d "$DIR/.git" ]; then git -C "$DIR" fetch -q --depth 1 origin "$BRANCH" && git -C "$DIR" checkout -q -f FETCH_HEAD
else git clone -q --depth 1 --branch "$BRANCH" --filter=blob:none --sparse https://github.com/pallavsharmaofficial/brandhoop "$DIR" && git -C "$DIR" sparse-checkout set hooplock/server hooplock/deploy; fi
cd "$DIR/hooplock/deploy"

IP="$(curl -fs4 https://api.ipify.org || hostname -I | awk '{print $1}')"
if [ ! -f .env ]; then
  echo "== First run: creating settings"
  PASS="$(openssl rand -base64 12 | tr -dc 'A-Za-z0-9' | head -c 12)"
  cat > .env <<ENV
DOMAIN=${DOMAIN:-${IP//./-}.sslip.io}
POSTGRES_PASSWORD=$(openssl rand -hex 24)
JWT_SECRET=$(openssl rand -hex 32)
ADMIN_PHONE=${ADMIN_PHONE:-9999999999}
ADMIN_PASSWORD=$PASS
AGENT_SIGNATURE_CHECKSUM=yX2RBYc2wS6WHuSHBgmIHJNz1J3QSrScV4_Sdu-fRhA
AGENT_APK_URL=https://pallavsharmaofficial.github.io/hooplock/agent/hooplock-agent.apk
ENV
  chmod 600 .env
fi
set -a; . ./.env; set +a

echo "== Starting (first build takes 2-4 minutes)"
docker compose up -d --build

echo "== Waiting for HTTPS"
for i in $(seq 1 60); do curl -fs "https://$DOMAIN/healthz" >/dev/null 2>&1 && break; sleep 5; done

cat <<TXT

==================================================================
 HoopLock server is running
 Server address : https://$DOMAIN
 Admin login    : $ADMIN_PHONE
 Admin password : $ADMIN_PASSWORD   (change in the app: Profile)

 Shop app: https://pallavsharmaofficial.github.io/hooplock/app/
   Sign-in screen > "Connect to real server" > https://$DOMAIN
 Settings are in $DIR/hooplock/deploy/.env  (back up this file)
 Update later: run this same command again.
==================================================================
TXT
