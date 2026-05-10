# Token & Cluster ID Flow - Comprehensive Guide

This document explains how Kubernetes join tokens and Kafka cluster IDs are **automatically generated and passed** from master/leader nodes to worker/follower nodes during Ansible execution.

---

## 📊 **How It Works - Visual Flow**

### **KUBERNETES TOKEN FLOW**

```
┌─────────────────────────────────────────────────────────────────┐
│                  KUBERNETES CLUSTER SETUP                       │
└─────────────────────────────────────────────────────────────────┘

PHASE 1: CONTROL PLANE INITIALIZATION
├─ kubeadm init runs
├─ Control Plane starts successfully
└─ Ready to generate tokens

    ↓

PHASE 2: TOKEN GENERATION (Control Plane Node)
├─ Command: kubeadm token create --print-join-command
├─ Output: Join token for workers
│  Example: kubeadm join 203.0.113.42:6443 --token abc123... --discovery-token-ca-cert-hash sha256:...
│
└─ Command: kubeadm init phase upload-certs --upload-certs
   Output: Certificate key for additional control planes
   Example: 8f2b34c789d0e...

    ↓

PHASE 3: TOKEN STORAGE (Ansible Facts)
├─ k8s_worker_join_command = "kubeadm join 203.0.113.42:6443 ..."
├─ k8s_control_plane_join_command = "kubeadm join ... --control-plane --certificate-key ..."
├─ k8s_token_generated_at = "2026-03-30T10:45:23.123456+00:00"
│
└─ These facts are DELEGATED to all worker nodes
   (Via: delegate_to, delegate_facts: true)

    ↓

PHASE 4: WORKER NODE CONSUMPTION (Worker Nodes - Serial)
├─ Worker 1 retrieves token from Control Plane facts
├─ Executes: kubeadm join 203.0.113.42:6443 ...
├─ Waits for worker 1 to join complete
│
├─ Worker 2 retrieves same token from Control Plane facts
├─ Executes: kubeadm join 203.0.113.42:6443 ...
└─ Waits for worker 2 to join complete

    ↓

RESULT: All nodes in cluster (kubectl get nodes)
├─ k8s-master-1 (Ready)
├─ k8s-worker-1 (Ready)
└─ k8s-worker-2 (Ready)
```

### **KAFKA CLUSTER ID FLOW**

```
┌─────────────────────────────────────────────────────────────────┐
│               KAFKA KRAFT CLUSTER SETUP                         │
└─────────────────────────────────────────────────────────────────┘

PHASE 1: LEADER NODE INITIALIZATION
├─ First node in inventory becomes leader
├─ Kafka directories created
└─ Ready to generate cluster ID

    ↓

PHASE 2: CLUSTER ID GENERATION (Leader Node)
├─ Command: uuidgen
├─ Output: Unique cluster ID
│  Example: 8f2b34c7-89d0-4e1a-91c2-7f5a3b8c9d0e
│
└─ Saved to: /opt/kafka/cluster.id

    ↓

PHASE 3: CLUSTER ID STORAGE (Ansible Facts)
├─ kafka_cluster_id = "8f2b34c7-89d0-4e1a-91c2-7f5a3b8c9d0e"
├─ kafka_cluster_id_generated_at = "2026-03-30T10:50:45.654321+00:00"
│
└─ These facts available to all follower nodes

    ↓

PHASE 4: CLUSTER ID DISTRIBUTION (File + Facts)
├─ File copied: /opt/kafka/cluster.id → each follower (/tmp/cluster.id)
├─ File moved: /tmp/cluster.id → /opt/kafka/cluster.id on follower
│
└─ Follower nodes can read cluster ID from:
   - File: /opt/kafka/cluster.id
   - Ansible Fact: hostvars['kafka-node-1']['kafka_cluster_id']

    ↓

PHASE 5: FOLLOWER NODE CONSUMPTION (Follower Nodes - Serial)
├─ Follower 1 retrieves cluster ID from leader
├─ Uses cluster ID in server.properties
├─ Starts Kafka broker
├─ Joins KRaft cluster
│
├─ Follower 2 retrieves cluster ID from leader
├─ Uses cluster ID in server.properties
├─ Starts Kafka broker
└─ Joins KRaft cluster

    ↓

RESULT: All nodes in Kafka cluster
├─ kafka-node-1 (Leader/Broker/Controller)
├─ kafka-node-2 (Follower/Broker/Controller)
└─ kafka-node-3 (Follower/Broker/Controller)
```

