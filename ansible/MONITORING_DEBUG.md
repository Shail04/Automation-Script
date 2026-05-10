# Token & Cluster ID - Monitoring & Debugging Guide

Quick reference for monitoring token/cluster ID generation during playbook execution.

## 🎯 What to Look For During Playbook Run

### Kubernetes Tokens

#### ✅ **Good Output - Token Generated**
```
TASK [Display generated tokens on Control Plane]
✓ Token Generated Successfully
✓ Timestamp: 2026-03-30T10:45:23...
✓ WORKER JOIN TOKEN: kubeadm join 203.0.113.42:6443 --token abc123...
```

#### ✅ **Good Output - Tokens Distributed**
```
TASK [Confirm tokens stored in worker facts]
✓ Distribution Method: Ansible Facts (in-memory)
✓ Status: READY FOR WORKER TO CONSUME
✓ k8s-worker-1 (203.0.113.65)
✓ k8s-worker-2 (203.0.113.66)
```

#### ✅ **Good Output - Token Retrieved & Used**
```
TASK [Display token being retrieved from Control Plane]
✓ TOKEN RETRIEVED SUCCESSFULLY
✓ Worker: k8s-worker-1
✓ JOIN COMMAND: kubeadm join 203.0.113.42:6443...

TASK [Join worker node to cluster]
✓ Join command executed successfully
```

#### ✅ **Good Output - Cluster Join Success**
```
TASK [Display worker node status]
✓ KUBERNETES CLUSTER JOIN - SUCCESS ✓
✓ Worker Node: k8s-worker-1
✓ Status: SUCCESSFULLY JOINED CLUSTER
```

---

### Kafka Cluster IDs

#### ✅ **Good Output - Cluster ID Generated**
```
TASK [Display generated Cluster ID on Leader]
✓ Cluster ID Generated Successfully
✓ Node: kafka-node-1
✓ CLUSTER ID (UUID): 8f2b34c7-89d0-4e1a-91c2-7f5a3b8c9d0e
✓ File Location: /opt/kafka/cluster.id
```

#### ✅ **Good Output - Cluster ID Distributed**
```
TASK [Display Cluster ID distribution to Followers]
✓ Distributing Cluster ID to follower nodes:
✓ kafka-node-2 (203.0.113.71)
✓ kafka-node-3 (203.0.113.72)
✓ Distribution Method: File Copy + Ansible Facts
✓ Status: READY FOR FOLLOWERS TO CONSUME
```

#### ✅ **Good Output - Cluster ID Retrieved**
```
TASK [Display Cluster ID being retrieved from Leader]
✓ Follower Node: kafka-node-2
✓ Connecting to: kafka-node-1 (203.0.113.70)
✓ CLUSTER ID RETRIEVED SUCCESSFULLY
✓ CLUSTER ID (UUID): 8f2b34c7-89d0-4e1a-91c2-7f5a3b8c9d0e
```

#### ✅ **Good Output - Cluster Join Success**
```
TASK [Display Follower node configuration]
✓ KAFKA CLUSTER JOIN - SUCCESS ✓
✓ Follower Node: kafka-node-2
✓ ✓ Cluster ID File Verified: /opt/kafka/cluster.id
✓ Status: SUCCESSFULLY JOINED CLUSTER
```

---

## ❌ **Common Issues & Solutions**

### Issue: Token Not Generated

**Error Message:**
```
FAILED! - "hostvars[groups['k8s_control_plane'][0]]['k8s_worker_join_command'] is not defined"
```

**Cause:** Control plane failed to initialize

**Solution:**
```bash
# Check control plane logs
ssh root@203.0.113.42
journalctl -u kubelet -n 50
systemctl status kubelet
```

### Issue: Cluster ID Not Found

**Error Message:**
```
FAILED! - "hostvars[groups['kafka'][0]]['kafka_cluster_id'] is not defined"
```

**Cause:** Leader failed to generate cluster ID

**Solution:**
```bash
# Check leader logs
ssh root@203.0.113.70
journalctl -u kafka -n 50
ls -la /opt/kafka/cluster.id
cat /opt/kafka/cluster.id
```

### Issue: Worker Join Timeout

**Error Message:**
```
FAILED! - "Wait for join command to be available" timed out after 300 seconds
```

**Cause:** Control plane not ready or token generation failed

**Solution:**
```bash
# Verify control plane
ssh root@203.0.113.42
kubectl get nodes
kubeadm token list
systemctl status kubelet
```

### Issue: Follower Kafka Join Failure

**Error Message:**
```
FAILED! - "kafka: Connection refused"
```

**Cause:** Leader not accessible or cluster ID mismatch

**Solution:**
```bash
# Check leader accessibility
ssh root@203.0.113.70
netstat -tlnp | grep 9093  # Controller port
curl -v telnet://203.0.113.70:9093

# Check cluster ID consistency
cat /opt/kafka/cluster.id
```

---

## 🔍 **Manual Verification Steps**

### Verify Kubernetes Token Flow

