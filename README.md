# app-infra

Terraform scripts for provisioning and deploying app instances on a manually created DigitalOcean droplet.

## Workflow

```
1. Create droplet manually on DigitalOcean (Ubuntu 24.04)
2. terraform apply  →  server/    (run once)
3. terraform apply  →  wms-app/   (run per app instance)
```

---

## `server/` — Server configuration

Connects as `root` on port `22`. Run once on a fresh droplet.

**What it does:**

1. Installs Nginx, MariaDB, PHP 8.3 + extensions, Node.js 22, PM2
2. Sets MariaDB root password, writes `/root/.my.cnf`
3. Creates deploy user (from `deploy_user` var) with sudo, copies your SSH key to it
4. Sets root password
5. Removes default Nginx site
6. Configures PM2 as a systemd service (survives reboot)
7. Firewall: allows `ssh_port`, `80`, `443` — blocks everything else
8. Moves SSH to `ssh_port`, disables root login, restarts sshd

> After this runs, root SSH is gone — all future access is via `deploy_user` on `ssh_port`.

**Usage:**

```bash
cd server
cp terraform.tfvars.example terraform.tfvars   # fill in values
terraform init
terraform apply
```

---

## `wms-app/` — App instance deployment

Connects as `deploy_user` on `ssh_port`. Run per app instance. Supports custom repo name and database names.

**What it does:**

1. Clones the GitHub repo (or `git pull` if already exists)
2. Generates and deploys `app/config.php` (DB credentials, Node URLs, app settings)
3. Generates and deploys `nodejs/.env` (port, emit secret)
4. Runs `npm install` in `nodejs/`
5. Sets ownership to `www-data`
6. Creates databases (`db_name`, `db_name2`) in MariaDB
7. Runs `php setup.php` to create all tables
8. Deploys Nginx site config, enables it, reloads Nginx
9. Opens Node.js port in UFW
10. Starts PM2 apps (`wms-socket`, `wms-scheduler`), saves process list

**Usage:**

```bash
cd wms-app
cp terraform.tfvars.example terraform.tfvars   # fill in values
terraform init
terraform apply
```

**To redeploy** after pushing new code — bump `deploy_version` in `terraform.tfvars` then:

```bash
terraform apply
```

---

## SSH access after setup

```bash
ssh YOUR_DEPLOY_USER@YOUR_DROPLET_IP -p YOUR_SSH_PORT
```

---

## Notes

- `terraform.tfvars` files are gitignored — never commit them (contain passwords and tokens)
- `.tfstate` files are gitignored — keep a backup if needed
- `server/` only needs to run once per server; `wms-app/` can run multiple times for different instances