---

## 🔍 **Monitoring Token/Cluster ID Generation During Playbook Run**

When you run the playbook, you'll see console output like this:

### **Kubernetes Token Generation Output**

```
TASK [Display generated tokens on Control Plane]
debug:
  msg: |-
    ╔════════════════════════════════════════════════════════════╗
    ║    KUBERNETES TOKEN GENERATION - CONTROL PLANE             ║
    ╠════════════════════════════════════════════════════════════╣
    ║                                                            ║
    ║ ✓ Token Generated Successfully                             ║
    ║ Node: k8s-master-1                                         ║
    ║ Timestamp: 2026-03-30T10:45:23.123456+00:00                ║
    ║                                                            ║
    ║ WORKER JOIN TOKEN:                                         ║
    ║ kubeadm join 203.0.113.42:6443 --token abc123def456        ║
    ║ --discovery-token-ca-cert-hash sha256:xyz789...            ║
    ║                                                            ║
    ║ Certificate Key: 8f2b34c789d0e1a2b3c4d5e6f7g8h9i0j1k       ║
    ║                                                            ║
    ╚════════════════════════════════════════════════════════════╝
```

### **Kubernetes Token Distribution Output**

```
TASK [Confirm tokens stored in worker facts]
debug:
  msg: |-
    ╔════════════════════════════════════════════════════════════╗
    ║    KUBERNETES TOKEN DISTRIBUTION - CONTROL PLANE           ║
    ╠════════════════════════════════════════════════════════════╣
    ║                                                            ║
    ║ Distributing tokens to workers:                            ║
    ║   ✓ k8s-worker-1 (203.0.113.65)                             ║
    ║   ✓ k8s-worker-2 (203.0.113.66)                             ║
    ║                                                            ║
    ║ Distribution Method: Ansible Facts (in-memory)             ║
    ║ Status: READY FOR WORKER TO CONSUME                        ║
    ║                                                            ║
    ╚════════════════════════════════════════════════════════════╝
```

### **Kubernetes Token Consumption Output (Worker)**

```
TASK [Display token being retrieved from Control Plane]
debug:
  msg: |-
    ╔════════════════════════════════════════════════════════════╗
    ║    KUBERNETES TOKEN CONSUMPTION - WORKER NODE              ║
    ╠════════════════════════════════════════════════════════════╣
    ║                                                            ║
    ║ Worker: k8s-worker-1                                       ║
    ║ Connecting to: k8s-master-1                                ║
    ║ (203.0.113.42)                                              ║
    ║                                                            ║
    ║ Token Generated At: 2026-03-30T10:45:23.123456+00:00        ║
    ║                                                            ║
    ║ ✓ TOKEN RETRIEVED SUCCESSFULLY                             ║
    ║                                                            ║
    ║ JOIN COMMAND:                                              ║
    ║ kubeadm join 203.0.113.42:6443 --token abc123def456        ║
    ║ --discovery-token-ca-cert-hash sha256:xyz789...            ║
    ║                                                            ║
    ╚════════════════════════════════════════════════════════════╝

TASK [Join worker node to cluster]
ok: [k8s-worker-1]

TASK [Display worker node status]
debug:
  msg: |-
    ╔════════════════════════════════════════════════════════════╗
    ║    KUBERNETES CLUSTER JOIN - SUCCESS ✓                     ║
    ╠════════════════════════════════════════════════════════════╣
    ║                                                            ║
    ║ Worker Node: k8s-worker-1                                  ║
    ║ Joined at: 2026-03-30T10:47:15.456789+00:00                ║
    ║ Control Plane: k8s-master-1                                ║
    ║                                                            ║
    ║ Status: SUCCESSFULLY JOINED CLUSTER                        ║
    ║                                                            ║
    ╚════════════════════════════════════════════════════════════╝
```