```bash
# 1. On control plane
ssh root@203.0.113.42
kubeadm token list
kubeadm token create --print-join-command

# 2. Copy the output and run on worker
ssh root@203.0.113.65
<paste-kubeadm-join-command>

# 3. Verify worker joined
kubectl get nodes
```

### Verify Kafka Cluster ID Flow

```bash
# 1. On leader
ssh root@203.0.113.70
cat /opt/kafka/cluster.id  # Should output UUID

# 2. On follower
ssh root@203.0.113.71
cat /opt/kafka/cluster.id  # Should match leader's ID

# 3. Verify cluster formation
kafka-metadata.sh --bootstrap-server kafka-node-1:9092 --snapshot /opt/kafka/data/logs/__cluster_metadata-0/00000000000000000000.log
```

---

## 📊 **Monitoring During Deployment**

### Running with Verbose Output

```bash
# Normal verbosity (recommended)
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v

# High verbosity (see all details)
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -vvv

# Save output to file
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v > deployment.log 2>&1
tail -f deployment.log  # Monitor in real-time
```

### Filtering for Token/ID Output

```bash
# Show only token generation
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v | grep -A 20 "TOKEN GENERATION"

# Show only cluster ID generation
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v | grep -A 20 "CLUSTER ID GENERATION"

# Show only success/failure
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v | grep -E "(SUCCESS|FAILED|✓)"
```

---

## 🧪 **Testing Token/ID Distribution Manually**

### Test 1: Verify Ansible Facts

```bash
# Add fact verification tasks to playbook
cat > test-facts.yml << 'EOF'
- name: Test Ansible Facts Distribution
  hosts: k8s_workers
  gather_facts: false
  tasks:
    - name: Display facts from control plane
      debug:
        msg: |
          Control Plane Facts:
          - k8s_worker_join_command: {{ hostvars[groups['k8s_control_plane'][0]]['k8s_worker_join_command'] | default('NOT FOUND') }}
          - k8s_token_generated_at: {{ hostvars[groups['k8s_control_plane'][0]]['k8s_token_generated_at'] | default('NOT FOUND') }}
EOF

ansible-playbook test-facts.yml -i inventory/hosts.yml
```

### Test 2: Verify File Distribution

```bash
# Test Kafka cluster ID file distribution
ansible kafka -i inventory/hosts.yml -m command -a "cat /opt/kafka/cluster.id"

# Expected output:
# kafka-node-1 | CHANGED | rc=0 >>
# 8f2b34c7-89d0-4e1a-91c2-7f5a3b8c9d0e
# 
# kafka-node-2 | CHANGED | rc=0 >>
# 8f2b34c7-89d0-4e1a-91c2-7f5a3b8c9d0e
# 
# kafka-node-3 | CHANGED | rc=0 >>
# 8f2b34c7-89d0-4e1a-91c2-7f5a3b8c9d0e
```

---

## 📝 **Deployment Checklist**

- [ ] Pre-deployment SSH test: `ansible all -i inventory/hosts.yml -m ping`
- [ ] Verify inventory: `ansible-inventory -i inventory/hosts.yml --list`
- [ ] Run with verbose: `ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v`
- [ ] Monitor token generation (look for ✅ marks)
- [ ] Monitor cluster ID generation (look for ✅ marks)
- [ ] Verify workers join: `kubectl get nodes`
- [ ] Verify Kafka cluster: `kafka-metadata.sh`
- [ ] Check logs: `journalctl -u kubelet` / `journalctl -u kafka`

---

## 🎓 **Understanding the Architecture**

```
┌──────────────────────────────────────────────────────────────────┐
│                    ANSIBLE CONTROL MACHINE                       │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Playbook Execution                                    │    │
│  │                                                         │    │
│  │  1. Connect to k8s-master-1 via SSH                    │    │
│  │  2. Run: kubeadm token create                          │    │
│  │  3. Store token in Ansible facts (memory)              │    │
│  │  4. Delegate facts to k8s-worker-1 (SSH)               │    │
│  │  5. Delegate facts to k8s-worker-2 (SSH)               │    │
│  │  6. Connect to k8s-worker-1                            │    │
│  │  7. Retrieve token from hostvars (k8s-master-1)        │    │
│  │  8. Run: kubeadm join <token>                          │    │
│  │  9. Repeat for k8s-worker-2                            │    │
│  │  10. Verify: kubectl get nodes                         │    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

Data Flow (No Manual Intervention):
Token: k8s-master-1 (in memory) → Ansible (in memory) → k8s-worker-1 (SSH)
```

---

## 📞 **Quick Troubleshooting**

| Issue | Check | Fix |
|-------|-------|-----|
| Token not generated | Control plane kubelet | SSH to master, check `systemctl status kubelet` |
| Token not distributed | Ansible delegated facts | Run with `-vvv` to see fact delegation |
| Worker join fails | Network connectivity | Check: `ping 203.0.113.42` from worker |
| Cluster ID mismatch | File corruption | Verify: `cat /opt/kafka/cluster.id` on all nodes |
| Playbook timeout | Service initialization | Increase wait timeout in playbook vars |

