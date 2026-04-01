# 📦 Ansible Automation Suite - Deployment Package

Complete automation suite for deploying Kubernetes, Kafka, and Jenkins infrastructure.

## 📁 Package Contents

### Documentation Files
```
ansible/
├── README.md                      # Main setup and overview guide
├── QUICK_REFERENCE.md            # One-page command cheat sheet
├── VALIDATION_CHECKLIST.md        # Pre & post-deployment verification
├── MONITORING_DEBUG.md            # Issues, solutions, debugging guide
├── TOKEN_CLUSTER_ID_FLOW.md      # How tokens/IDs flow through automation
└── DEPLOYMENT_SUMMARY.md          # This file
```

### Configuration Files
```
ansible/
├── ansible.cfg                    # Ansible configuration
├── inventory/
│   └── hosts.yml                  # Infrastructure inventory with all VMs
└── quickstart.sh                  # Quick start automation script
```

### Playbook Files
```
ansible/playbooks/
├── site.yml                       # Master orchestration playbook
├── kubernetes.yml                 # Kubernetes cluster setup
├── kafka.yml                      # Kafka cluster setup
└── jenkins_maven.yml              # Jenkins & Maven installation
```

---

## 🎯 Quick Start

### Step 1: Review Documentation (5 min)
Start here based on your need:
- **New to this?** → Read `README.md`
- **Need commands fast?** → Read `QUICK_REFERENCE.md`
- **Running soon?** → Read `VALIDATION_CHECKLIST.md`
- **Understanding flow?** → Read `TOKEN_CLUSTER_ID_FLOW.md`

### Step 2: Validate Environment (10-15 min)
```bash
cd c:\Users\sbm26\Automation-Script\ansible

# Use VALIDATION_CHECKLIST.md section by section:
# 1. Run infrastructure prerequisites checks
# 2. Verify Ansible configuration
# 3. Test connectivity
# 4. Validate playbook syntax
# 5. Run dry-run with --check
```

### Step 3: Deploy (30-45 min)
```bash
# Full deployment with monitoring
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v

# OR save to log for analysis
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v 2>&1 | tee deploy-$(date +%Y%m%d-%H%M%S).log
```

### Step 4: Verify Success (5 min)
```bash
# Check Kubernetes
ssh root@10.2.162.64 "kubectl get nodes"

# Check Kafka cluster ID consistency
ansible kafka -i inventory/hosts.yml -m command -a "cat /opt/kafka/cluster.id"

# Check Jenkins
curl http://10.2.162.80:8080
```

---

## 🏗️ What Gets Deployed

### Kubernetes Cluster
- **Control Plane**: 1x master node (10.2.162.64)
- **Worker Nodes**: 2x workers (10.2.162.65, 10.2.162.66)
- **Version**: 1.35.1
- **Container Runtime**: containerd 1.7.18
- **Networking**: Flannel CNI

**Dynamic Token Handling:**
- Master generates join tokens automatically
- Workers join cluster using shared tokens
- No manual token copying required

### Kafka Cluster
- **Nodes**: 3x brokers in KRaft mode (10.2.162.70, 71, 72)
- **Version**: 4.0.0
- **Mode**: Kraft (no Zookeeper)
- **Java**: OpenJDK 17
- **Features**: Automatic cluster ID generation and distribution

**Dynamic Cluster ID Handling:**
- Leader generates UUID cluster ID
- Cluster ID automatically distributed to followers
- All nodes configured for controller quorum

### Jenkins CI/CD
- **Server**: Single node (10.2.162.80)
- **Jenkins**: 2.440.3
- **Maven**: 3.9.9
- **Java**: OpenJDK 17 JDK
- **Port**: 8080

---

## 🔄 Data Flow Architecture

### Kubernetes Token Flow
```
STEP 1: Control Plane Generates Tokens
  └─ kubeadm token create --print-join-command
     └─ Stored in Ansible facts on master

STEP 2: Distribute Tokens to Workers
  └─ Ansible delegates facts to all worker nodes
     └─ Uses delegate_to + delegate_facts: true

STEP 3: Workers Retrieve and Join
  └─ Worker retrieves token from hostvars[master]
     └─ kubeadm join <token>
        └─ Cluster joined successfully
```

