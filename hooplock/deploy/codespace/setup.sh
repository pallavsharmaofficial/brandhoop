#!/usr/bin/env bash
# One-time setup inside the codespace: PostgreSQL + build the HoopLock server.
set -euo pipefail
cd "$(dirname "$0")/../../server"
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq postgresql > /dev/null
sudo service postgresql start
sudo -u postgres psql -qc "do \$\$ begin if not exists (select from pg_roles where rolname='hooplock') then create role hooplock login password 'hooplock'; end if; end \$\$;"
sudo -u postgres psql -qtc "select 1 from pg_database where datname='hooplock'" | grep -q 1 || sudo -u postgres createdb -O hooplock hooplock
npm ci --no-audit --no-fund
npm run build
echo "HoopLock server built."
