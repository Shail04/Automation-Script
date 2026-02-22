#!/bin/bash

# Maven Installation and Configuration Script
# This script installs and configures Maven for Jenkins automation

set -e  # Exit on error

echo "======================================"
echo "Maven Installation & Configuration"
echo "======================================"

# Option 1: Install Maven via YUM (Quick method)
install_maven_yum() {
    echo "Installing Maven via YUM..."
    sudo yum install maven -y
    mvn -version
    echo "Maven installed successfully via YUM"
}

# Option 2: Install Latest Maven Manually (Recommended)
install_maven_manual() {
    echo "Installing Maven 3.9.9 manually..."
    
    # Download Maven
    cd /tmp
    wget https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz
    
    # Extract to /opt
    sudo tar -xvzf apache-maven-3.9.9-bin.tar.gz -C /opt
    sudo ln -s /opt/apache-maven-3.9.9 /opt/maven
    
    # Set environment variables
    echo "export M2_HOME=/opt/maven" >> ~/.bashrc
    echo "export PATH=$M2_HOME/bin:$PATH" >> ~/.bashrc
    source ~/.bashrc
    
    mvn -version
    echo "Maven installed successfully manually"
}

# Configure Maven Repository for Smarts user
configure_repository() {
    echo "Configuring Maven repository..."
    
    # Create .m2 directory structure
    sudo mkdir -p /apps/.m2/repository
    
    # Change ownership
    sudo chown -R smarts:smarts /apps/.m2
    
    # Set permissions
    sudo chmod -R 755 /apps/.m2
    
    echo "Repository directory created and configured at /apps/.m2"
}

# Configure Maven Repository for Jenkins user
configure_jenkins_repository() {
    echo "Configuring Maven repository for Jenkins user..."
    
    # Create Jenkins .m2 directory
    sudo mkdir -p /var/lib/jenkins/.m2/repository
    
    # Change ownership to Jenkins
    sudo chown -R jenkins:jenkins /var/lib/jenkins/.m2
    
    # Set permissions
    sudo chmod -R 755 /var/lib/jenkins/.m2
    
    echo "Jenkins repository directory created at /var/lib/jenkins/.m2"
}

# Configure settings.xml
configure_settings() {
    echo "Configuring Maven settings.xml..."
    
    # Determine which settings.xml to use
    if [ -f "/etc/maven/settings.xml" ]; then
        SETTINGS_FILE="/etc/maven/settings.xml"
    elif [ -f "/opt/maven/conf/settings.xml" ]; then
        SETTINGS_FILE="/opt/maven/conf/settings.xml"
    else
        echo "ERROR: settings.xml file not found!"
        exit 1
    fi
    
    echo "Using settings file: $SETTINGS_FILE"
    
    # Backup original settings
    sudo cp $SETTINGS_FILE ${SETTINGS_FILE}.backup.$(date +%Y%m%d_%H%M%S)
    echo "Backup created: ${SETTINGS_FILE}.backup"
    
    # Add local repository configuration
    sudo sed -i '/<localRepository>/d' $SETTINGS_FILE
    
    # Insert local repository after <settings> tag
    sudo sed -i '/<settings>/a\  <localRepository>/apps/.m2/repository</localRepository>' $SETTINGS_FILE
    
    # Add proxy configuration
    add_proxy_config "$SETTINGS_FILE"
    
    echo "settings.xml configured successfully"
}

# Add proxy configuration to settings.xml
add_proxy_config() {
    local SETTINGS_FILE=$1
    
    echo "Adding proxy configuration..."
    
    # Check if proxies section already exists
    if ! sudo grep -q "<proxies>" $SETTINGS_FILE; then
        # Add proxies section before closing </settings>
        sudo sed -i '/<\/settings>/i\  <proxies>\n    <proxy>\n      <id>corporate-proxy</id>\n      <active>false</active>\n      <protocol>http</protocol>\n      <host>your-proxy-host</host>\n      <port>8080</port>\n      <username>your-username</username>\n      <password>your-password</password>\n      <nonProxyHosts>localhost|127.0.0.1</nonProxyHosts>\n    </proxy>\n  </proxies>' $SETTINGS_FILE
        echo "Proxy configuration added to settings.xml"
    else
        echo "Proxy configuration already exists in settings.xml"
    fi
}

# Verify Maven installation
verify_installation() {
    echo ""
    echo "======================================"
    echo "Verifying Maven Installation"
    echo "======================================"
    
    mvn -version
    
    echo ""
    echo "Maven Home: $(mvn -q -Dexec.executable="echo" -Dexec.args="\${project.basedir}" exec:exec 2>/dev/null || echo 'Not available')"
    echo "Local Repository: /apps/.m2/repository"
    echo "Jenkins Repository: /var/lib/jenkins/.m2/repository"
    echo ""
}

# Main execution
main() {
    echo ""
    echo "Select Maven installation option:"
    echo "1) Install via YUM (quick)"
    echo "2) Install manually (recommended for latest version)"
    echo ""
    read -p "Enter your choice (1 or 2): " choice
    
    case $choice in
        1)
            install_maven_yum
            ;;
        2)
            install_maven_manual
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
    
    configure_repository
    configure_jenkins_repository
    configure_settings
    verify_installation
    
    echo "======================================"
    echo "Maven setup completed successfully!"
    echo "======================================"
}

# Run main function
main "$@"