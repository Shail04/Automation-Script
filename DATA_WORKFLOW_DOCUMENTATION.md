# 🏗️ Automation Script Infrastructure Dashboard - Data Workflow Documentation

**Generated:** May 10, 2026  
**Infrastructure Suite:** Kubernetes, Kafka, Jenkins, ELK Stack, Victoria Metrics  
**Status:** Production-Ready Automation

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architecture Overview](#architecture-overview)
3. [Complete Data Workflows](#complete-data-workflows)
4. [Network Topology](#network-topology)
5. [Component Details](#component-details)
6. [Deployment Pipeline](#deployment-pipeline)
7. [Integration Patterns](#integration-patterns)
8. [Monitoring & Observability](#monitoring--observability)

---

## Executive Summary

This automation suite orchestrates a complete production-grade infrastructure stack with:

- **Kubernetes Cluster**: Container orchestration (1.35.1) with 3 nodes
- **Kafka KRaft**: Distributed message streaming (4.0.0, 3-node cluster)
- **Jenkins/Maven**: CI/CD pipeline automation
- **ELK Stack**: Unified logging (9.1.2, 3-node cluster)
- **Victoria Metrics**: Time-series metrics storage & visualization
- **Ansible**: Infrastructure as Code orchestration

### Key Statistics

| Metric | Value |
|--------|-------|
| **Total Hosts** | 9 |
| **Total Services** | 15+ |
| **IP Range** | 203.0.113.0/24 |
| **Automation Tool** | Ansible 2.9+ |
| **Dynamic Features** | 2 (K8s tokens, Kafka cluster IDs) |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AUTOMATION INFRASTRUCTURE                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  Ansible Control Plane (Orchestrator)                        │   │
│  │  - Inventory Management (hosts.yml)                          │   │
│  │  - Dynamic Token/Cluster ID Generation                       │   │
│  │  - Serial Execution Control                                  │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                              │                                       │
│        ┌─────────────────────┼─────────────────────┐                │
│        │                     │                     │                │
│        ▼                     ▼                     ▼                │
│   ┌─────────────┐       ┌─────────────┐       ┌─────────────┐      │
│   │ Kubernetes  │       │   Kafka     │       │  Jenkins    │      │
│   │   Cluster   │       │   KRaft     │       │   /Maven    │      │
│   │  (3 nodes)  │       │  (3 nodes)  │       │  (1 node)   │      │
│   └──────┬──────┘       └──────┬──────┘       └──────┬──────┘      │
│          │                     │                     │               │
│          └─────────────────────┼─────────────────────┘               │
│                                ▼                                     │
│                    ┌──────────────────────┐                         │
│                    │    ELK Stack         │                         │
│                    │  Elasticsearch       │                         │
│                    │  Logstash (Ingest)   │                         │
│                    │  Kibana (UI)         │                         │
│                    └──────────┬───────────┘                         │
│                               │                                      │
│                               ▼                                      │
│                    ┌──────────────────────┐                         │
│                    │  Victoria Metrics    │                         │
│                    │  + Grafana           │                         │
│                    │  (Observability)     │                         │
│                    └──────────────────────┘                         │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Complete Data Workflows

### 1️⃣ Kubernetes Cluster Setup Workflow

**Objective:** Deploy a 3-node Kubernetes cluster with automatic token generation and worker node joining

#### Flow Diagram
```
Ansible Control Plane
        │
        ├─► Generate K8s Control Plane (203.0.113.42)
        │   ├─ Initialize kubeadm
        │   ├─ Install containerd 1.7.18
        │   └─ Start API server on port 6443
        │
        ├─► Generate Join Tokens
        │   ├─ Create kubeadm join command
        │   ├─ Extract certificate keys
        │   └─ Store in Ansible facts (hostvars)
        │
        └─► Deploy Worker Nodes (Serial)
            ├─► Worker 1 (203.0.113.65)
            │   ├─ Retrieve join command from hostvars
            │   ├─ Execute: kubeadm join
            │   └─ Verify: kubectl get nodes (NotReady → Ready)
            │
            └─► Worker 2 (203.0.113.66)
                ├─ Retrieve join command from hostvars
                ├─ Execute: kubeadm join
                └─ Verify: kubectl get nodes (both Ready)
```

#### Data Elements in Transit
- **Join Command**: 32-character token + certificate hash
- **API Server Certificate**: TLS credential for kubelet authentication
- **Pod CIDR**: 10.244.0.0/16 (Flannel overlay network)
- **Service CIDR**: 10.96.0.0/12 (default)

#### Error Handling
- Token expiration check (24 hours default)
- Certificate validation before node join
- Rollback: Remove worker node if join fails
- Retry logic: 3 attempts with 30-second delays

---

### 2️⃣ Kafka Cluster ID Distribution Workflow

**Objective:** Create 3-node Kafka KRaft cluster with automatic cluster ID generation and distribution

#### Flow Diagram
```
Ansible Inventory (leader = first host: kafka-node-1)
        │
        ├─► Leader Election
        │   └─ kafka-node-1 (203.0.113.70) = Broker ID 1 (Leader)
        │
        ├─► Kafka Format Storage
        │   ├─ mkdir /data/kafka
        │   ├─ Install Java 17
        │   └─ Extract Kafka 4.0.0 to /opt/kafka
        │
        ├─► Generate Cluster ID (Leader Only)
        │   ├─ Execute: kafka-storage.sh format --cluster-id <UUID>
        │   ├─ Generate new UUID (e.g., R5a8K2oOT3eX9mP6qLwZ8Q)
        │   ├─ Write to: /opt/kafka/cluster.id
        │   └─ Store in Ansible fact: kafka_cluster_id
        │
        ├─► Distribute Cluster ID to Followers
        │   ├─► Follower 1 (kafka-node-2: 203.0.113.71)
        │   │   ├─ Retrieve cluster ID from Ansible var
                │   ├─ Write to: /opt/kafka/cluster.id
        │   │   └─ Format log directory with same cluster ID
        │   │
        │   └─► Follower 2 (kafka-node-3: 203.0.113.72)
        │       ├─ Retrieve cluster ID from Ansible var
        │       ├─ Write to: /opt/kafka/cluster.id
        │       └─ Format log directory with same cluster ID
        │
        ├─► Configure Controller Quorum
        │   ├─ Set: controller.quorum.voters=1@203.0.113.70:9093,2@203.0.113.71:9093,3@203.0.113.72:9093
        │   └─ Each node knows full quorum membership
        │
        └─► Start Services & Verify
            ├─ Start all 3 brokers
            ├─ Verify cluster.id consistency (kafka_cluster_id across all nodes)
            └─ Validate controller quorum elected (logs show leader)
```

#### Data Elements in Transit
- **Cluster ID**: UUID format (36 characters)
- **Controller Quorum**: 3 broker node addresses + ports
- **Bootstrap Metadata**: Replicated across all brokers
- **Configuration Files**: server.properties with node-specific settings

#### Verification Commands
```bash
# Verify all nodes have same cluster ID
ansible kafka -i inventory/hosts.yml -m command -a "cat /opt/kafka/cluster.id"

# Expected output (all same):
kafka-node-1 | SUCCESS | rc=0 >> 
R5a8K2oOT3eX9mP6qLwZ8Q

kafka-node-2 | SUCCESS | rc=0 >> 
R5a8K2oOT3eX9mP6qLwZ8Q

kafka-node-3 | SUCCESS | rc=0 >> 
R5a8K2oOT3eX9mP6qLwZ8Q
```

---

### 3️⃣ Event Streaming Pipeline (Applications → Kafka → ELK)

**Objective:** Stream application events through Kafka for processing and storage in Elasticsearch

#### Data Flow
```
Applications (running in K8s or standalone)
        │
        ├─ Produce Events to Kafka Topics
        │  ├─ Topic: "application-logs"
        │  ├─ Topic: "transactions"
        │  ├─ Topic: "user-events"
        │  └─ Topic: "system-metrics"
        │
        ▼
Kafka Brokers (KRaft Mode)
        │
        ├─ Topic Replication Factor: 3
        ├─ Min In-Sync Replicas: 2
        ├─ Leader: Node 1 (Broker ID 1)
        ├─ Replicas: Nodes 2, 3
        │
        ├─ Topic Partitioning
        │  ├─ Partition 0 → Leader Node 1, Replicas: [2,3]
        │  ├─ Partition 1 → Leader Node 2, Replicas: [3,1]
        │  └─ Partition 2 → Leader Node 3, Replicas: [1,2]
        │
        ▼
Logstash (Log Ingestion)
        │
        ├─ Input: Kafka Consumer
        │  ├─ Group ID: "logstash-group"
        │  ├─ Offset Commit: auto
        │  └─ Parallel Threads: 4
        │
        ├─ Filter Pipeline
        │  ├─ Parse JSON/CSV
        │  ├─ Extract Fields (timestamp, level, message)
        │  ├─ Enrich Data (environment, hostname, service)
        │  ├─ GeoIP lookup (if applicable)
        │  └─ Hash sensitive data (PII redaction)
        │
        ├─ Output: Elasticsearch
        │  ├─ Index Pattern: "logs-%{+YYYY.MM.dd}"
        │  ├─ Bulk API: 1000 docs/batch
        │  └─ Compression: gzip
        │
        ▼
Elasticsearch Cluster
        │
        ├─ Indexing (Real-time)
        │  ├─ Primary Shard: Receives write
        │  ├─ Replica Shards: Replicated (2 replicas minimum)
        │  ├─ Refresh Interval: 1 second (near real-time)
        │  └─ Flush Interval: 30 seconds (durability)
        │
        ├─ Inverted Index
        │  ├─ Full-text searchable
        │  ├─ Field-level indexing
        │  └─ Aggregation support
        │
        ├─ Index Lifecycle Management
        │  ├─ Hot: Write to current index
        │  ├─ Warm: Rollover after 1 day / 50GB
        │  ├─ Cold: Archive after 7 days
        │  └─ Delete: After 90 days (configurable)
        │
        ▼
Kibana (Visualization)
        │
        ├─ Search Interface
        │  ├─ KQL (Kibana Query Language)
        │  ├─ Lucene Query Syntax
        │  └─ Time-range filtering
        │
        ├─ Dashboards
        │  ├─ Real-time log streaming
        │  ├─ Error rate trending
        │  ├─ Performance metrics
        │  └─ User behavior analysis
        │
        └─ Alerting
           ├─ Threshold-based alerts
           ├─ Webhook notifications
           └─ Integration with PagerDuty/Slack
```

#### Data Formats Supported
- **JSON**: Native format for application logs
- **CSV**: Structured event data
- **Syslog**: System and service logs
- **Binary**: Custom application formats (with parsing)

---

### 4️⃣ CI/CD Build & Deployment Pipeline

**Objective:** Automate application builds and deployments via Jenkins to Kubernetes

#### Pipeline Stages
```
Developer Push to Git Repository
        │
        ▼
Jenkins SCM Trigger
        │
        ├─ Poll SCM (5-minute intervals) OR
        ├─ Webhook trigger (GitHub, GitLab)
        └─ Manual trigger
        │
        ▼
Jenkins Job Execution
        │
        ├─ Stage 1: Checkout
        │  ├─ Clone git repository
        │  ├─ Checkout specific branch/tag
        │  └─ Load Jenkinsfile (pipeline definition)
        │
        ├─ Stage 2: Build (Maven)
        │  ├─ Execute: mvn clean compile
        │  ├─ Dependencies resolved (Maven Central)
        │  ├─ Java source code compiled to bytecode
        │  └─ Unit tests executed
        │
        ├─ Stage 3: Package
        │  ├─ Execute: mvn package -DskipTests
        │  ├─ Create JAR/WAR artifact
        │  ├─ Generate Docker image layers
        │  └─ Push to Docker registry (if configured)
        │
        ├─ Stage 4: Artifact Staging
        │  ├─ Store in: /var/lib/jenkins/workspace/project/target/
        │  ├─ Version: project-v1.2.3.jar
        │  └─ Metadata: Build info, timestamps, hashes
        │
        ├─ Stage 5: Docker Image Build (if needed)
        │  ├─ Dockerfile: FROM openjdk:17-slim
        │  ├─ COPY: artifact into image
        │  ├─ Build image tag: registry/app:build-123
        │  └─ Push to registry: docker push
        │
        ├─ Stage 6: Deploy to Kubernetes
        │  ├─ kubectl apply -f deployment.yaml
        │  ├─ Image pull: registry/app:build-123
        │  ├─ Pod creation in specified namespace
        │  └─ Rolling update strategy (maxUnavailable: 0)
        │
        ├─ Stage 7: Smoke Tests
        │  ├─ Health check: GET /health
        │  ├─ API endpoint validation
        │  ├─ Database connectivity verify
        │  └─ External service connectivity
        │
        └─ Stage 8: Logging & Reporting
           ├─ Build log stored in Jenkins
           ├─ Test results parsed (JUnit XML)
           ├─ Coverage reports generated
           ├─ Artifacts archived
           └─ Status posted to Git (commit status)
                │
                ▼
        Deployment Complete (Production)
        └─ Application accessible via K8s service
           └─ Logs forwarded to Kafka → ELK Stack
```

#### Data Flow in Build
```
Source Code (KB) → Compiled Classes (MB) → Packaged JAR (MB-GB) → Docker Image (GB) → Registry
```

---

### 5️⃣ Unified Logging Architecture

**Objective:** Centralize all logs from infrastructure and applications

#### Multi-Source Log Collection
```
Log Sources:
├─ Kubernetes
│  ├─ Pod stdout/stderr (via kubelet)
│  ├─ Container runtime logs
│  ├─ kubelet logs (/var/log/kubelet.log)
│  ├─ API server logs
│  └─ Controller manager logs
│
├─ Kafka
│  ├─ Broker logs (/opt/kafka/logs/server.log)
│  ├─ Controller logs (KRaft)
│  └─ Replication logs
│
├─ Jenkins
│  ├─ Build logs (per job per build)
│  ├─ System logs (/var/log/jenkins/jenkins.log)
│  └─ Plugin logs
│
├─ Elasticsearch
│  ├─ Cluster logs
│  ├─ Shard allocation logs
│  └─ GC logs (JVM)
│
└─ Application Services
   ├─ Custom application logs
   ├─ Framework logs (Spring, etc.)
   └─ Third-party library logs

        │
        └─► Collection Methods:
            ├─ Filebeat (log file tailing)
            ├─ Fluentd (flexible collection)
            ├─ Prometheus (metrics to logs)
            └─ Direct API pushes
        │
        ▼
Kafka Topics (Buffer)
        │
        ├─ Topic: "logs-kubernetes"
        ├─ Topic: "logs-kafka"
        ├─ Topic: "logs-jenkins"
        └─ Topic: "logs-application"
        │
        ▼
Logstash Processors
        │
        ├─ Input: Read from Kafka
        ├─ Filter: Parse & Enrich
        │  ├─ JSON parsing
        │  ├─ Timestamp normalization
        │  ├─ Field extraction
        │  ├─ Environment tagging
        │  └─ Sensitive data masking
        └─ Output: Index in Elasticsearch
        │
        ▼
Elasticsearch Index
        │
        ├─ Index Template: logs-*
        ├─ Settings:
        │  ├─ Shards: 3
        │  ├─ Replicas: 2
        │  ├─ Refresh: 1s
        │  └─ Retention: 90 days (ILM policy)
        │
        ├─ Mappings:
        │  ├─ @timestamp (date)
        │  ├─ host (keyword)
        │  ├─ service (keyword)
        │  ├─ level (keyword)
        │  ├─ message (text, analyzed)
        │  └─ tags (keyword array)
        │
        ▼
Kibana UI & Querying
        │
        ├─ Data View: "logs-*"
        ├─ Time Range: Last 24 hours
        ├─ Filters: service="jenkins", level="ERROR"
        └─ Aggregations: Terms, date histogram, percentiles
```

---

### 6️⃣ Metrics & Observability Flow

**Objective:** Collect and visualize infrastructure & application metrics

#### Metrics Pipeline
```
Metric Producers:
├─ Kubernetes (kubelet metrics)
│  ├─ CPU usage (container_cpu_usage_seconds_total)
│  ├─ Memory (container_memory_usage_bytes)
│  ├─ Network I/O (container_network_receive_bytes_total)
│  └─ Disk I/O (container_fs_usage_bytes)
│
├─ Kafka (JMX metrics)
│  ├─ Broker throughput (messages-in-per-sec)
│  ├─ Replication lag (underreplicatedjsonpartitions)
│  ├─ Controller status (IsController)
│  └─ Queue sizes (BytesInPerSec, BytesOutPerSec)
│
├─ Jenkins
│  ├─ Build queue length
│  ├─ Executor utilization
│  ├─ Build duration
│  └─ Job success rate
│
└─ Applications (custom metrics)
   ├─ Request latency
   ├─ Error rates
   ├─ Business metrics
   └─ Custom counters
        │
        ▼
Prometheus Scraper (15-60s intervals)
        │
        ├─ Scrape config:
        │  ├─ K8s ServiceMonitor: *.metrics:9090
        │  ├─ Kafka: 203.0.113.70:9308, .71, .72
        │  ├─ Jenkins: 203.0.113.42:8080/prometheus
        │  └─ Node exporters: :9100
        │
        └─ Metric relabeling:
           ├─ Add environment label
           ├─ Add region label
           └─ Drop high-cardinality labels
        │
        ▼
Victoria Metrics (Time-Series DB)
        │
        ├─ Ingestion: 100K+ metrics/sec capacity
        ├─ Storage: /apps/victoria-metrics/storage
        ├─ Retention: 12 months (configurable)
        ├─ Compression: gorilla algorithm
        ├─ Deduplication: Per-metric timestamps
        │
        ├─ Query Language: PromQL-compatible
        │  ├─ Instant queries (current value)
        │  ├─ Range queries (time series)
        │  ├─ Aggregations (avg, sum, max)
        │  └─ Mathematical operations
        │
        ▼
Grafana Dashboard
        │
        ├─ Visualization Types:
        │  ├─ Time-series graphs
        │  ├─ Gauge charts
        │  ├─ Heatmaps
        │  ├─ Table views
        │  └─ Custom plugins
        │
        ├─ Dashboards:
        │  ├─ Infrastructure Overview
        │  ├─ Kubernetes Cluster Health
        │  ├─ Kafka Broker Status
        │  ├─ Jenkins Build Pipeline
        │  └─ Application Performance
        │
        ├─ Alerting Rules:
        │  ├─ CPU > 80% for 5min → Alert
        │  ├─ Memory > 90% → Critical
        │  ├─ Kafka lag > 10000 msgs → Warning
        │  └─ Jenkins queue > 50 → Info
        │
        └─ Notification Channels:
           ├─ Email
           ├─ Slack
           ├─ PagerDuty
           └─ Webhooks
```

---

## Network Topology

### IP Address Allocation

| Component | Hostname | IP Address | Port | Service |
|-----------|----------|-----------|------|---------|
| **Kubernetes Control Plane** | k8s-master-1 | 203.0.113.42 | 6443 | kube-apiserver |
| **Kubernetes Worker 1** | k8s-worker-1 | 203.0.113.65 | 10250 | kubelet |
| **Kubernetes Worker 2** | k8s-worker-2 | 203.0.113.66 | 10250 | kubelet |
| **Kafka Node 1 (Leader)** | kafka-node-1 | 203.0.113.70 | 9092, 9093 | Broker, Controller |
| **Kafka Node 2** | kafka-node-2 | 203.0.113.71 | 9092, 9093 | Broker, Controller |
| **Kafka Node 3** | kafka-node-3 | 203.0.113.72 | 9092, 9093 | Broker, Controller |
| **Jenkins/Maven** | jenkins-server | 203.0.113.42 | 8080 | Jenkins HTTP |
| **Elasticsearch** | (varies) | Varies | 9200, 9300 | REST API, Node comm |
| **Kibana** | (varies) | Varies | 5601 | Kibana UI |
| **Victoria Metrics** | (varies) | Varies | 61990 | Metrics API |

### Network Segmentation

```
┌─ Management Network (Ansible Control)
│
├─ Kubernetes Network (203.0.113.64-66)
│  ├─ Pod Network (10.244.0.0/16) - Flannel overlay
│  ├─ Service Network (10.96.0.0/12) - K8s internal DNS
│  └─ Node Network (203.0.113.0/24) - Direct node-to-node
│
├─ Kafka Network (203.0.113.70-72)
│  ├─ Broker Network (9092) - Client connections
│  ├─ Controller Network (9093) - KRaft quorum
│  └─ JMX Port (9999) - Metrics collection
│
├─ CI/CD Network (203.0.113.42)
│  ├─ Jenkins UI (8080)
│  ├─ Jenkins Agent Connections (50000)
│  └─ Maven Repository Access (443)
│
└─ ELK Network
   ├─ Elasticsearch (9200, 9300)
   ├─ Kibana (5601)
   ├─ Logstash (5000)
   └─ Monitoring (61990)
```

---

## Component Details

### Kubernetes Cluster (1.35.1)

**Architecture:**
- 1 Control Plane + 2 Worker Nodes
- containerd 1.7.18 as container runtime
- Flannel CNI for pod networking

**Token Management:**
```yaml
# Auto-generated during deployment:
kubeadm token: <32-char-random>
certificate-key: <64-char-random>
discovery-token-ca-cert-hash: sha256:<hash>
```

### Kafka KRaft Cluster (4.0.0)

**Cluster Configuration:**
```properties
# server.properties (per node)
broker.id=1                    # Unique per node
process.roles=broker,controller
controller.quorum.voters=1@203.0.113.70:9093,2@203.0.113.71:9093,3@203.0.113.72:9093
controller.listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
listener.security.protocol.map=PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT
inter.broker.listener.name=PLAINTEXT
log.dirs=/data/kafka
cluster.id=R5a8K2oOT3eX9mP6qLwZ8Q  # Auto-distributed
```

### Jenkins CI/CD (2.440.3)

**Pipeline Stages:**
1. Checkout source code
2. Build with Maven (compile, test, package)
3. Create Docker image
4. Push to registry
5. Deploy to Kubernetes
6. Run smoke tests
7. Archive artifacts

### ELK Stack (9.1.2)

**Deployment:**
- 3-node Elasticsearch cluster (1 master, 2 data)
- Logstash for log ingestion and transformation
- Kibana for visualization and analysis

**Index Configuration:**
```json
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 2,
    "index.lifecycle.name": "logs-policy",
    "index.lifecycle.rollover_alias": "logs"
  },
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" },
      "host": { "type": "keyword" },
      "message": { "type": "text" },
      "level": { "type": "keyword" },
      "service": { "type": "keyword" }
    }
  }
}
```

---

## Deployment Pipeline

### Sequential Deployment Order

1. **Kubernetes Cluster Setup** (30-45 min)
   - Control plane deployment
   - Worker node joining
   - Network addon installation

2. **Kafka KRaft Cluster** (15-20 min)
   - Leader election & cluster ID generation
   - Broker configuration
   - Quorum formation

3. **Jenkins/Maven** (10-15 min)
   - Jenkins installation
   - Maven setup
   - Plugin configuration

4. **ELK Stack** (20-25 min)
   - Elasticsearch cluster formation
   - Logstash configuration
   - Kibana UI enablement

5. **Monitoring Stack** (10-15 min)
   - Victoria Metrics deployment
   - Grafana setup
   - Dashboard creation

6. **Integration & Testing** (10-15 min)
   - Cross-service connectivity verification
   - Data flow validation
   - Smoke tests

### Deployment Validation Commands

```bash
# Verify Kubernetes
kubectl get nodes                                    # All nodes READY
kubectl cluster-info                                 # Cluster accessible
kubectl get pods -A                                  # Core pods running

# Verify Kafka Cluster ID Distribution
ansible kafka -i inventory/hosts.yml -m command -a "cat /opt/kafka/cluster.id"  # All same

# Verify Jenkins
curl http://203.0.113.42:8080/api/json               # Jenkins API accessible

# Verify Elasticsearch
curl http://ES_IP:9200/_cluster/health              # status: green, nodes: 3

# Verify Data Flow
# 1. Produce message to Kafka
kafka-console-producer --bootstrap-server 203.0.113.70:9092 --topic test

# 2. Check Logstash consumption
tail -f /var/log/logstash/logstash-plain.log

# 3. Query Elasticsearch
curl "http://ES_IP:9200/logs-*/_search?q=*"

# 4. View in Kibana
curl http://KIBANA_IP:5601/api/status
```

---

## Integration Patterns

### Synchronous Communication Patterns

1. **Kubernetes ← → Kubelet (API calls)**
   - Control plane polls kubelet status
   - Kubelet reports node conditions
   - Pod event notifications

2. **Kafka ← → Broker (Log replication)**
   - Leader replicates to followers
   - ISR (in-sync replicas) coordination
   - Acknowledged writes

3. **Jenkins ← → Kubernetes (Deployments)**
   - Jenkins calls kubectl via API
   - Waits for deployment rollout
   - Validates pod readiness

### Asynchronous Communication Patterns

1. **Applications → Kafka (Event Publishing)**
   - Non-blocking topic writes
   - Batch message publishing
   - Offset tracking

2. **Kafka → Logstash (Event Streaming)**
   - Consumer group coordination
   - Lag-aware processing
   - Error retry logic

3. **Metrics → Victoria Metrics**
   - Scrape intervals (30-60s)
   - Fire-and-forget UDP
   - Batch compression

---

## Monitoring & Observability

### Key Metrics to Monitor

| Metric | Source | Alert Threshold | Remediation |
|--------|--------|-----------------|-------------|
| K8s Node CPU | kubelet | > 80% for 5min | Scale horizontally |
| K8s Memory | kubelet | > 90% | Evict pods / Scale |
| Kafka Broker Lag | Kafka JMX | > 10K msgs | Increase consumer throughput |
| Kafka Replication Lag | Kafka | > 0 | Investigate broker ISR |
| Jenkins Queue | Jenkins API | > 50 jobs | Add executors / Agents |
| ES Cluster Health | Elasticsearch | Red | Investigate shard allocation |
| Elasticsearch Disk | Elasticsearch | > 85% | Add data nodes / Archive |
| Logstash Lag | Logstash metrics | > 1000 events | Increase pipeline throughput |

### Alert Channels

- **Email**: ops-team@company.com
- **Slack**: #infrastructure-alerts
- **PagerDuty**: For critical outages

### Dashboards to Create

1. **Infrastructure Overview**: CPU, memory, network I/O
2. **Kubernetes Health**: Node status, pod counts, deploy success rate
3. **Kafka Throughput**: Messages in/out, broker lag, replication status
4. **Jenkins Pipeline**: Build queue, success rate, duration trends
5. **Log Analysis**: Error rates, top errors, error sources
6. **System Capacity**: Trending analysis, forecast projections

---

## References

- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Kafka KRaft Documentation**: https://kafka.apache.org/documentation/#kraft
- **Elasticsearch Documentation**: https://www.elastic.co/guide/
- **Ansible Documentation**: https://docs.ansible.com/
- **Victoria Metrics**: https://victoriametrics.com/
- **Grafana**: https://grafana.com/grafana/

---

**Dashboard Generated:** May 10, 2026  
**Last Updated:** 2026-05-10  
**Version:** 1.0  
**Status:** Production Ready ✅
