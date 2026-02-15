#!/usr/bin/env python3

import subprocess
import sys
import os
import time
import platform
import socket
import json
from pathlib import Path

class JenkinsInstaller:
    def __init__(self):
        self.os_type = platform.system()
        self.os_version = platform.release()
        self.arch = platform.machine()
        self.jenkins_version = "2.440.3"
        
        # Determine package manager and Jenkins download URL
        self.detect_system()
    
    def detect_system(self):
        """Detect OS and set appropriate package manager"""
        if self.os_type == "Windows":
            self.system_name = "Windows"
            self.package_manager = "chocolatey"
            self.jenkins_port = 8080
        elif self.os_type == "Linux":
            # Determine Linux distribution
            if self.is_ubuntu_debian():
                self.system_name = "Ubuntu/Debian"
                self.package_manager = "apt"
            elif self.is_redhat_centos():
                self.system_name = "RedHat/CentOS"
                self.package_manager = "yum"
            else:
                self.system_name = "Linux (Unknown)"
                self.package_manager = "unknown"
            self.jenkins_port = 8080
        elif self.os_type == "Darwin":
            self.system_name = "macOS"
            self.package_manager = "brew"
            self.jenkins_port = 8080
        else:
            self.system_name = "Unknown"
            self.package_manager = "unknown"
    
    def is_ubuntu_debian(self):
        """Check if system is Ubuntu or Debian"""
        try:
            with open('/etc/os-release', 'r') as f:
                content = f.read().lower()
                return 'ubuntu' in content or 'debian' in content
        except FileNotFoundError:
            return False
    
    def is_redhat_centos(self):
        """Check if system is RedHat or CentOS"""
        try:
            with open('/etc/os-release', 'r') as f:
                content = f.read().lower()
                return 'rhel' in content or 'centos' in content or 'fedora' in content
        except FileNotFoundError:
            return False
    
    def log_info(self, message):
        """Print info message"""
        print(f"\033[94m[INFO]\033[0m {message}")
    
    def log_success(self, message):
        """Print success message"""
        print(f"\033[92m[SUCCESS]\033[0m {message}")
    
    def log_warning(self, message):
        """Print warning message"""
        print(f"\033[93m[WARNING]\033[0m {message}")
    
    def log_error(self, message):
        """Print error message"""
        print(f"\033[91m[ERROR]\033[0m {message}")
    
    def run_command(self, cmd, sudo=False, shell=True, check=True):
        """Execute shell command"""
        if sudo and self.os_type != "Windows":
            cmd = f"sudo {cmd}"
        
        try:
            result = subprocess.run(
                cmd,
                shell=shell,
                capture_output=True,
                text=True,
                check=False
            )
            return result.returncode, result.stdout, result.stderr
        except Exception as e:
            self.log_error(f"Failed to execute command: {str(e)}")
            if check:
                sys.exit(1)
            return 1, "", str(e)
    
    def check_command_exists(self, cmd):
        """Check if command exists"""
        if self.os_type == "Windows":
            result = subprocess.run(
                f"where {cmd}",
                shell=True,
                capture_output=True
            )
        else:
            result = subprocess.run(
                f"which {cmd}",
                shell=True,
                capture_output=True
            )
        return result.returncode == 0
    
    def get_local_ip(self):
        """Get local IP address"""
        try:
            hostname = socket.gethostname()
            ip = socket.gethostbyname(hostname)
            return ip
        except Exception:
            return "localhost"
    
    def install_ubuntu_debian(self):
        """Install Jenkins on Ubuntu/Debian"""
        self.log_info("Installing on Ubuntu/Debian...")
        
        # Update package manager
        self.log_info("Updating package manager...")
        retcode, _, _ = self.run_command("apt-get update -y", sudo=True)
        if retcode != 0:
            self.log_error("Failed to update apt")
            return False
        self.log_success("Package manager updated")
        
        # Install dependencies
        self.log_info("Installing Java 17 JDK...")
        retcode, _, _ = self.run_command("apt-get install -y openjdk-17-jdk wget", sudo=True)
        if retcode != 0:
            self.log_error("Failed to install Java")
            return False
        self.log_success("Java 17 installed")
        
        # Download Jenkins
        self.log_info(f"Downloading Jenkins {self.jenkins_version}...")
        deb_file = f"jenkins_{self.jenkins_version}_all.deb"
        url = f"https://pkg.jenkins.io/debian-stable/binary/{deb_file}"
        retcode, _, _ = self.run_command(f"wget -q --show-progress {url}", sudo=False)
        if retcode != 0:
            self.log_error(f"Failed to download Jenkins from {url}")
            return False
        self.log_success("Jenkins downloaded")
        
        # Install Jenkins
        self.log_info("Installing Jenkins package...")
        retcode, _, stderr = self.run_command(f"dpkg -i {deb_file}", sudo=True, check=False)
        if retcode != 0:
            self.log_warning("Fixing dependencies...")
            self.run_command("apt-get install -f -y", sudo=True)
        self.log_success("Jenkins installed")
        
        # Clean up
        try:
            os.remove(deb_file)
            self.log_info("Cleaned up installer file")
        except:
            pass
        
        return True
    
    def install_redhat_centos(self):
        """Install Jenkins on RedHat/CentOS"""
        self.log_info("Installing on RedHat/CentOS...")
        
        # Check if yum or dnf is available
        if self.check_command_exists("dnf"):
            pm = "dnf"
        else:
            pm = "yum"
        
        # Update package manager
        self.log_info("Updating package manager...")
        retcode, _, _ = self.run_command(f"{pm} update -y", sudo=True)
        if retcode != 0:
            self.log_error(f"Failed to update {pm}")
            return False
        self.log_success("Package manager updated")
        
        # Install dependencies
        self.log_info("Installing Java 17 JDK...")
        retcode, _, _ = self.run_command(f"{pm} install -y java-17-openjdk java-17-openjdk-devel wget", sudo=True)
        if retcode != 0:
            self.log_error("Failed to install Java")
            return False
        self.log_success("Java 17 installed")
        
        # Add Jenkins repo
        self.log_info("Adding Jenkins repository...")
        retcode, _, _ = self.run_command("wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo", sudo=True)
        if retcode != 0:
            self.log_warning("Could not add Jenkins repo - attempting direct download")
        
        # Import Jenkins key
        self.run_command("rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key", sudo=True, check=False)
        
        # Download Jenkins RPM
        self.log_info(f"Downloading Jenkins {self.jenkins_version}...")
        rpm_file = f"jenkins-{self.jenkins_version}-1.1.noarch.rpm"
        url = f"https://pkg.jenkins.io/redhat-stable/jenkins-{self.jenkins_version}-1.1.noarch.rpm"
        retcode, _, _ = self.run_command(f"wget -q --show-progress {url}", sudo=False)
        if retcode != 0:
            self.log_error(f"Failed to download Jenkins from {url}")
            return False
        self.log_success("Jenkins downloaded")
        
        # Install Jenkins
        self.log_info("Installing Jenkins package...")
        retcode, _, _ = self.run_command(f"{pm} install -y {rpm_file}", sudo=True)
        if retcode != 0:
            self.log_error("Failed to install Jenkins")
            return False
        self.log_success("Jenkins installed")
        
        # Clean up
        try:
            os.remove(rpm_file)
            self.log_info("Cleaned up installer file")
        except:
            pass
        
        return True
    
    def install_windows(self):
        """Install Jenkins on Windows"""
        self.log_info("Installing on Windows...")
        self.log_info("Please ensure you have Administrator privileges")
        
        # Check if Java is installed
        self.log_info("Checking for Java installation...")
        if not self.check_command_exists("java"):
            self.log_warning("Java not found. Installing Java 17...")
            
            # Check if Chocolatey is installed
            if not self.check_command_exists("choco"):
                self.log_warning("Chocolatey not found. Installing Chocolatey...")
                self.log_info("Please run this in PowerShell as Administrator:")
                self.log_info("Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser")
                self.log_info("iex ((New-Object System.Net.ServicePointManager).SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072); iex (New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')")
                return False
            
            # Install Java via Chocolatey
            self.log_info("Installing Java 17 via Chocolatey...")
            retcode, _, _ = self.run_command("choco install openjdk17 -y")
            if retcode != 0:
                self.log_error("Failed to install Java")
                return False
            self.log_success("Java 17 installed")
        else:
            self.log_success("Java already installed")
        
        # Verify Java
        self.log_info("Java version:")
        self.run_command("java -version", check=False)
        
        # Download Jenkins WAR
        self.log_info(f"Downloading Jenkins {self.jenkins_version}...")
        jenkins_dir = Path.home() / "Jenkins"
        jenkins_dir.mkdir(exist_ok=True)
        war_file = jenkins_dir / "jenkins.war"
        
        download_url = f"https://mirrors.jenkins.io/war-stable/{self.jenkins_version}/jenkins.war"
        retcode, _, _ = self.run_command(
            f"powershell -Command \"(New-Object Net.WebClient).DownloadFile('{download_url}', '{war_file}')\"",
            shell=False
        )
        if retcode != 0:
            self.log_error(f"Failed to download Jenkins")
            return False
        self.log_success(f"Jenkins downloaded to {war_file}")
        
        # Install Jenkins as Windows service
        self.log_info("Installing Jenkins as Windows service...")
        self.log_info("Please run the following command in PowerShell as Administrator:")
        self.log_info(f"java -jar '{war_file}' --install=Jenkins --httpPort={self.jenkins_port}")
        self.log_warning("Then run: net start Jenkins")
        
        return True
    
    def start_jenkins(self):
        """Start Jenkins service"""
        self.log_info("Starting Jenkins service...")
        
        if self.os_type == "Windows":
            self.run_command("net start Jenkins", sudo=False, check=False)
        else:
            self.run_command("systemctl enable jenkins", sudo=True, check=False)
            self.run_command("systemctl start jenkins", sudo=True, check=False)
        
        # Wait for Jenkins to initialize and generate password file
        self.log_info("Waiting for Jenkins to initialize...")
        max_wait = 120  # 2 minutes
        elapsed = 0
        interval = 5
        
        if self.os_type != "Windows":
            # Wait for password file to be created
            jenkins_secrets = "/var/lib/jenkins/secrets/initialAdminPassword"
            while elapsed < max_wait:
                retcode, _, _ = self.run_command(f"test -f {jenkins_secrets}", sudo=True, check=False)
                if retcode == 0:
                    self.log_success("Jenkins initialization files detected")
                    break
                time.sleep(interval)
                elapsed += interval
            
            # Check status
            retcode, stdout, _ = self.run_command("systemctl status jenkins --no-pager", sudo=True, check=False)
            if retcode == 0:
                self.log_success("Jenkins service is running")
            else:
                self.log_warning("Could not verify Jenkins service status")
        else:
            time.sleep(10)  # Windows needs more time
        
        return True
    
    def get_admin_password(self):
        """Retrieve initial admin password"""
        if self.os_type == "Windows":
            # For Windows, password is displayed during setup
            jenkins_home = Path.home() / "Jenkins"
            return None, str(jenkins_home)
        else:
            jenkins_secrets = "/var/lib/jenkins/secrets/initialAdminPassword"
            retcode, stdout, stderr = self.run_command(f"cat {jenkins_secrets}", sudo=True, check=False)
            if retcode == 0:
                return stdout.strip(), None
            else:
                return None, jenkins_secrets
    
    def show_access_info(self):
        """Display access information"""
        ip = self.get_local_ip()
        
        print("\n" + "=" * 44)
        print(" Jenkins Installed Successfully!")
        print("=" * 44)
        print()
        self.log_success(f"Jenkins is now running on {self.system_name}")
        print(f"\033[94m[INFO]\033[0m Access URL: http://{ip}:{self.jenkins_port}")
        print()
        
        # Show initial admin password path
        if self.os_type == "Windows":
            jenkins_home = Path.home() / "Jenkins"
            print(f"\033[94m[INFO]\033[0m Jenkins home: {jenkins_home}")
            print(f"\033[93m[INFO]\033[0m Run Jenkins service and check initial password")
        else:
            jenkins_secrets = "/var/lib/jenkins/secrets/initialAdminPassword"
            print(f"\033[94m[INFO]\033[0m Initial Admin Password:")
            retcode, stdout, _ = self.run_command(f"cat {jenkins_secrets}", sudo=True, check=False)
            if retcode == 0:
                print(stdout)
            else:
                self.log_warning(f"To retrieve password, run: sudo cat {jenkins_secrets}")
        
        print()
        self.log_success("Installation complete!")
    
    def install(self):
        """Main installation method"""
        print("\n" + "=" * 44)
        print(" Jenkins Direct Package Installer")
        print("=" * 44)
        print()
        
        self.log_info(f"Detected OS: {self.system_name}")
        self.log_info(f"OS Version: {self.os_version}")
        self.log_info(f"Architecture: {self.arch}")
        self.log_info(f"Package Manager: {self.package_manager}")
        print()
        
        # Check if already running
        if self.os_type != "Windows":
            if self.check_command_exists("systemctl"):
                retcode, _, _ = self.run_command("systemctl is-active --quiet jenkins", check=False)
                if retcode == 0:
                    self.log_warning("Jenkins is already installed and running")
                    response = input("Do you want to reinstall? (y/n): ").lower()
                    if response != 'y':
                        return True
        
        # Perform installation based on OS
        if self.system_name == "Windows":
            success = self.install_windows()
        elif self.package_manager == "apt":
            success = self.install_ubuntu_debian()
        elif self.package_manager == "yum":
            success = self.install_redhat_centos()
        else:
            self.log_error(f"Unsupported package manager: {self.package_manager}")
            return False
        
        if not success:
            return False
        
        # Start Jenkins
        if self.os_type != "Windows":
            if not self.start_jenkins():
                return False
        
        # Show access info
        self.show_access_info()
        
        return True

def main():
    try:
        installer = JenkinsInstaller()
        success = installer.install()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\nInstallation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\033[91m[ERROR]\033[0m Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