### **Kafka Cluster ID Generation Output**

```
TASK [Display generated Cluster ID on Leader]
debug:
  msg: |-
    ╔════════════════════════════════════════════════════════════╗
    ║    KAFKA CLUSTER ID GENERATION - LEADER NODE               ║
    ╠════════════════════════════════════════════════════════════╣
    ║                                                            ║
    ║ ✓ Cluster ID Generated Successfully                        ║
    ║ Node: kafka-node-1                                         ║
    ║ Node ID: 1                                                 ║
    ║ Timestamp: 2026-03-30T10:52:01.987654+00:00                ║
    ║                                                            ║
    ║ CLUSTER ID (UUID):                                         ║
    ║ 8f2b34c7-89d0-4e1a-91c2-7f5a3b8c9d0e                       ║
    ║                                                            ║
    ║ File Location: /opt/kafka/cluster.id                       ║
    ║                                                            ║
    ╚════════════════════════════════════════════════════════════╝
```

### **Kafka Cluster ID Distribution Output**

```
TASK [Display Cluster ID distribution to Followers]
debug:
  msg: |-
    ╔════════════════════════════════════════════════════════════╗
    ║    KAFKA CLUSTER ID DISTRIBUTION - LEADER NODE             ║
    ╠════════════════════════════════════════════════════════════╣
    ║                                                            ║
    ║ Distributing Cluster ID to follower nodes:                ║
    ║   ✓ kafka-node-2 (203.0.113.71)                             ║
    ║   ✓ kafka-node-3 (203.0.113.72)                             ║
    ║                                                            ║
    ║ Cluster ID: 8f2b34c7-89d0-4e1a-91c2-7f5a3b8c9d0e           ║
    ║ Distribution Method: File Copy + Ansible Facts             ║
    ║ Status: READY FOR FOLLOWERS TO CONSUME                     ║
    ║                                                            ║
    ╚════════════════════════════════════════════════════════════╝
```

### **Kafka Cluster ID Consumption Output (Follower)**

```
TASK [Display Cluster ID being retrieved from Leader]
debug:
  msg: |-
    ╔════════════════════════════════════════════════════════════╗
    ║    KAFKA CLUSTER ID CONSUMPTION - FOLLOWER NODE            ║
    ╠════════════════════════════════════════════════════════════╣
    ║                                                            ║
    ║ Follower Node: kafka-node-2                                ║
    ║ Node ID: 2                                                 ║
    ║ Connecting to: kafka-node-1                                ║
    ║ (203.0.113.70)                                              ║
    ║                                                            ║
    ║ Cluster ID Generated At: 2026-03-30T10:52:01.987654+00:00  ║
    ║                                                            ║
    ║ ✓ CLUSTER ID RETRIEVED SUCCESSFULLY                        ║
    ║                                                            ║
    ║ CLUSTER ID (UUID):                                         ║
    ║ 8f2b34c7-89d0-4e1a-91c2-7f5a3b8c9d0e                       ║
    ║                                                            ║
    ╚════════════════════════════════════════════════════════════╝

TASK [Display Follower node configuration]
debug:
  msg: |-
    ╔════════════════════════════════════════════════════════════╗
    ║    KAFKA CLUSTER JOIN - SUCCESS ✓                          ║
    ╠════════════════════════════════════════════════════════════╣
    ║                                                            ║
    ║ Follower Node: kafka-node-2                                ║
    ║ Node ID: 2                                                 ║
    ║ Joined at: 2026-03-30T10:54:33.321654+00:00                ║
    ║                                                            ║
    ║ ✓ Cluster ID File Verified: /opt/kafka/cluster.id          ║
    ║ ✓ Cluster ID: 8f2b34c7-89d0-4e1a-91c2-7f5a3b8c9d0e         ║
    ║                                                            ║
    ║ Status: SUCCESSFULLY JOINED CLUSTER                        ║
    ║                                                            ║
    ╚════════════════════════════════════════════════════════════╝
```

