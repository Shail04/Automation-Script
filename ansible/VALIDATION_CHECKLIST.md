# Pre-Deployment Validation Checklist

Use this checklist before running the full playbook deployment.

## ✅ Infrastructure Prerequisites

- [ ] **Network Connectivity**
  ```bash
  ping 203.0.113.42 && echo "Control plane reachable"
  ping 203.0.113.70 && echo "Kafka leader reachable"
  ping 203.0.113.42 && echo "Jenkins reachable"
  ```

- [ ] **SSH Access**
  ```bash
  ssh -i ~/.ssh/id_rsa root@203.0.113.42 "echo SSH OK"
  ssh -i ~/.ssh/id_rsa root@203.0.113.70 "echo SSH OK"
  ```

- [ ] **Disk Space** (minimum required)
  ```bash
  # For each host, verify minimum disk space
  ssh root@203.0.113.42 "df -h / | grep -E '^/'  # Kubernetes need 40GB
  ssh root@203.0.113.70 "df -h / | grep -E '^/'  # Kafka need 50GB
  ```

- [ ] **RAM Available**
  ```bash
  # Verify minimum RAM
  ssh root@203.0.113.42 "free -h | grep Mem"  # Need 4GB minimum
  ssh root@203.0.113.70 "free -h | grep Mem"  # Need 8GB minimum
  ```

---

## ✅ Ansible Configuration

- [ ] **Ansible Installed**
  ```bash
  ansible --version
  # Should show: ansible 2.9+ with Python 3.8+
  ```

- [ ] **Inventory File Exists**
  ```bash
  ls -la ansible/inventory/hosts.yml
  # File should exist and be readable
  ```

- [ ] **Ansible Config Present**
  ```bash
  cat ansible/ansible.cfg | grep -E "^(host_key_checking|inventory|log_path)"
  ```

- [ ] **SSH Key Configured**
  ```bash
  ls -la ~/.ssh/id_rsa
  chmod 600 ~/.ssh/id_rsa
  ```

---

## ✅ Connectivity Tests

- [ ] **Ansible Ping All Hosts**
  ```bash
  cd c:\Users\sbm26\Automation-Script\ansible
  ansible all -i inventory/hosts.yml -m ping
  
  # Expected output: All hosts respond with pong
  # k8s-control-plane-1 | SUCCESS => { "ping": "pong" }
  # k8s-worker-1 | SUCCESS => { "ping": "pong" }
  # kafka-node-1 | SUCCESS => { "ping": "pong" }
  # jenkins-1 | SUCCESS => { "ping": "pong" }
  ```

- [ ] **Test Command Execution**
  ```bash
  ansible all -i inventory/hosts.yml -m command -a "whoami"
  
  # Expected: root on all hosts
  ```

- [ ] **Test Ansible Gathering Facts**
  ```bash
  ansible all -i inventory/hosts.yml -m setup -a "filter=ansible_os_family"
  
  # Should succeed and show OS family
  ```

---

## ✅ Kubernetes Environment

- [ ] **Check for Existing Kubernetes**
  ```bash
  ssh root@203.0.113.42 "which kubeadm kubectl && echo WARNING: K8s already installed"
  # OK if not found; ERROR if already installed (cleanup needed)
  ```

- [ ] **Networking Ready**
  ```bash
  ssh root@203.0.113.42 "ip route show"
  # Verify network connectivity between all nodes
  ```

---

## ✅ Kafka Environment

- [ ] **Check for Existing Kafka**
  ```bash
  ssh root@203.0.113.70 "test -d /opt/kafka && echo WARNING: Kafka already installed"
  # OK if directory not found
  ```

- [ ] **Java Not Pre-installed** (good - playbook will install it)
  ```bash
  ssh root@203.0.113.70 "which java && echo WARNING: Java already installed"
  # OK if command not found
  ```

---

## ✅ Jenkins Environment

- [ ] **Check for Existing Jenkins**
  ```bash
  ssh root@203.0.113.42 "systemctl status jenkins && echo WARNING: Jenkins already running"
  # OK to see "Unit jenkins.service could not be found"
  ```

- [ ] **Port 8080 Available**
  ```bash
  ssh root@203.0.113.42 "netstat -tlnp | grep 8080"
  # OK if no output (port is free); ERROR if port in use
  ```

---

## ✅ Playbook Syntax

- [ ] **Validate Playbook Syntax**
  ```bash
  ansible-playbook playbooks/site.yml -i inventory/hosts.yml --syntax-check
  
  # Expected output: "Playbook runs successfully ✓"
  ```

- [ ] **Validate Kubernetes Playbook**
  ```bash
  ansible-playbook playbooks/kubernetes.yml -i inventory/hosts.yml --syntax-check
  ```

