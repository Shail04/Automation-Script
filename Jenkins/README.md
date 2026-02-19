# Jenkins Installation & Setup Guide

This folder contains multiple automated installation scripts for deploying Apache Jenkins CI/CD server on Linux, macOS, and Windows systems.

## Overview

- **Jenkins Version**: 2.440.3 LTS (Long Term Support)
- **Default Port**: 8080
- **Java Requirement**: OpenJDK 17
- **Supported OS**: Ubuntu, Debian, RHEL, CentOS, Fedora, macOS, Windows
- **Installation Methods**: 3 installer options (Bash basic, Bash enhanced, Python multiplatform)

## Files in This Folder

| File | Purpose | Best For |
|------|---------|----------|
| `jenkins_installer.sh` | Basic bash installer | Ubuntu/Debian quick setup |
| `jenkins_installer_enhanced.sh` | Production-ready bash with color output & error handling | Ubuntu/Debian production |
| `jenkins_installer_multiplatform.py` | Cross-platform Python installer | Windows, macOS, and multi-distro Linux |
| `Uninstall_jenkins.sh` | Complete uninstall with backup | Safe removal on any Linux |
| `README.md` | This documentation | Reference |

## Quick Start

### For Ubuntu/Debian (Choose One):

**Option 1: Basic Installation (5 minutes)**
```bash
sudo bash jenkins_installer.sh
```

**Option 2: Enhanced Installation (5 minutes, recommended)**
```bash
sudo bash jenkins_installer_enhanced.sh
```

### For Windows, macOS, or Multi-Distro Linux:

**Using Python installer**
```bash
python3 jenkins_installer_multiplatform.py
```

---

## Prerequisites

### System Requirements

| OS | Requirements |
|----|--------------|
| **Ubuntu/Debian** | bash, sudo, apt-get, internet connection |
| **RHEL/CentOS** | bash, sudo, yum/dnf, internet connection |
| **macOS** | Homebrew (brew), Python 3, internet connection |
| **Windows** | PowerShell as Admin, Chocolatey (or manual setup), internet connection |

### Hardware Requirements

- **Minimum**: 512 MB RAM, 50 GB disk space
- **Recommended**: 2 GB RAM, 100 GB disk space
- **Production**: 4+ GB RAM, 200+ GB disk space (depends on jobs & build artifacts)

### Network Requirements

- Internet access to download Java, Jenkins, and plugins
- Port 8080 available (or configure different port)
- For distributed builds: Open port 50000 for Jenkins agents

---

## Installation Methods Explained

### Method 1: Basic Bash Installer (`jenkins_installer.sh`)

**Best for**: First-time users on Ubuntu/Debian who want quick setup

**What it does**:
- Updates package manager
- Installs OpenJDK 17 and wget
- Downloads Jenkins 2.440.3 .deb package
- Installs Jenkins package
- Enables and starts Jenkins service
- Displays initial admin password

**Run it**:
```bash
sudo bash jenkins_installer.sh
```

**Time**: ~5 minutes

**Output**: Shows access URL and initial admin password

---

### Method 2: Enhanced Bash Installer (`jenkins_installer_enhanced.sh`)

**Best for**: Production deployments on Ubuntu/Debian with better error handling

**What it does** (all of Method 1, plus):
- ✅ Color-coded output (easier to read)
- ✅ Comprehensive error handling with helpful messages
- ✅ Checks if Jenkins already installed (prevents reinstall)
- ✅ Validates Java installation after setup
- ✅ Waits up to 5 minutes for initial password file
- ✅ Shows IP address and full access instructions
- ✅ Auto-cleanup of temporary files
- ✅ Verifies Jenkins service is running before showing password

**Run it**:
```bash
sudo bash jenkins_installer_enhanced.sh
```

**Time**: ~5-7 minutes (includes verification steps)

**Output**: 
```
============================================
 Jenkins Direct Package Installer
============================================

[SUCCESS] Dependencies installed
[SUCCESS] Jenkins service started
[SUCCESS] Jenkins is running (PID: 12345)

============================================
 Jenkins Installation Complete
============================================
Access Jenkins at: http://192.168.1.100:8080

Initial Admin Password:
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
============================================
```

---

### Method 3: Python Multiplatform Installer (`jenkins_installer_multiplatform.py`)

**Best for**: Windows, macOS, or multi-distro Linux environments

