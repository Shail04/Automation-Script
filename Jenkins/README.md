# Jenkins Automation Scripts

This folder contains scripts for installing, configuring, and uninstalling Jenkins, as well as setting up Maven for Jenkins automation.

---

## Table of Contents

- [Scripts Overview](#scripts-overview)
- [Quick Start Steps (Detailed)](#quick-start-steps-detailed)
- [Jenkins Installers Reference](#jenkins-installers-reference)
- [Post-Installation](#post-installation)
- [Maven Setup](#maven-setup)
- [Uninstall](#uninstall)
- [Dependencies](#dependencies)

---

## Scripts Overview

| Script | Description |
|--------|-------------|
| `jenkins_installer.sh` | Basic Bash installer for Debian/Ubuntu |
| `jenkins_installer.py` | Python installer for Debian/Ubuntu |
| `jenkins_installer_enhanced.sh` | Enhanced Bash installer with error handling and colored output |
| `jenkins_installer_multiplatform.py` | Multi-platform Python installer (Linux + Windows) |
| `Maven.sh` | Maven installation and configuration for Jenkins |
| `Uninstall_jenkins.sh` | Complete Jenkins uninstall script |

---

## Quick Start Steps (Detailed)

### Step 1: Prepare the machine

Before running any installation script, ensure your environment is ready:

- **Privileges:** Jenkins needs to install system packages (Java, wget) and configure services. On Linux, you must have `sudo` or root access. On Windows, run as Administrator. Without proper privileges, the scripts will fail when installing dependencies.
- **Internet access:** The scripts download Jenkins packages (`.deb`, `.rpm`, or `.war`) from the official Jenkins mirrors. Ensure outbound HTTPS access to `pkg.jenkins.io`, `mirrors.jenkins.io`, and your distribution's package mirrors.
- **Disk space:** Reserve at least 1–2 GB free disk space for Jenkins, Java, and build artifacts.

### Step 2: Navigate to the Jenkins folder

From your project root, change into the Jenkins directory so all script paths and references work correctly:

```bash
cd path/to/Automation-Script/Jenkins
```

Replace `path/to` with the actual path to your repository (e.g. `/home/user/projects/Automation-Script/Jenkins`).

### Step 3: Choose the right installer

Different scripts suit different setups:

| Use case | Script | Explanation |
|----------|--------|-------------|
| **Simple Ubuntu/Debian** | `jenkins_installer.sh` or `jenkins_installer.py` | Minimal, fast install. Good for local or test environments. Fewer checks and error handling. |
| **Robust Ubuntu/Debian** | `jenkins_installer_enhanced.sh` | Adds colored output, error handling, cleanup, and waits for Jenkins to be fully ready. Better for production-like setups. Must be run as root/sudo. |
| **Multi-OS** | `jenkins_installer_multiplatform.py` | Detects Ubuntu/Debian, RedHat/CentOS, or Windows and installs accordingly. Use when you support mixed environments. |

### Step 4: Run the chosen installer

Bash scripts must be executable before you run them:

```bash
chmod +x jenkins_installer.sh
./jenkins_installer.sh
```

For scripts that require root (e.g. `jenkins_installer_enhanced.sh`):

```bash
chmod +x jenkins_installer_enhanced.sh
sudo ./jenkins_installer_enhanced.sh
```

For Python installers:

```bash
python3 jenkins_installer.py
# or
python3 jenkins_installer_multiplatform.py
```

Python scripts often need `sudo` for system-level operations; the script will prompt or perform the necessary privileged commands.

### Step 5: Wait for Jenkins to start

The installer will:

1. Update the package manager (`apt` / `yum`).
2. Install Java 17 (OpenJDK) and `wget` if missing.
3. Download the Jenkins package (version 2.440.3 LTS).
4. Install the package and fix any dependency issues.
5. Enable and start the Jenkins service (`systemctl enable jenkins` / `systemctl start jenkins`).

On Linux, Jenkins may take 1–5 minutes to fully initialize and create `/var/lib/jenkins/secrets/initialAdminPassword`. The enhanced script waits for this file before finishing.

### Step 6: Get the Jenkins URL and initial admin password

- **Access URL:** Open a browser and go to `http://<server-ip>:8080`. Use your server's IP or hostname. Default port is `8080` unless changed.
- **Initial admin password:** On first start, Jenkins requires this one-time password:
  ```bash
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
  ```
  Copy the output and paste it into the Jenkins setup wizard. Use it to create your admin user; after that, this file is no longer needed.

### Step 7: (Optional) Set up Maven for builds

If your Jenkins pipelines use Maven, run `Maven.sh` to install and configure it:

1. **Choose installation method:**
   - Option 1: Install via YUM (quick, uses system packages).
   - Option 2: Install Maven 3.9.9 manually from Apache (recommended for a specific version).

2. **What the script does:**
   - Installs Maven.
   - Creates `/apps/.m2/repository` for the `smarts` user.
   - Creates `/var/lib/jenkins/.m2/repository` for the Jenkins user.
   - Configures `settings.xml` with the local repository path and optional proxy settings.

Run it with:

```bash
chmod +x Maven.sh
./Maven.sh
```

### Step 8: (Optional) Uninstall Jenkins

To remove Jenkins and related data:

```bash
sudo ./Uninstall_jenkins.sh
```

The script will:

1. Ask for confirmation before proceeding.
2. Back up `/var/lib/jenkins` to `/root/jenkins_backup_<timestamp>`.
3. Stop and disable the Jenkins service.
4. Remove the Jenkins package and dependencies.
5. Delete Jenkins directories (`/var/lib/jenkins`, `/var/log/jenkins`, etc.).
6. Remove the `jenkins` user and group.
7. Remove repository configs and keyrings.
8. Clean up any leftover `.deb`, `.rpm`, or `.war` files.

After this, Jenkins is fully removed; restore from the backup if needed.

---

## Jenkins Installers Reference

### 1. `jenkins_installer.sh`

Simple, minimal Bash script for quick installation on Debian/Ubuntu.

- **Platform:** Debian/Ubuntu
- **Requirements:** `sudo`
- **Usage:**
  ```bash
  chmod +x jenkins_installer.sh
  ./jenkins_installer.sh
  ```

### 2. `jenkins_installer.py`

Python-based installer for Debian/Ubuntu systems.

- **Platform:** Debian/Ubuntu
- **Requirements:** Python 3, `sudo`
- **Usage:**
  ```bash
  python3 jenkins_installer.py
  # or
  chmod +x jenkins_installer.py && ./jenkins_installer.py
  ```

### 3. `jenkins_installer_enhanced.sh`

Robust Bash installer with colored output, error handling, and cleanup.

- **Platform:** Debian/Ubuntu
- **Requirements:** Must run as root or with sudo
- **Features:** Cleanup on exit, waits for Jenkins to initialize, validates service status
- **Usage:**
  ```bash
  chmod +x jenkins_installer_enhanced.sh
  sudo ./jenkins_installer_enhanced.sh
  ```

### 4. `jenkins_installer_multiplatform.py`

Cross-platform Python installer supporting multiple operating systems.

- **Platforms:**
  - **Ubuntu/Debian** — installs via `.deb` package
  - **RedHat/CentOS** — installs via `.rpm` package
  - **Windows** — downloads Jenkins WAR; requires manual service setup
- **Requirements:** Python 3, `sudo` (Linux)
- **Usage:**
  ```bash
  python3 jenkins_installer_multiplatform.py
  ```

---

## Post-Installation

After installation, Jenkins is typically available at:

- **URL:** `http://<your-ip>:8080`
- **Initial Admin Password:**
  ```bash
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
  ```

---

## Maven Setup

### `Maven.sh`

Installs and configures Maven for Jenkins builds.

- **Installation options:**
  1. **YUM** — Quick install via package manager
  2. **Manual** — Latest Maven (3.9.9) from Apache
- **Configurations:**
  - Creates `.m2` repository at `/apps/.m2/repository` for `smarts` user
  - Creates `/var/lib/jenkins/.m2/repository` for Jenkins user
  - Configures `settings.xml` with local repository and optional proxy
- **Usage:**
  ```bash
  chmod +x Maven.sh
  ./Maven.sh
  ```

---

## Uninstall

### `Uninstall_jenkins.sh`

Removes Jenkins completely from the system.

- **Platforms:** Ubuntu/Debian, RedHat/CentOS/Fedora
- **Requirements:** Must run as root or with sudo
- **Actions:**
  - Backs up Jenkins configuration to `/root/jenkins_backup_<timestamp>`
  - Stops and disables Jenkins service
  - Removes package and dependencies
  - Deletes Jenkins directories, user, repos, and keyrings
  - Cleans downloaded packages
- **Usage:**
  ```bash
  chmod +x Uninstall_jenkins.sh
  sudo ./Uninstall_jenkins.sh
  ```

---

## Dependencies

- **Java 17** — Required for Jenkins (installed automatically by most installers)
- **wget** — For downloading Jenkins packages