- [ ] **Validate Kafka Playbook**
  ```bash
  ansible-playbook playbooks/kafka.yml -i inventory/hosts.yml --syntax-check
  ```

- [ ] **Validate Jenkins Playbook**
  ```bash
  ansible-playbook playbooks/jenkins_maven.yml -i inventory/hosts.yml --syntax-check
  ```

---

## ✅ Documentation Verification

- [ ] **Check Documentation Files Exist**
  ```bash
  ls -la ansible/README.md
  ls -la ansible/TOKEN_CLUSTER_ID_FLOW.md
  ls -la ansible/MONITORING_DEBUG.md
  ls -la ansible/QUICK_REFERENCE.md
  ls -la ansible/VALIDATION_CHECKLIST.md (this file)
  ```

- [ ] **Read Quick Reference**
  - Review QUICK_REFERENCE.md
  - Understand common commands

- [ ] **Understand Token Flow**
  - Review TOKEN_CLUSTER_ID_FLOW.md
  - Understand how tokens are generated and distributed

---

## ✅ Pre-Deployment Dry Run

- [ ] **Run Playbook in Check Mode**
  ```bash
  ansible-playbook playbooks/site.yml -i inventory/hosts.yml --check
  
  # This performs a dry-run without making actual changes
  # Should complete without errors
  ```

- [ ] **Run with Verbose for Dry Run**
  ```bash
  ansible-playbook playbooks/site.yml -i inventory/hosts.yml --check -v
  
  # Shows what would be executed
  ```

---

## ✅ Firewall and SELinux (if applicable)

- [ ] **Disable Firewall** (if needed)
  ```bash
  # For testing only - enable after verification
  ansible all -i inventory/hosts.yml -m systemd -a "name=firewalld state=stopped enabled=no"
  ```

- [ ] **SELinux Configuration** (if on RHEL/CentOS)
  ```bash
  # Temporarily disable for testing
  ansible all -i inventory/hosts.yml -m command -a "setenforce 0"
  ```

---

## ✅ Proxy Settings (if applicable)

- [ ] **Verify Proxy Configuration**
  ```bash
  # If using proxy, verify in inventory:
  cat ansible/inventory/hosts.yml | grep -i proxy
  
  # Should show:
  # http_proxy: http://cloudproxy.nat.bt.com:8080
  # https_proxy: http://cloudproxy.nat.bt.com:8080
  # no_proxy: <list-of-exclusions>
  ```

---

## ✅ Final Pre-Deployment Checklist

- [ ] All connectivity tests passed
- [ ] Playbook syntax is validated
- [ ] No existing installations found
- [ ] Documentation reviewed
- [ ] Dry-run completed successfully
- [ ] Backup created (if upgrading existing systems)

---

## 🚀 Ready to Deploy

If all checkmarks are completed, you're ready to run:

```bash
cd c:\Users\sbm26\Automation-Script\ansible

# Run the full deployment with verbose output
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v

# OR save output to log file for later review
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v 2>&1 | tee deployment-$(date +%Y%m%d-%H%M%S).log
```

---

## 📊 Expected Deployment Timeline

| Phase | Duration | Status Check |
|-------|----------|--------------|
| Kubernetes Control Plane | 5-10 min | Wait for "✓ Token Generated" |
| Kubernetes Worker 1 Join | 2-3 min | Wait for join command output |
| Kubernetes Worker 2 Join | 2-3 min | Wait for join command output |
| Kafka Leader Setup | 3-5 min | Wait for "✓ Cluster ID Generated" |
| Kafka Follower 1 Join | 2-3 min | Wait for successful join |
| Kafka Follower 2 Join | 2-3 min | Wait for successful join |
| Jenkins & Maven | 5-10 min | Watch for port 8080 ready |
| **Total** | **~30-45 min** | All components ready |

---

## 📞 Post-Deployment Verification

After deployment completes, verify with:

```bash
# Verify Kubernetes
ssh root@203.0.113.42 "kubectl get nodes"
# Should show 1 control plane + 2 workers all Ready

# Verify Kafka
ssh root@203.0.113.70 "cat /opt/kafka/cluster.id"
ssh root@203.0.113.71 "cat /opt/kafka/cluster.id"
ssh root@203.0.113.72 "cat /opt/kafka/cluster.id"
# All three should have the SAME UUID

# Verify Jenkins
curl http://203.0.113.42:8080
# Should return Jenkins login page (HTTP 200)
```

---

## 🆘 Issues Found?

Refer to:
1. **MONITORING_DEBUG.md** - Comprehensive troubleshooting guide
2. **QUICK_REFERENCE.md** - Common commands
3. **TOKEN_CLUSTER_ID_FLOW.md** - Understand data flow
4. Ansible verbose output: `-vvv` flag

