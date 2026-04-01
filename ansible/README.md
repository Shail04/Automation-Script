# Ansible Infrastructure Automation

This directory contains Ansible playbooks for deploying and configuring a complete infrastructure stack with Kubernetes, Kafka, and Jenkins CI/CD.

## 📚 Documentation

- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - One-page cheat sheet for common commands and operations
- **[VALIDATION_CHECKLIST.md](VALIDATION_CHECKLIST.md)** - Pre-deployment verification steps and post-deployment validation
- **[MONITORING_DEBUG.md](MONITORING_DEBUG.md)** - Monitoring during deployment, common issues, verification steps, and troubleshooting guide
- **[TOKEN_CLUSTER_ID_FLOW.md](TOKEN_CLUSTER_ID_FLOW.md)** - Comprehensive guide on how tokens and cluster IDs are generated and passed between nodes
- This README - Setup and usage guide

## Key Features

### Dynamic Token/Cluster ID Handling

This Ansible automation **automatically handles dynamic token and cluster ID generation** without any manual intervention:

#### Kubernetes Token Management
- **Control Plane**: Generates join tokens and certificate keys
- **Worker Nodes**: Automatically retrieve and use join commands
- **Delegation**: Uses Ansible facts to share tokens across nodes
- **Serial Execution**: Ensures control plane is ready before workers join

#### Kafka Cluster ID Management
- **Leader Election**: First node in inventory becomes leader
- **Cluster ID Generation**: Leader generates UUID-based cluster ID
- **Distribution**: Cluster ID is automatically copied to all follower nodes
- **Coordination**: Uses Ansible delegation and facts for coordination

### Deployment Flow

```
1. Control Plane/Leader Setup
   ├── Install prerequisites
   ├── Generate tokens/cluster IDs
   └── Start services

2. Worker/Follower Setup (Serial)
   ├── Wait for leader to be ready
   ├── Retrieve tokens/cluster IDs
   ├── Join cluster
   └── Verify membership
```

## Component Details

### Kubernetes Cluster Setup

**Dynamic Token Handling:**
- Control plane generates `kubeadm token create --print-join-command`
- Certificate keys are extracted and shared
- Worker nodes automatically join using shared tokens
- Cluster status is verified after all nodes join

**Key Features:**
- **Version**: 1.35.1 with containerd 1.7.18
- **CNI**: Flannel networking
- **Security**: TLS bootstrap, certificate management
- **HA**: Multi-control-plane support (expandable)

### Kafka KRaft Cluster Setup

**Dynamic Cluster ID Handling:**
- Leader node generates UUID cluster ID
- Cluster ID is distributed to all nodes via Ansible facts
- Controller quorum is pre-configured
- Automatic leader election based on inventory order

**Key Features:**
- **Version**: 4.0.0 (KRaft mode, no Zookeeper)
- **Java**: OpenJDK 17
- **Clustering**: 3-node controller quorum
- **Performance**: Optimized for production use

## Prerequisites

### Control Machine Requirements
- Ansible 2.9+ installed
- Python 3.8+
- SSH access to all target hosts
- SSH key-based authentication configured

### Target Machine Requirements
- RHEL/CentOS 7+ or Ubuntu 18.04+
- Root or sudo access without password prompt
- Internet connectivity for downloading packages
- Minimum resources:
  - **Kubernetes**: 4GB RAM, 2 CPU cores per node
  - **Kafka**: 8GB RAM, 4 CPU cores per node
  - **Jenkins**: 4GB RAM, 2 CPU cores

## Installation

### 1. Install Ansible
```bash
pip install ansible>=2.9
```

### 2. Configure SSH Access
```bash
# Copy your SSH public key to all target hosts
ssh-copy-id -i ~/.ssh/id_rsa.pub root@<target-host>
```

### 3. Update Inventory
Edit `inventory/hosts.yml` and update:
- IP addresses for each VM
- Hostnames
- Any environment-specific variables
- Proxy settings if applicable

### 4. Test Connectivity
```bash
ansible all -i inventory/hosts.yml -m ping
```

