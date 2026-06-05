#!/bin/bash
set -e

# ── Packages ──────────────────────────────────────────────────────────────────
apt-get update -qq
apt-get install -y nginx mariadb-server git curl unzip ufw \
  php8.3 php8.3-fpm php8.3-mysql php8.3-mbstring php8.3-xml \
  php8.3-curl php8.3-zip php8.3-intl php8.3-bcmath php8.3-gd

# ── Node.js 22 ────────────────────────────────────────────────────────────────
if [ ! -f /etc/apt/sources.list.d/nodesource.list ]; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
fi
apt-get install -y nodejs
npm install -g pm2

# ── Services ──────────────────────────────────────────────────────────────────
systemctl enable php8.3-fpm && systemctl start php8.3-fpm
systemctl enable mariadb     && systemctl start mariadb

# ── MariaDB root password ─────────────────────────────────────────────────────
if [ ! -f /root/.my.cnf ]; then
  mysql -u root <<SQLEOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${db_root_pass}';
FLUSH PRIVILEGES;
SQLEOF

  cat > /root/.my.cnf <<MYCNF
[client]
user=root
password=${db_root_pass}
MYCNF
  chmod 600 /root/.my.cnf
fi

# ── Deploy user ───────────────────────────────────────────────────────────────
id -u ${deploy_user} &>/dev/null || useradd -m -s /bin/bash -G sudo ${deploy_user}
echo '${deploy_user} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${deploy_user}
mkdir -p /home/${deploy_user}/.ssh
cp /root/.ssh/authorized_keys /home/${deploy_user}/.ssh/authorized_keys
chown -R ${deploy_user}:${deploy_user} /home/${deploy_user}/.ssh
chmod 700 /home/${deploy_user}/.ssh
chmod 600 /home/${deploy_user}/.ssh/authorized_keys
echo "root:${root_pass}" | chpasswd

# ── Nginx: remove default site ────────────────────────────────────────────────
rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx

# ── PM2 startup service ───────────────────────────────────────────────────────
env PATH=$PATH:/usr/bin pm2 startup systemd -u root --hp /root || true
systemctl enable pm2-root || true

# ── Firewall ──────────────────────────────────────────────────────────────────
ufw allow ${ssh_port}/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# ── SSH hardening (runs last — drops connection) ───────────────────────────────
sed -i "s/^#\?Port .*/Port ${ssh_port}/" /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sleep 2 && systemctl restart ssh &