**Features**:
- ✅ **Windows Support**: Uses Chocolatey for installation
- ✅ **macOS Support**: Uses Homebrew for installation
- ✅ **Linux Support**: Detects distro automatically (Ubuntu, RHEL, Fedora, etc.)
- ✅ **Cross-platform**: Single script works on all major OS
- ✅ **Automatic OS detection**: No manual configuration needed
- ✅ **Interactive**: Asks for Java installation preference
- ✅ **Verbose logging**: Shows every step with color-coded output
- ✅ **Error recovery**: Automatically suggests fixes for common issues

**Run it**:
```bash
python3 jenkins_installer_multiplatform.py
```

**Supported Operating Systems**:
- Ubuntu 18.04, 20.04, 22.04, 24.04
- Debian 10, 11, 12
- RHEL 7, 8, 9
- CentOS 7, 8, 9
- Fedora 36+
- macOS 10.15+
- Windows 10, 11 (with Chocolatey)

**Time**: ~5-10 minutes (depends on Java installation method)

---

## Step-by-Step Installation Guide

### On Ubuntu/Debian (Enhanced Method - Recommended)

#### Step 1: Prepare Your System
```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Verify sudo access
sudo whoami
# Should output: root
```

#### Step 2: Run the Installer
```bash
# Download if not present
wget https://your-repo/jenkins_installer_enhanced.sh
# Or if already on system:
cd ~/Automation-Script/Jenkins

# Run installer with sudo
sudo bash jenkins_installer_enhanced.sh
```

#### Step 3: Wait for Completion
The script will output something like:
```
[INFO] Updating package manager...
[SUCCESS] Package manager updated
[INFO] Installing dependencies (Java 17 JDK and wget)...
[SUCCESS] Dependencies installed
...
[INFO] Starting Jenkins service...
[SUCCESS] Jenkins service started
[SUCCESS] Jenkins is running
```

#### Step 4: Access Jenkins
- Open browser to: `http://YOUR_IP:8080`
- Paste the initial admin password from the script output
- Complete the setup wizard (select suggested plugins or customize)

#### Step 5: Create Admin User
After completing the setup wizard, you'll be prompted to create the first admin user:
- Username: (e.g., `admin`)
- Password: (strong password)
- Email: (your email)

#### Step 6: Configure Jenkins
Jenkins Dashboard → Manage Jenkins → Configure System to set:
- Jenkins URL (if accessing from other machines)
- Email notification settings
- Agent settings

---

### On Windows (Python Method)

#### Prerequisites:
1. **Install Chocolatey** (if not already installed):
   ```powershell
   # Open PowerShell as Administrator
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   
   # Copy and paste this into PowerShell:
   [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
   iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
   
   # Verify installation
   choco --version
   ```

2. **Install Python** (if not already installed):
   ```powershell
   choco install python -y
   python --version
   ```

#### Installation:
```powershell
# Navigate to script directory
cd C:\Users\YourName\Automation-Script\Jenkins

# Run Python installer
python jenkins_installer_multiplatform.py
```

#### Expected Output:
```
[INFO] Detected OS: Windows
[INFO] Detected Java: Not installed
Do you want Jenkins to install Java? (yes/no): yes
[INFO] Installing OpenJDK 17 via Chocolatey...
[SUCCESS] Java installed
[INFO] Installing Jenkins via Chocolatey...
[SUCCESS] Jenkins installed
[INFO] Starting Jenkins service...
[SUCCESS] Jenkins service started
```

#### Access Jenkins:
- Open browser to: `http://localhost:8080`
- Initial password will be shown or found in Jenkins log

---

### On macOS (Python Method)

#### Prerequisites:
1. **Install Homebrew** (if not present):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Install Python**:
   ```bash
   brew install python3
   python3 --version
   ```

#### Installation:
```bash
cd ~/Automation-Script/Jenkins
python3 jenkins_installer_multiplatform.py
```

#### Access Jenkins:
- Open browser to: `http://localhost:8080`

---

## Post-Installation Setup

### Get Initial Admin Password

**If you ran the installer**, the password should be displayed. Otherwise:

```bash
# On Linux
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# On Windows (PowerShell)
Get-Content "C:\Windows\System32\jenkins\secrets\initialAdminPassword"

# On macOS
cat ~/.jenkins/secrets/initialAdminPassword
```

### Initial Setup Wizard