### 5. Pre-Deployment Validation
Before running the full deployment, review and complete **[VALIDATION_CHECKLIST.md](VALIDATION_CHECKLIST.md)** to verify:
- Infrastructure prerequisites (network, SSH, disk space, RAM)
- Ansible configuration
- Connectivity to all hosts
- Playbook syntax validation
- Dry-run execution

## Deployment

### Deploy All Components
```bash
ansible-playbook playbooks/site.yml -i inventory/hosts.yml
```

### Deploy Specific Components

#### Kubernetes Only
```bash
ansible-playbook playbooks/kubernetes.yml -i inventory/hosts.yml --tags kubernetes
```

#### Kafka Only
```bash
ansible-playbook playbooks/kafka.yml -i inventory/hosts.yml --tags kafka
```

#### Jenkins & Maven Only
```bash
ansible-playbook playbooks/jenkins_maven.yml -i inventory/hosts.yml --tags jenkins
```

### With Verbose Output
```bash
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v
```

### With Extra Variables
```bash
ansible-playbook playbooks/kubernetes.yml -i inventory/hosts.yml \
  -e "k8s_version=1.35.1" \
  -e "control_plane_ip=10.2.162.64"
```

## Component Details

### Kubernetes Cluster Setup

The Kubernetes playbook installs and configures:

- **Version**: 1.35.1
- **Container Runtime**: containerd 1.7.18
- **CNI Plugin**: Flannel
- **Control Plane**: kubeadm-based initialization
- **Features**: 
  - Swap disabled
  - Kernel modules configured
  - Firewall rules (optional)
  - Systemd cgroup driver

#### Kubernetes Variables
```yaml
control_plane_ip: "10.2.162.64"
control_plane_port: "61149"
k8s_version: "1.35.1"
containerd_version: "1.7.18"
pod_cidr: "10.244.0.0/16"
```

#### Post-Installation Steps
1. Copy admin credentials from control plane
2. Run worker join commands
3. Wait for all nodes to be ready
4. Verify cluster: `kubectl get nodes`

### Kafka Cluster Setup (KRaft Mode)

The Kafka playbook installs and configures:

- **Version**: 4.0.0
- **Mode**: KRaft (Kraft controller mode without Zookeeper)
- **Java**: OpenJDK 17
- **Cluster**: 3-node configuration
- **Features**:
  - Automatic cluster ID generation and distribution
  - Leader election
  - Systemd service integration
  - Directory structure creation

#### Kafka Variables
```yaml
kafka_version: "4.0.0"
kafka_install_dir: "/opt/kafka"
kafka_data_dir: "/data/kafka"
controller_quorum: "1@10.2.162.70:9093,2@10.2.162.71:9093,3@10.2.162.72:9093"
```

#### Post-Installation Steps
1. Verify cluster formation: `kafka-metadata.sh`
2. Create test topic
3. Produce and consume test messages
4. Monitor logs: `journalctl -u kafka -f`

### Jenkins & Maven Setup

The Jenkins playbook installs and configures:

- **Jenkins**: 2.440.3
- **Java**: OpenJDK 17 JDK
- **Maven**: 3.9.9
- **SCM**: Git integration
- **NodeJS**: Optional (for Jenkins plugins)

#### Jenkins Variables
```yaml
jenkins_version: "2.440.3"
jenkins_home: "/var/lib/jenkins"
jenkins_port: "8080"
maven_version: "3.9.9"
maven_home: "/opt/maven"
```

#### Post-Installation Steps
1. Access Jenkins: `http://<jenkins-server>:8080`
2. Retrieve initial admin password from console output
3. Install recommended plugins
4. Create first admin user
5. Configure Maven in System Configuration

## Configuration Variables

### Environment-specific Variables
Edit `inventory/hosts.yml` to customize:

```yaml
# Proxy settings
http_proxy: "http://your-proxy:8080"
https_proxy: "https://your-proxy:8080"

# SSH settings
ansible_ssh_user: "root"
ansible_ssh_pass: "your-password"

# Component versions
k8s_version: "1.35.1"
kafka_version: "4.0.0"
jenkins_version: "2.440.3"
```

### Using Ansible Vault for Secrets

Protect sensitive data:
```bash
# Create vault file
ansible-vault create group_vars/all/vault.yml

# Edit vault file
ansible-vault edit group_vars/all/vault.yml

# Run playbook with vault
ansible-playbook playbooks/site.yml --ask-vault-pass
```