### Kafka Cluster ID Flow
```
STEP 1: Leader Generates Cluster ID
  └─ uuidgen generates unique UUID
     └─ Stored in /opt/kafka/cluster.id
        └─ Also stored in Ansible facts

STEP 2: Distribute to Followers
  └─ File copied to all followers via delegation
     └─ Also distributed via Ansible facts

STEP 3: Followers Consume Cluster ID
  └─ Followers read cluster ID from multiple sources
     └─ From file: /opt/kafka/cluster.id
        └─ From facts: hostvars[leader]['kafka_cluster_id']
           └─ Cluster join successful
```

---

## 📊 Documentation Guide

| File | Purpose | When to Use | Read Time |
|------|---------|-------------|-----------|
| **README.md** | Project overview, setup instructions | Starting point | 10-15 min |
| **QUICK_REFERENCE.md** | Common commands, quick lookup | During operations | 5 min lookup |
| **VALIDATION_CHECKLIST.md** | Pre-deployment verification | Before running playbook | 15-20 min |
| **MONITORING_DEBUG.md** | Troubleshooting, common issues | When problems occur | 10 min lookup |
| **TOKEN_CLUSTER_ID_FLOW.md** | How automation works internally | Understanding process | 15-20 min |
| **DEPLOYMENT_SUMMARY.md** | Package overview (this file) | Quick overview | 5 min |

---

## ⚙️ System Requirements

### Control Machine
- Ansible 2.9+
- Python 3.8+
- SSH client with key-based auth
- 2GB RAM minimum

### Target Machines

| Component | CPU | RAM | Disk | Network |
|-----------|-----|-----|------|---------|
| **Kubernetes Control Plane** | 2 cores | 4GB | 40GB | IP: 10.2.162.64 |
| **Kubernetes Workers** (×2) | 2 cores | 4GB | 40GB | IP: 10.2.162.65-66 |
| **Kafka Brokers** (×3) | 4 cores | 8GB | 50GB | IP: 10.2.162.70-72 |
| **Jenkins** | 2 cores | 4GB | 30GB | IP: 10.2.162.80 |

---

## 🔐 Security Configuration

### SSH Access
```bash
# All SSH access uses key-based authentication
# Default user: root
# SSH keys: ~/.ssh/id_rsa (public key on all targets)

# To update key path, edit: inventory/hosts.yml
ansible_ssh_private_key_file: /path/to/key
```

### Proxy Support
```yaml
# If using proxy, configure in inventory:
http_proxy: http://cloudproxy.nat.bt.com:8080
https_proxy: http://cloudproxy.nat.bt.com:8080
no_proxy: "localhost,127.0.0.1,10.2.160.0/16"
```

### Secrets Management
```bash
# For sensitive data, use Ansible Vault:
ansible-vault create group_vars/all/vault.yml
ansible-playbook playbooks/site.yml --ask-vault-pass
```

---

## 🚀 Typical Deployment Workflow

### Phase 1: Preparation (15 min)
1. Read `README.md` for overview
2. Verify SSH access to all nodes
3. Update `inventory/hosts.yml` if needed
4. Review `VALIDATION_CHECKLIST.md`

### Phase 2: Validation (20 min)
1. Test connectivity: `ansible all -i inventory/hosts.yml -m ping`
2. Validate syntax: `ansible-playbook playbooks/site.yml --syntax-check`
3. Run dry-run: `ansible-playbook playbooks/site.yml --check`
4. Review expected behavior in `TOKEN_CLUSTER_ID_FLOW.md`

### Phase 3: Deployment (30-45 min)
1. Run full playbook: `ansible-playbook playbooks/site.yml -v`
2. Monitor debug output for tokens/cluster IDs
3. Watch for success messages in each phase
4. Keep reference to `MONITORING_DEBUG.md` for issues

