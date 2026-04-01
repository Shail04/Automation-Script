# Ansible Playbook - Quick Reference

One-page cheat sheet for running and debugging the automation.

## 🚀 Quick Start

```bash
# Navigate to ansible directory
cd c:\Users\sbm26\Automation-Script\ansible

# Verify connectivity to all hosts
ansible all -i inventory/hosts.yml -m ping

# Run full deployment
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v

# Run specific playbook
ansible-playbook playbooks/kubernetes.yml -i inventory/hosts.yml -v
ansible-playbook playbooks/kafka.yml -i inventory/hosts.yml -v
ansible-playbook playbooks/jenkins_maven.yml -i inventory/hosts.yml -v
```

## 📋 Common Commands

```bash
# List all hosts
ansible-inventory -i inventory/hosts.yml --list

# List specific group
ansible-inventory -i inventory/hosts.yml --host k8s_control_plane

# Run ad-hoc command
ansible k8s_workers -i inventory/hosts.yml -m command -a "kubectl get nodes"
ansible kafka -i inventory/hosts.yml -m command -a "cat /opt/kafka/cluster.id"

# Copy file to all hosts
ansible all -i inventory/hosts.yml -m copy -a "src=file.txt dest=/tmp/file.txt"

# Install package on all hosts
ansible all -i inventory/hosts.yml -m apt -a "name=curl state=present"

# Check disk space
ansible all -i inventory/hosts.yml -m command -a "df -h /"

# Check memory
ansible all -i inventory/hosts.yml -m command -a "free -h"
```

## ✅ Verification Commands

```bash
# Verify Kubernetes
ssh root@10.2.162.64 "kubectl get nodes"
ssh root@10.2.162.64 "kubectl cluster-info"

# Verify Kafka Cluster ID Distribution
ansible kafka -i inventory/hosts.yml -m command -a "cat /opt/kafka/cluster.id"

# Verify Jenkins
ssh root@10.2.162.80 "systemctl status jenkins"
curl http://10.2.162.80:8080

# Check service status
ansible all -i inventory/hosts.yml -m service -a "name=kubelet state=started"
ansible kafka -i inventory/hosts.yml -m service -a "name=kafka state=started"
```

## 🔧 Debugging

```bash
# Run with high verbosity (see all details)
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -vvv

# Run specific host
ansible-playbook playbooks/kubernetes.yml -i inventory/hosts.yml -l k8s_control_plane

# Syntax check
ansible-playbook playbooks/site.yml -i inventory/hosts.yml --syntax-check

# Dry run (preview changes without executing)
ansible-playbook playbooks/site.yml -i inventory/hosts.yml --check

# Show variable values
ansible-playbook playbooks/kubernetes.yml -i inventory/hosts.yml -e "ansible_verbosity=4"
```

## 📊 Log Locations

```bash
# Kubernetes
ssh root@10.2.162.64 "journalctl -u kubelet -f"
ssh root@10.2.162.65 "journalctl -u kubelet -f"

# Kafka
ssh root@10.2.162.70 "tail -f /opt/kafka/logs/server.log"
ssh root@10.2.162.71 "tail -f /opt/kafka/logs/server.log"

# Jenkins
ssh root@10.2.162.80 "tail -f /var/log/jenkins/jenkins.log"

# Ansible
cat /var/log/ansible/ansible.log
```

## 🛑 Stop/Rollback Commands

```bash
# Stop all services
ansible all -i inventory/hosts.yml -m service -a "name=kubelet state=stopped"
ansible all -i inventory/hosts.yml -m service -a "name=kafka state=stopped"

# Reset Kubernetes
ssh root@10.2.162.64 "kubeadm reset -f"
ssh root@10.2.162.65 "kubeadm reset -f"

# Uninstall specific packages
ansible all -i inventory/hosts.yml -m apt -a "name=kubelet state=absent"
ansible all -i inventory/hosts.yml -m apt -a "name=kafka state=absent"
```

## 📍 Token & Cluster ID Data Flow

### Kubernetes Tokens
```
kubeadm token generate (control-plane)
  ↓
Set Ansible fact: k8s_worker_join_command
  ↓
Delegate to workers (k8s_workers)
  ↓
Worker retrieves: hostvars[control-plane]['k8s_worker_join_command']
  ↓
kubeadm join <token>
```

### Kafka Cluster IDs
```
uuidgen (leader)
  ↓
Save to /opt/kafka/cluster.id
  ↓
Set Ansible fact: kafka_cluster_id
  ↓
Copy cluster.id to followers
  ↓
Follower retrieves: hostvars[leader]['kafka_cluster_id']
  ↓
Create server.properties with cluster.id
```

## 🎯 Expected Output Timeline

```
1. Kubernetes Control Plane Setup (5-10 min)
   ✓ Token Generated
   ✓ Tokens Distributed to Workers
   
2. Kubernetes Worker Join (2-3 min per worker)
   ✓ Worker 1 Joins Cluster
   ✓ Worker 2 Joins Cluster
   
3. Kafka Leader Setup (3-5 min)
   ✓ Cluster ID Generated
   ✓ Cluster ID Distributed to Followers
   
4. Kafka Follower Join (2-3 min per follower)
   ✓ Follower 1 Joins Cluster
   ✓ Follower 2 Joins Cluster
   
5. Jenkins & Maven Setup (5-10 min)
   ✓ Jenkins Installed
   ✓ Maven Installed
   
Total Deployment Time: ~30-45 minutes
```

## ⚠️ Common Issues

| Issue | Solution |
|-------|----------|
| SSH key not found | Check SSH key path in inventory |
| Connection timeout | Verify network connectivity: `ping 10.2.162.64` |
| Insufficient privileges | Ensure you have sudo/root access |
| Disk space | Run `df -h /` to check available space |
| Port already in use | Check: `netstat -tlnp \| grep :8080` |
| Token not generated | Check control plane: `journalctl -u kubelet -n 50` |
| Cluster ID mismatch | Verify file: `cat /opt/kafka/cluster.id` |

## 📚 Documentation Files

- **TOKEN_CLUSTER_ID_FLOW.md** - Detailed token/cluster ID flow with visuals
- **MONITORING_DEBUG.md** - Monitoring and debugging guide
- **README.md** - Project overview and setup instructions
- **quickstart.sh** - Automated quick start script

## 🔐 Security Notes

- SSH keys should be in `~/.ssh/` directory
- Update inventory with actual SSH key paths
- Consider using SSH agent: `ssh-add ~/.ssh/id_rsa`
- Restrict file permissions: `chmod 600 ansible/inventory/hosts.yml`

## 📞 Support

For issues, check:
1. MONITORING_DEBUG.md for common problems
2. Token/Cluster ID flow documentation
3. Service logs (journalctl, /var/log)
4. Ansible verbose output (-vvv)