---

## 🔧 **Ansible Mechanisms Used**

### **1. Delegate Facts (`delegate_facts: true`)**

```yaml
- name: Store join commands as facts for worker nodes
  set_fact:
    k8s_worker_join_command: "{{ worker_join_command.stdout }}"
    k8s_token_generated_at: "{{ ansible_date_time.iso8601 }}"
  delegate_to: "{{ item }}"
  delegate_facts: true
  loop: "{{ groups['k8s_workers'] }}"
```

**What it does:**
- Creates facts on remote nodes
- Makes data available via `hostvars`
- Survives across plays
- No SSH file transfer needed

### **2. Hostvars Access**

```yaml
- name: Join worker node to cluster
  command: "{{ hostvars[groups['k8s_control_plane'][0]]['k8s_worker_join_command'] }}"
```

**What it does:**
- Retrieves facts from control plane
- Works across serial execution
- Available during playbook run

### **3. Serial Execution**

```yaml
- name: Configure Kubernetes Worker Nodes
  hosts: k8s_workers
  serial: 1  # ONE worker at a time
```

**What it does:**
- Ensures proper sequencing
- Control plane ready before workers join
- Prevents race conditions

### **4. Wait Conditions**

```yaml
- name: Wait for join command to be available
  wait_for:
    timeout: 300
```

**What it does:**
- Blocks if token not ready
- Ensures synchronization
- Prevents failures from race conditions

---

## 📋 **Data Flow Summary**

| Component | Generation | Storage | Distribution | Consumption |
|-----------|-----------|---------|--------------|------------|
| **K8s Token** | `kubeadm token create` | Ansible Facts | `delegate_facts: true` | `hostvars[...]` |
| **K8s Cert Key** | `kubeadm init phase` | Ansible Facts | `delegate_facts: true` | `hostvars[...]` |
| **Kafka Cluster ID** | `uuidgen` | File + Facts | File Copy + Facts | File Read + `hostvars[...]` |
| **Transmission** | In-process | In-memory | Network (play-by-play) | In-memory |
| **Security** | Root restricted | SSH encrypted | SSH file copy | SSH encrypted |

---

## ✅ **Verification During Playbook Run**

To see all the token/cluster ID generation and distribution:

```bash
# Run with verbose output
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v

# Or with extra verbosity
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -vvv
```

You'll see:
1. ✅ Token generated on control plane
2. ✅ Token distribution to workers
3. ✅ Each worker retrieving token
4. ✅ Each worker joining cluster
5. ✅ Cluster ID generated on leader
6. ✅ Cluster ID distributed to followers
7. ✅ Each follower retrieving cluster ID
8. ✅ Each follower joining cluster

---

## 🚀 **Running the Complete Workflow**

```bash
# Deploy everything
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v

# Watch the flow:
# 1. K8s control plane → generates token
# 2. K8s workers → receive token → join
# 3. Kafka leader → generates cluster ID
# 4. Kafka followers → receive cluster ID → join

# Verify results
kubectl get nodes  # On control plane
kafka-metadata.sh  # On any Kafka node
```

---

## 📝 **Notes**

- **No manual copying required**: All tokens/IDs automatically passed
- **Encrypted transmission**: Uses SSH for all network communication
- **Serial execution**: Prevents race conditions
- **Idempotent**: Can be run multiple times safely
- **Observable**: Console output shows all steps