1. **Unlock Jenkins**
   - Paste initial admin password from above

2. **Install Plugins**
   - Choose "Install suggested plugins" (recommended for new users)
   - Or "Select plugins to install" for custom setup

3. **Create First Admin User**
   - Username: `admin`
   - Password: (choose strong password)
   - Full name: (your name or "Jenkins Admin")
   - Email: (your email)

4. **Instance Configuration**
   - Jenkins URL: Leave as `http://localhost:8080` or use your server's IP
   - Click "Save and Continue"

### Install Essential Plugins

Go to **Jenkins Dashboard → Manage Jenkins → Manage Plugins → Available**

Recommended plugins:
- **Blue Ocean** - Modern Jenkins UI
- **GitHub Integration** - For GitHub integration
- **Pipeline** - For declarative/scripted pipelines
- **Docker** - For containerized builds
- **Email Extension** - Advanced email notifications

---

## Verification

### Check Jenkins Service Status

**Linux**:
```bash
sudo systemctl status jenkins
```

Expected output includes `Active: active (running)`

**Windows (PowerShell)**:
```powershell
Get-Service Jenkins
```

Expected: `Status: Running`

**macOS**:
```bash
brew services list | grep jenkins
```

Expected: `jenkins started ...`

### Test Jenkins Access

```bash
# Test if port 8080 is listening
curl http://localhost:8080

# On Windows PowerShell
Test-NetConnection -ComputerName localhost -Port 8080
```

### View Jenkins Logs

**Linux**:
```bash
# Live logs
sudo tail -f /var/log/jenkins/jenkins.log

# Last 50 lines
sudo tail -n 50 /var/log/jenkins/jenkins.log

# Or via systemd
sudo journalctl -u jenkins -f
```

**Windows (PowerShell)**:
```powershell
Get-Content "C:\Program Files\Jenkins\jenkins.log" -Tail 50 -Wait
```

**macOS**:
```bash
tail -f ~/Library/Logs/Jenkins/jenkins.log
```

---

## Troubleshooting

### Issue: Port 8080 Already in Use

**Diagnosis**:
```bash
# Find what's using port 8080
sudo netstat -tulpn | grep 8080
# or
sudo lsof -i :8080
```

**Solutions**:

1. **Stop the other service**
   ```bash
   sudo systemctl stop <other-service>
   ```

2. **Change Jenkins port**
   ```bash
   # Edit Jenkins configuration
   sudo nano /etc/default/jenkins
   
   # Find this line:
   # HTTP_PORT=8080
   
   # Change to:
   HTTP_PORT=8081
   
   # Restart Jenkins
   sudo systemctl restart jenkins
   
   # Access at http://localhost:8081
   ```

### Issue: Java Not Found

**Cause**: Java installation failed or PATH not updated

**Fix**:
```bash
# Verify Java is installed
java -version

# If not found, reinstall manually
sudo apt install openjdk-17-jdk -y  # Ubuntu/Debian

# Or on RHEL/CentOS
sudo yum install java-17-openjdk -y

# Restart Jenkins
sudo systemctl restart jenkins
```

### Issue: Initial Admin Password Not Generated

**Cause**: Jenkins service didn't fully start or secrets directory permission issue

**Diagnosis**:
```bash
# Check Jenkins service status
sudo systemctl status jenkins

# Check if secrets directory exists
ls -la /var/lib/jenkins/secrets/
```

**Fix**:
```bash
# Wait longer for Jenkins to fully initialize
sleep 30

# Try to retrieve password again
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# If still not there, check ownership
sudo chown -R jenkins:jenkins /var/lib/jenkins

# Restart service
sudo systemctl restart jenkins

# Wait another 30 seconds and try again
sleep 30
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Issue: Jenkins Service Won't Start

**Diagnosis**:
```bash
sudo systemctl status jenkins
sudo journalctl -u jenkins -n 50
```

**Common causes & fixes**:

1. **Insufficient disk space**
   ```bash
   df -h | grep "/"  # Check disk usage
   ```

2. **Corrupted Jenkins configuration**
   ```bash
   # Backup and reset config
   sudo mv /var/lib/jenkins /var/lib/jenkins.backup
   sudo systemctl restart jenkins
   ```

3. **Java not properly installed**
   ```bash
   java -version  # Should output version
   which java     # Should show path like /usr/bin/java
   ```

### Issue: "Permission Denied" on Scripts

**Fix**:
```bash
# Make scripts executable
chmod +x jenkins_installer.sh
chmod +x jenkins_installer_enhanced.sh
chmod +x jenkins_installer_multiplatform.py

