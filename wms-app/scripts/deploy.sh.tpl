#!/bin/bash
set -e

APP_ROOT="${app_root}"
APP_NAME="${app_name}"
GITHUB_TOKEN="${github_token}"
GITHUB_USER="${github_user}"
GITHUB_REPO="${github_repo}"
DB_NAME="${db_name}"
DB_NAME2="${db_name2}"
NODE_PORT="${node_port}"

# ── Clone or update repo ──────────────────────────────────────────────────────
if [ -d "$APP_ROOT/.git" ]; then
  cd "$APP_ROOT" && git pull
else
  git clone "https://$GITHUB_TOKEN@github.com/$GITHUB_USER/$GITHUB_REPO.git" "$APP_ROOT"
fi

# ── Deploy config files ───────────────────────────────────────────────────────
mv /tmp/app_config.php  "$APP_ROOT/app/config.php"
mv /tmp/app_nodejs.env  "$APP_ROOT/nodejs/.env"

# ── Node.js dependencies ──────────────────────────────────────────────────────
cd "$APP_ROOT/nodejs" && npm install

# ── Ownership ─────────────────────────────────────────────────────────────────
chown -R www-data:www-data "$APP_ROOT"

# ── Databases ─────────────────────────────────────────────────────────────────
mysql <<SQLEOF
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
CREATE DATABASE IF NOT EXISTS \`$DB_NAME2\`;
SQLEOF

# ── DB schema setup ───────────────────────────────────────────────────────────
php "$APP_ROOT/setup.php"

# ── Nginx site ────────────────────────────────────────────────────────────────
mv /tmp/app_nginx.conf "/etc/nginx/sites-available/$APP_NAME"
ln -sf "/etc/nginx/sites-available/$APP_NAME" "/etc/nginx/sites-enabled/$APP_NAME"
nginx -t && systemctl reload nginx

# ── Firewall: open Node.js port ───────────────────────────────────────────────
ufw allow $NODE_PORT/tcp

# ── PM2 ───────────────────────────────────────────────────────────────────────
cd "$APP_ROOT/nodejs"
pm2 describe wms-socket &>/dev/null && pm2 restart ecosystem.config.js || pm2 start ecosystem.config.js
pm2 save