### Phase 4: Verification (10 min)
1. Verify Kubernetes: `kubectl get nodes`
2. Verify Kafka: Check cluster IDs match on all nodes
3. Verify Jenkins: Access web UI at `http://10.2.162.80:8080`
4. Review logs if any issues found

---

## 📞 Troubleshooting Quick Links

| Issue | Location | Solution |
|-------|----------|----------|
| SSH connection fails | MONITORING_DEBUG.md | SSH Connection Issues section |
| Token not generated | MONITORING_DEBUG.md | Common Issues table |
| Cluster ID mismatch | MONITORING_DEBUG.md | Manual Verification section |
| Playbook won't run | VALIDATION_CHECKLIST.md | Pre-Deployment checklist |
| Don't know command | QUICK_REFERENCE.md | Common Commands section |
| Need to understand flow | TOKEN_CLUSTER_ID_FLOW.md | Complete documentation |

---

## ✅ Deployment Checklist

Before you start:
- [ ] Reviewed `README.md`
- [ ] Completed `VALIDATION_CHECKLIST.md`
- [ ] SSH connectivity verified with `ansible all -m ping`
- [ ] Playbook syntax validated with `--syntax-check`
- [ ] Dry-run executed successfully with `--check`

Ready to deploy:
```bash
cd c:\Users\sbm26\Automation-Script\ansible
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v
```

---

## 📈 Expected Deployment Timeline

| Component | Duration | Status Indicator |
|-----------|----------|-----------------|
| Kubernetes Control Plane | 5-10 min | ✓ Token Generated |
| Kubernetes Workers | 4-6 min | ✓ Nodes Join Cluster |
| Kafka Leader | 3-5 min | ✓ Cluster ID Generated |
| Kafka Followers | 4-6 min | ✓ Cluster Joined |
| Jenkins & Maven | 5-10 min | ✓ Port 8080 Ready |
| **TOTAL** | **~30-45 min** | ✅ All Services Running |

---

## 🎓 Learning Resources

### Understanding Token Generation
1. Read `TOKEN_CLUSTER_ID_FLOW.md` - Phase 1: Initialization
2. Check `playbooks/kubernetes.yml` - Search for "kubeadm token create"
3. Review debug output during deployment

### Understanding Cluster ID Distribution
1. Read `TOKEN_CLUSTER_ID_FLOW.md` - Phase 2: Generation & Phase 3: Distribution
2. Check `playbooks/kafka.yml` - Search for "uuidgen"
3. Review debug output during deployment

### Ansible Patterns Used
- **delegate_to** - Execute task on specific host
- **delegate_facts** - Store facts on different host
- **hostvars** - Access variables from other hosts
- **serial** - Execute per-host instead of parallel
- **set_fact** - Create dynamic variables

---

## 📝 Notes

- All playbooks are **idempotent** - safe to run multiple times
- **Serial execution** prevents race conditions
- **Debug output** shows complete data flow
- **No manual steps** required between phases
- All **tokens and IDs are automatically generated**

---

## 🔗 Next Steps After Deployment

### Post-Deployment
1. Access Jenkins UI and configure initial admin account
2. Create first Kubernetes namespace
3. Deploy sample application to Kubernetes
4. Test Kafka by creating topic and producing messages

### Monitoring & Maintenance
- Set up Prometheus for Kubernetes monitoring
- Configure ELK stack for Kafka logging
- Enable Jenkins plugin management
- Implement backup procedures

### Security Hardening
- Enable RBAC in Kubernetes
- Configure TLS for Kafka
- Set up Jenkins authentication
- Implement network policies

---

## 📞 Support

For detailed help:
- **Quick commands** → `QUICK_REFERENCE.md`
- **Pre-deployment** → `VALIDATION_CHECKLIST.md`
- **Issues during run** → `MONITORING_DEBUG.md`
- **Understanding automation** → `TOKEN_CLUSTER_ID_FLOW.md`
- **Setup instructions** → `README.md`

All files are in: `c:\Users\sbm26\Automation-Script\ansible\`