# Run with proper permissions
sudo bash jenkins_installer.sh
```

### Issue: Script Not Finding Apt/Yum

**Cause**: Unusual Linux distribution or PATH issue

**Fix**:
```bash
# Ensure utilities are available
which apt-get  # Should output /usr/bin/apt-get
which yum      # Should output /usr/bin/yum

# Use multiplatform Python script instead (better detection)
python3 jenkins_installer_multiplatform.py
```

---

## Uninstallation

### Safe Removal (Recommended)

```bash
sudo bash Uninstall_jenkins.sh
```

This script will:
- ✅ Ask for confirmation before removing anything
- ✅ Backup all Jenkins data to `/root/jenkins_backup_TIMESTAMP`
- ✅ Stop Jenkins service
- ✅ Remove Jenkins package
- ✅ Clean up directories and files
- ✅ Remove Jenkins repositories (if added)
- ✅ Optionally remove Jenkins user account

### Manual Uninstallation

**On Linux (Ubuntu/Debian)**:
```bash
# Stop service
sudo systemctl stop jenkins
sudo systemctl disable jenkins

# Backup data (optional but recommended)
sudo cp -r /var/lib/jenkins ~/jenkins_backup_$(date +%Y%m%d)

# Remove package
sudo apt-get purge jenkins -y
sudo apt-get autoremove -y

# Remove directories
sudo rm -rf /var/lib/jenkins
sudo rm -rf /var/log/jenkins

# Remove service file
sudo rm /etc/systemd/system/jenkins.service
sudo systemctl daemon-reload
```

**On Linux (RHEL/CentOS)**:
```bash
sudo systemctl stop jenkins
sudo systemctl disable jenkins
sudo yum remove jenkins -y
sudo rm -rf /var/lib/jenkins /var/log/jenkins
```

**On macOS**:
```bash
brew services stop jenkins
brew uninstall jenkins
rm -rf ~/.jenkins
```

**On Windows (PowerShell)**:
```powershell
# Stop service
Stop-Service Jenkins
Set-Service Jenkins -StartupType Disabled

# Uninstall via Chocolatey
choco uninstall jenkins -y

# Manual removal
Remove-Item -Recurse "C:\Program Files\Jenkins" -Force
Remove-Item -Recurse "C:\Windows\System32\jenkins" -Force
```

---

## Important File Locations

| Item | Location |
|------|----------|
| **Jenkins Home** | `/var/lib/jenkins` (Linux) or `~/.jenkins` (macOS) or `C:\Program Files\Jenkins` (Windows) |
| **Configuration** | `$JENKINS_HOME/config.xml` |
| **Jobs** | `$JENKINS_HOME/jobs/` |
| **Plugins** | `$JENKINS_HOME/plugins/` |
| **Initial Password** | `$JENKINS_HOME/secrets/initialAdminPassword` |
| **Jenkins Log** | `/var/log/jenkins/jenkins.log` (Linux) |
| **Service File** | `/etc/systemd/system/jenkins.service` (Linux) |
| **.deb Package** | `jenkins_2.440.3_all.deb` |

---

## Common Commands

### Start/Stop/Restart Jenkins

**Linux (systemd)**:
```bash
# Start
sudo systemctl start jenkins

# Stop
sudo systemctl stop jenkins

# Restart
sudo systemctl restart jenkins

# Status
sudo systemctl status jenkins

# Enable auto-start on reboot
sudo systemctl enable jenkins
```

**Windows (PowerShell as Administrator)**:
```powershell
# Start
Start-Service Jenkins

# Stop
Stop-Service Jenkins

# Restart
Restart-Service Jenkins

# Status
Get-Service Jenkins
```

**macOS**:
```bash
# Start
brew services start jenkins

# Stop
brew services stop jenkins

# Restart
brew services restart jenkins

# Status
brew services list | grep jenkins
```

### View Jenkins Version

```bash
sudo cat /var/lib/jenkins/config.xml | grep "<version>"