## Troubleshooting

### For Comprehensive Troubleshooting Guide
See **[MONITORING_DEBUG.md](MONITORING_DEBUG.md)** for:
- Common issues and solutions
- Manual verification steps
- Debug output examples
- Real-time monitoring during deployment
- Quick issue resolution checklist

### Quick Troubleshooting

#### SSH Connection Issues
```bash
# Test SSH connection
ansible all -i inventory/hosts.yml -m ping -vvv

# Enable SSH debugging
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -vvv
```

#### Package Installation Failures
```bash
# Check package manager
ansible all -i inventory/hosts.yml -m command -a "which apt-get || which yum"

# Manually update on target
ssh root@<target> "apt-get update && apt-get upgrade -y"
```

#### Service Start Issues
```bash
# Check service status
ansible all -i inventory/hosts.yml -m service -a "name=<service> state=started"

# View service logs
ansible all -i inventory/hosts.yml -m command -a "journalctl -u <service> -n 50"
```

#### Firewall Issues
```bash
# Temporarily disable firewall for testing
ansible all -i inventory/hosts.yml -m systemd -a "name=firewalld state=stopped enabled=no"
```

## Security Considerations

1. **SSH Key Management**
   - Use SSH key-based authentication
   - Store private keys securely
   - Restrict file permissions: `chmod 600 ~/.ssh/id_rsa`

2. **Ansible Vault**
   - Encrypt sensitive variables
   - Use strong vault passwords
   - Store vault password separately

3. **Network Security**
   - Configure firewall rules after deployment
   - Use VPN for remote access
   - Enable SELinux on RHEL/CentOS systems

4. **Access Control**
   - Restrict sudo access
   - Use non-root users where possible
   - Implement RBAC in Kubernetes

## Monitoring and Logging

### Ansible Logging
- Default log location: `/var/log/ansible.log`
- Configure in `ansible.cfg`

### Component Logs
- **Kubernetes**: `journalctl -u kubelet -f`
- **Kafka**: `tail -f /var/log/kafka/*.log`
- **Jenkins**: `tail -f /var/lib/jenkins/logs/jenkins.log`

## Maintenance

### Rolling Updates
```bash
# Update Kubernetes
ansible-playbook playbooks/kubernetes.yml -i inventory/hosts.yml --extra-vars "k8s_version=1.36.0"

# Update Kafka
ansible-playbook playbooks/kafka.yml -i inventory/hosts.yml --extra-vars "kafka_version=4.1.0"
```

### Backup and Recovery
```bash
# Backup Jenkins configuration
ansible ci_cd -i inventory/hosts.yml -m archive -a "path=/var/lib/jenkins dest=/backup/jenkins.tar.gz"

# Backup Kafka brokers
ansible kafka -i inventory/hosts.yml -m archive -a "path=/data/kafka dest=/backup/kafka.tar.gz"
```

## FAQ

**Q: How do I skip Kubernetes installation and deploy only Kafka?**
A: Use host groups in inventory and run: `ansible-playbook playbooks/kafka.yml -i inventory/hosts.yml`

**Q: Can I customize the Kubernetes network CIDR?**
A: Yes, edit `pod_cidr` in `inventory/hosts.yml` before deployment.

**Q: How do I add more Kafka nodes?**
A: Add nodes to inventory with appropriate `node_id` and update `controller_quorum` variable.

**Q: How do I integrate Jenkins with GitLab/GitHub?**
A: After installation, configure in Jenkins UI: Manage Jenkins → System Configuration → GitHub/GitLab settings

## Support and Contributions

For quick reference: See **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** for common commands

For troubleshooting: See **[MONITORING_DEBUG.md](MONITORING_DEBUG.md)** for comprehensive debugging guide

For issues or improvements:
1. Check logs: `journalctl` or component logs
2. Run playbooks with `-vvv` for debugging
3. Verify inventory configuration
4. Test SSH connectivity
5. Refer to documentation files above for detailed guidance

## License

These playbooks are part of the Automation-Script collection.

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Ansible Documentation](https://docs.ansible.com/)
