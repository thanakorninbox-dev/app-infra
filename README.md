# app-infra

Ansible playbooks for configuring and deploying app instances on a manually created DigitalOcean droplet.

## Workflow

```
1. Create droplet manually on DigitalOcean (Ubuntu 24.04)
2. ansible-playbook server.yml     ← run once per server
3. ansible-playbook wms-app.yml    ← run per app instance
```

---

## Setup

```bash
cd ansible
cp inventory.ini.example inventory.ini       # fill in server IP, user, port
cp vars/server.yml.example vars/server.yml   # fill in passwords, SSH port, deploy user
```

---

## `server.yml` — Server configuration

Connects as `root` on port `22`. Run once on a fresh droplet.

**What it does:**

1. Installs Nginx, MariaDB, PHP 8.3 + extensions, Node.js 22, PM2
2. Sets MariaDB root password, writes `/root/.my.cnf`
3. Creates deploy user with sudo, copies SSH key to it
4. Sets root password
5. Deploys base Nginx config + `index.php` (phpinfo) for verification
6. Configures PM2 as a systemd service (survives reboot)
7. Enables unattended security upgrades
8. Configures fail2ban (5 failed attempts → 1hr ban)
9. Firewall: allows `ssh_port`, `80`, `443` — blocks everything else
10. Moves SSH to `ssh_port`, disables root login, disables password auth

> After this runs, root SSH is gone — all future access is via `deploy_user` on `ssh_port`.

**Usage:**

```bash
# First run — connect as root on port 22
cd ansible
ansible-playbook -i inventory.ini server.yml
```

**Verify:**
```bash
# phpinfo in browser
http://YOUR_DROPLET_IP/index.php

# SSH as deploy user
ssh YOUR_DEPLOY_USER@YOUR_DROPLET_IP -p YOUR_SSH_PORT

# Root should be blocked
ssh root@YOUR_DROPLET_IP -p YOUR_SSH_PORT   # Permission denied
```

**After verified — update `inventory.ini`:**
```ini
[production]
YOUR_DROPLET_IP ansible_user=YOUR_DEPLOY_USER ansible_port=YOUR_SSH_PORT
```

---

## `wms-app.yml` — App instance deployment

Connects as `deploy_user` on `ssh_port`. Supports custom repo name and database names.

**What it does:**

1. Creates databases (`db_name`, `db_name2`) in MariaDB
2. Clones the GitHub repo (or `git pull` if already exists)
3. Generates and deploys `app/config.php` (DB credentials, Node URLs, app settings)
4. Generates and deploys `nodejs/.env` (port, emit secret)
5. Runs `npm install` in `nodejs/`
6. Sets ownership to `www-data`
7. Runs `php setup.php` to create all tables
8. Removes base Nginx site, deploys app Nginx config, reloads Nginx
9. Opens Node.js port in UFW
10. Starts PM2 apps (`wms-socket`, `wms-scheduler`), saves process list

**Setup:**

```bash
cp vars/wms-app.yml.example vars/wms-app.yml   # fill in values
```

**Usage:**

```bash
ansible-playbook -i inventory.ini wms-app.yml
```

**To redeploy** after pushing new code:

```bash
ansible-playbook -i inventory.ini wms-app.yml
```

Ansible skips steps already done — only re-runs what changed.

---

## SSH access after setup

```bash
ssh YOUR_DEPLOY_USER@YOUR_DROPLET_IP -p YOUR_SSH_PORT
```

---

## Notes

- `inventory.ini`, `vars/server.yml`, `vars/apps/*.yml` are gitignored — never commit them (contain passwords and tokens)
- `server.yml` runs once per server; `wms-app.yml` can run multiple times for different app instances
- This server supports multiple apps — each app gets its own Nginx site config and PM2 processes