# Or
curl -s http://localhost:8080 | grep "Jenkins"
```

### Update Jenkins

**Linux (systemd)**:
```bash
# Using package manager
sudo apt update && sudo apt upgrade jenkins -y  # Ubuntu/Debian
# or
sudo yum update jenkins -y  # RHEL/CentOS

# Restart to apply update
sudo systemctl restart jenkins
```

**Windows (Chocolatey)**:
```powershell
choco upgrade jenkins -y
```

**macOS (Homebrew)**:
```bash
brew upgrade jenkins
```

### Test Jenkins Connectivity

```bash
# Test if running
curl -I http://localhost:8080

# Check firewall (Linux)
sudo ufw status
sudo firewall-cmd --list-all

# Allow port through firewall
sudo ufw allow 8080/tcp        # Ubuntu/Debian
sudo firewall-cmd --add-port=8080/tcp --permanent  # RHEL/CentOS
```

---

## Configuration Tips

### Change Jenkins Port

```bash
# Edit configuration file
sudo nano /etc/default/jenkins

# Find or add this line:
HTTP_PORT=8080

# Change to desired port:
HTTP_PORT=8081

# Save and restart
sudo systemctl restart jenkins
```

### Configure Jenkins URL

Jenkins Dashboard → **Manage Jenkins** → **Configure System**

Set **Jenkins URL** to:
- `http://YOUR_SERVER_IP:8080` (for network access)
- `http://localhost:8080` (for local only)

### Increase Memory for Large Jobs

```bash
# Edit Jenkins configuration
sudo nano /etc/default/jenkins

# Find this line:
JAVA_ARGS="-Djava.awt.headless=true"

# Change to:
JAVA_ARGS="-Djava.awt.headless=true -Xmx4096m -Xms2048m"
# This sets max memory to 4GB, initial memory to 2GB

# Restart Jenkins
sudo systemctl restart jenkins
```

---

## Recommended Next Steps

After Jenkins is installed and running:

1. **Install Plugins**
   - Dashboard → Manage Jenkins → Manage Plugins
   - Search for useful plugins (Git, GitHub, Pipeline, Docker, etc.)

2. **Create Your First Job**
   - Dashboard → New Item
   - Choose job type (Freestyle, Pipeline, or Multibranch)
   - Configure and run

3. **Set Up Credentials**
   - Dashboard → Manage Jenkins → Credentials
   - Add SSH keys or API tokens for GitHub/GitLab/etc.

4. **Configure Security**
   - Dashboard → Manage Jenkins → Configure Global Security
   - Enable authentication and authorization

5. **Set Up Email Notifications**
   - Dashboard → Manage Jenkins → Configure System
   - Configure SMTP for email alerts

6. **Backup Configuration**
   - Regularly backup `/var/lib/jenkins/`
   - Use Configuration as Code (CasC) plugin for easier management

---

## Useful Links

- **Official Jenkins Documentation**: https://www.jenkins.io/doc/
- **Jenkins Plugins**: https://plugins.jenkins.io/
- **LTS Release Notes**: https://www.jenkins.io/changelog-stable/
- **Jenkins Community**: https://www.jenkins.io/community/
- **Blue Ocean Documentation**: https://plugins.jenkins.io/blueocean/

---

## Troubleshooting Reference

| Problem | Solution | Command |
|---------|----------|---------|
| Forgot admin password | Reset via groovy script or reset security | `sudo cat /var/lib/jenkins/config.xml` |
| Jenkins slow/hung | Increase memory | Edit `/etc/default/jenkins` |
| Can't access from network | Check firewall & Jenkins URL | `sudo ufw allow 8080` |
| Plugin installation fails | Check internet & disk space | `df -h` |
| Service won't start | Check logs & Java installation | `sudo journalctl -u jenkins` |

---

## Notes

- **Latest Jenkins LTS**: Always use LTS (Long Term Support) for production
- **Java Version**: Jenkins 2.440.3 requires Java 11+, optimized for Java 17+
- **Disk Space**: Plan for ~500MB base + plugins + build artifacts
- **Memory**: Start with 2GB, increase if jobs fail or Jenkins is slow
- **Backups**: Regular backups of `/var/lib/jenkins` are critical for production
- **Plugins**: Keep plugins updated via Dashboard → Manage Jenkins → Manage Plugins
- **Security**: Always change initial admin password and configure authentication

---

**Last Updated**: February 18, 2026  
**Jenkins Version**: 2.440.3 LTS  
**Java Version**: 17 LTS
