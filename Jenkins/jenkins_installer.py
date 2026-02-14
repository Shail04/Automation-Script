#!/usr/bin/env python3

import subprocess
import sys
import time
import socket

def run_command(cmd, sudo=False, check=True):
    """Execute a shell command and return output"""
    if sudo:
        cmd = f"sudo {cmd}"
    
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            check=check
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.CalledProcessError as e:
        if check:
            print(f"[ERROR] Command failed: {cmd}")
            print(f"[ERROR] {e.stderr}")
            sys.exit(1)
        return e.returncode, e.stdout, e.stderr

def get_local_ip():
    """Get the local IP address"""
    try:
        # Try to get hostname and resolve to IP
        hostname = socket.gethostname()
        ip = socket.gethostbyname(hostname)
        return ip
    except Exception:
        # Fallback: try to run hostname command
        retcode, stdout, _ = run_command("hostname -I | awk '{print $1}'", sudo=False, check=False)
        if retcode == 0:
            return stdout.strip()
        return "localhost"

def main():
    print("==================================")
    print(" Jenkins Direct Package Installer ")
    print("==================================")
    print()
    
    # Update package manager
    print("[INFO] Updating package manager...")
    run_command("apt update -y", sudo=True)
    
    # Install dependencies
    print("[INFO] Installing dependencies (Java 17 and wget)...")
    run_command("apt install -y openjdk-17-jdk wget", sudo=True)
    
    # Check Java version
    print("[INFO] Java Version:")
    retcode, stdout, _ = run_command("java -version", sudo=False, check=False)
    print(stdout)
    
    # Download latest Jenkins LTS package
    print("[INFO] Downloading Jenkins...")
    run_command("wget https://pkg.jenkins.io/debian-stable/binary/jenkins_2.440.3_all.deb", sudo=False)
    
    # Install Jenkins package
    print("[INFO] Installing Jenkins package...")
    retcode, _, stderr = run_command("dpkg -i jenkins_2.440.3_all.deb", sudo=True, check=False)
    
    # If dpkg fails, try to fix dependencies
    if retcode != 0:
        print("[INFO] Fixing missing dependencies...")
        run_command("apt -f install -y", sudo=True)
    
    # Start Jenkins service
    print("[INFO] Starting Jenkins...")
    run_command("systemctl enable jenkins", sudo=True)
    run_command("systemctl start jenkins", sudo=True)
    
    # Wait for service to start
    time.sleep(5)
    
    # Check service status
    print("[INFO] Checking Jenkins service status...")
    retcode, stdout, _ = run_command("systemctl status jenkins --no-pager", sudo=True, check=False)
    print(stdout)
    
    # Get IP address
    ip = get_local_ip()
    
    # Display success message
    print()
    print("==================================")
    print(" Jenkins Installed Successfully ")
    print("==================================")
    print(f"Access URL: http://{ip}:8080")
    print()
    
    # Show initial admin password
    print("Initial Admin Password:")
    retcode, stdout, stderr = run_command("cat /var/lib/jenkins/secrets/initialAdminPassword", sudo=True, check=False)
    if retcode == 0:
        print(stdout)
    else:
        print("[WARNING] Could not retrieve initial admin password yet. Jenkins may still be initializing.")
        print("         Try running: sudo cat /var/lib/jenkins/secrets/initialAdminPassword")

if __name__ == "__main__":
    main()
