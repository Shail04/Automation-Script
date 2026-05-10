# 🏗️ Automation Script - Infrastructure Dashboard Index

**Project:** Automation-Script Infrastructure Automation Suite  
**Created:** May 10, 2026  
**Version:** 1.0  
**Status:** ✅ Complete & Production Ready

---

## 📑 Documentation Index

### 🎯 Start Here
- **[DASHBOARD_GUIDE.md](DASHBOARD_GUIDE.md)** - Quick start guide for accessing dashboards
  - How to open the HTML dashboard
  - Navigation guide for each tab
  - Quick reference commands
  - Troubleshooting tips

### 📊 Main Dashboard
- **[INFRASTRUCTURE_DASHBOARD.html](INFRASTRUCTURE_DASHBOARD.html)** - Interactive visual dashboard
  - **Open this file in a web browser to view the dashboard**
  - 7 interactive tabs with comprehensive infrastructure overview
  - Visual diagrams using Mermaid.js and SVG
  - Service matrices and topology views
  - Deployment pipeline visualization

### 📖 Detailed Documentation
- **[DATA_WORKFLOW_DOCUMENTATION.md](DATA_WORKFLOW_DOCUMENTATION.md)** - Complete technical documentation
  - Executive summary
  - 6 detailed data workflows
  - Network topology & IP schema
  - Component specifications
  - Deployment pipeline details
  - Integration patterns
  - Monitoring & observability

### 📋 Existing Project Documentation
- **[README.md](ansible/README.md)** - Setup and overview guide
- **[QUICK_REFERENCE.md](ansible/QUICK_REFERENCE.md)** - Common commands cheat sheet
- **[DEPLOYMENT_SUMMARY.md](ansible/DEPLOYMENT_SUMMARY.md)** - Package contents summary
- **[VALIDATION_CHECKLIST.md](ansible/VALIDATION_CHECKLIST.md)** - Pre & post deployment checks
- **[TOKEN_CLUSTER_ID_FLOW.md](ansible/TOKEN_CLUSTER_ID_FLOW.md)** - Token/ID flow details
- **[MONITORING_DEBUG.md](ansible/MONITORING_DEBUG.md)** - Monitoring & troubleshooting

---

## 🗂️ Infrastructure Components

### Kubernetes Cluster (1.35.1)
```
├─ Control Plane: 203.0.113.42:6443
├─ Worker 1: 203.0.113.65
└─ Worker 2: 203.0.113.66

Runtime: containerd 1.7.18
Networking: Flannel CNI
Pod Network: 10.244.0.0/16
Service Network: 10.96.0.0/12
```

### Kafka KRaft Cluster (4.0.0)
```
├─ Node 1 (Leader): 203.0.113.70 (Broker ID: 1)
├─ Node 2: 203.0.113.71 (Broker ID: 2)
└─ Node 3: 203.0.113.72 (Broker ID: 3)

Mode: KRaft (no Zookeeper)
Java: OpenJDK 17
Cluster ID: Auto-generated & Distributed
Controller Quorum: All 3 nodes
```

### CI/CD Pipeline
```
├─ Jenkins: 203.0.113.42:8080 (v2.440.3)
└─ Maven: 3.9.9

Java: OpenJDK 17
Build Tool: Maven
Kubernetes Integration: Pod executor
```

### ELK Stack (9.1.2)
```
├─ Elasticsearch: 3-node cluster (1 master, 2 data)
├─ Logstash: Log ingestion & processing
└─ Kibana: Visualization & search

Shards: 3 (per index)
Replicas: 2
Index Retention: 90 days (configurable)
```

### Monitoring Stack
```
├─ Victoria Metrics: Time-series database
│  ├─ Port: 61990
│  ├─ Retention: 12 months
│  └─ Data Dir: /apps/victoria-metrics/storage
│
└─ Grafana: Visualization & alerting

Query Language: PromQL-compatible
Scrape Interval: 15-60 seconds
```

---

## 📊 Dashboard Navigation

### Interactive Dashboard Tabs (INFRASTRUCTURE_DASHBOARD.html)

| Tab | Purpose | Best For |
|-----|---------|----------|
| **Overview** | Component summary & key features | Quick understanding of infrastructure |
| **Architecture** | System design & component relationships | Understanding how pieces fit together |
| **Data Workflows** | 6 detailed data flows end-to-end | Tracing data paths through system |
| **Components** | Detailed specs for each service | Deep technical reference |
| **Network Topology** | IP schema, ports, communication patterns | Connectivity & network planning |
| **Services Matrix** | Integration matrix & dependencies | Service relationships |
| **Deployment Pipeline** | Sequential deployment with validation | Implementation & verification |

---

## 🔄 Data Workflows Documented

### 1. Kubernetes Cluster Setup
**Flow:** Ansible → Control Plane → Token Generation → Worker Joining

Key points:
- Automatic join token generation
- Serial worker node joining
- Certificate-based authentication

### 2. Kafka Cluster ID Distribution
**Flow:** Ansible → Leader Election → UUID Generation → Distribution

Key points:
- Leader election (first node)
- Automatic cluster ID generation
- Distribution to all followers
- Controller quorum coordination

### 3. Event Streaming
**Flow:** Applications → Kafka Topics → Logstash → Elasticsearch → Kibana

Key points:
- Multi-topic architecture
- Topic replication (factor: 3)
- Logstash filtering & enrichment
- Real-time search & visualization

### 4. CI/CD Pipeline
**Flow:** Git → Jenkins → Maven Build → Docker Image → K8s Deployment

Key points:
- Automated build triggering
- Maven artifact generation
- Kubernetes rolling deployments
- Smoke test validation

### 5. Unified Logging
**Flow:** All Components → Kafka Buffer → Logstash Processing → Elasticsearch Storage → Kibana UI

Key points:
- Multi-source log collection
- Normalized data format
- Index lifecycle management
- Real-time search capabilities

### 6. Metrics Collection
**Flow:** Metric Producers → Prometheus Scraper → Victoria Metrics → Grafana Dashboards

Key points:
- Prometheus-compatible scraping
- Time-series data compression
- Long-term retention
- Customizable visualization

---

## ✅ Quick Start Checklist

### To Access Dashboard
- [ ] Open `INFRASTRUCTURE_DASHBOARD.html` in web browser
- [ ] Review Overview tab (5 minutes)
- [ ] Explore Architecture tab (10 minutes)
- [ ] Check specific workflows in Data Workflows tab

### To Deploy Infrastructure
- [ ] Read DASHBOARD_GUIDE.md
- [ ] Review Deployment Pipeline tab
- [ ] Follow VALIDATION_CHECKLIST.md from ansible folder
- [ ] Execute ansible playbooks in order
- [ ] Verify with validation commands

### To Monitor & Maintain
- [ ] Access Kibana at ES_IP:5601
- [ ] Access Grafana for metrics
- [ ] Monitor Services Matrix for dependencies
- [ ] Use troubleshooting guide for issues

---

## 🎯 Key Metrics & Thresholds

### CPU & Memory
- **Alert:** CPU > 80% for 5 minutes
- **Alert:** Memory > 90% available
- **Critical:** Memory > 95%

### Kafka
- **Alert:** Consumer lag > 10,000 messages
- **Alert:** Replication lag detected (ISR < replicas)
- **Critical:** Leader unavailable

### Elasticsearch
- **Alert:** Cluster health = yellow
- **Critical:** Cluster health = red
- **Alert:** Disk usage > 85%
- **Critical:** Disk usage > 90%

### Jenkins
- **Alert:** Build queue > 50 jobs
- **Alert:** Build failure rate > 10%
- **Info:** Long build duration trend

### Victoria Metrics
- **Alert:** Storage usage > 85%
- **Alert:** Ingestion lag > 1 minute
- **Info:** Metrics churn rate trending

---

## 📁 File Structure

```
Automation-Script/
├── 📊 INFRASTRUCTURE_DASHBOARD.html      [NEW] Interactive visual dashboard
├── 📖 DATA_WORKFLOW_DOCUMENTATION.md     [NEW] Complete technical docs
├── 📋 DASHBOARD_GUIDE.md                 [NEW] Quick start guide
├── 📑 Dashboard-Index.md                 [NEW] This file
│
├── ansible/
│   ├── README.md
│   ├── QUICK_REFERENCE.md
│   ├── DEPLOYMENT_SUMMARY.md
│   ├── VALIDATION_CHECKLIST.md
│   ├── TOKEN_CLUSTER_ID_FLOW.md
│   ├── MONITORING_DEBUG.md
│   ├── ansible.cfg
│   ├── quickstart.sh
│   ├── inventory/
│   │   └── hosts.yml
│   └── playbooks/
│       ├── site.yml
│       ├── kubernetes.yml
│       ├── kafka.yml
│       └── jenkins_maven.yml
│
├── Jenkins/
│   ├── jenkins_installer.sh
│   ├── jenkins_installer.py
│   ├── jenkins_installer_enhanced.sh
│   ├── jenkins_installer_multiplatform.py
│   ├── Maven.sh
│   ├── Uninstall_jenkins.sh
│   └── README.md
│
├── Kubernetes/
│   ├── k8s_install.sh
│   ├── k8s.sh
│   ├── reset_k8s.sh
│   └── README.md
│
├── Kafka/
│   ├── Kafka_setup.sh
│   ├── Uninstall_kafka.sh
│   └── README.md
│
├── Kafka-OL9/
│   ├── kafka_install_ol9.sh
│   └── README.md
│
├── Elasticsearch/
│   ├── elasticsearch_master_install.sh
│   ├── elasticsearch_node_install.sh
│   ├── logstash_install.sh
│   ├── kibana_install.sh
│   └── README.md
│
└── Monitoring/
    ├── victoria_metrics_single_node.sh
    ├── victoria_multinode.sh
    └── README.md
```

---

## 🚀 Common Tasks

### View Dashboard
```
1. Open file: INFRASTRUCTURE_DASHBOARD.html in browser
2. Use tabs to navigate different views
3. Print page for documentation
```

### Verify Deployment
```bash
# Kubernetes
kubectl get nodes

# Kafka cluster ID
ansible kafka -i ansible/inventory/hosts.yml -m command -a "cat /opt/kafka/cluster.id"

# Jenkins
curl http://203.0.113.42:8080/api/json

# Elasticsearch
curl http://ES_IP:9200/_cluster/health

# Victoria Metrics
curl http://VM_IP:61990/health
```

### Deploy Infrastructure
```bash
cd ansible
ansible-playbook playbooks/site.yml -i inventory/hosts.yml -v
```

### Monitor Data Flow
```bash
# Produce test message
kafka-console-producer --bootstrap-server 203.0.113.70:9092 --topic test

# Consume from Kafka
kafka-console-consumer --bootstrap-server 203.0.113.70:9092 --topic test

# Search logs in Kibana
# Visit: http://KIBANA_IP:5601
# Index: logs-*
# Query: message:"test"
```

---

## 📈 Performance Optimization Tips

### Kubernetes
- Monitor node CPU/memory
- Use resource requests/limits on pods
- Implement HPA for auto-scaling

### Kafka
- Monitor consumer lag
- Tune number of partitions per topic
- Adjust replication factor based on durability needs

### Elasticsearch
- Monitor shard allocation
- Use index lifecycle policies
- Optimize search queries with filters before aggregations

### Victoria Metrics
- Configure appropriate scrape intervals
- Set retention policy based on storage
- Use recording rules for complex queries

---

## 🔐 Security Considerations

### Networking
- Restrict SSH access to control plane IPs
- Use security groups/firewalls
- Consider TLS for inter-node communication

### Authentication
- SSH key-based (no passwords)
- Kibana authentication enabled
- Jenkins credentials management

### Data Protection
- Elasticsearch encryption at rest
- Log anonymization for PII
- Kafka ACLs for topic access control

---

## 📞 Support & Troubleshooting

### Issue: Nodes not joining Kubernetes
**Solution:** Check TOKEN_CLUSTER_ID_FLOW.md → Kubernetes section

### Issue: Kafka cluster ID mismatch
**Solution:** Check TOKEN_CLUSTER_ID_FLOW.md → Kafka section

### Issue: Logs not appearing in Elasticsearch
**Solution:** Check MONITORING_DEBUG.md → Logstash section

### Issue: Victoria Metrics not scraping metrics
**Solution:** Check prometheus configuration, firewall rules

### For More Help
- Review MONITORING_DEBUG.md
- Check VALIDATION_CHECKLIST.md
- Read component-specific READMEs

---

## 📅 Maintenance Schedule

### Daily
- Monitor Kibana dashboards
- Check Grafana alerts
- Verify log ingestion

### Weekly
- Review cluster health (ES, Kafka)
- Check disk usage trends
- Validate backup procedures

### Monthly
- Capacity planning analysis
- Performance optimization review
- Security audit
- Documentation updates

---

## 📝 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-05-10 | Initial dashboard & documentation created |

---

## 🎓 Learning Resources

### For Beginners
1. Start with Overview tab
2. Read DASHBOARD_GUIDE.md
3. Watch architecture video tutorials (external)

### For Intermediate
1. Study Data Workflows tab
2. Review network topology
3. Practice deployment checklist

### For Advanced
1. Deep dive into component documentation
2. Optimize data flows for your use case
3. Customize monitoring rules

---

## ✨ What's New

✅ **Interactive HTML Dashboard** - Visual overview with 7 tabs  
✅ **Complete Workflow Documentation** - 6 detailed data flows  
✅ **Network Topology Diagram** - IP schema & connectivity  
✅ **Deployment Pipeline** - Step-by-step with validation  
✅ **Services Integration Matrix** - Dependency visualization  
✅ **Quick Reference Guide** - Common commands & tasks  
✅ **Component Details** - Technical specifications  
✅ **Monitoring Guide** - Metrics & alerting  

---

**Dashboard Created:** May 10, 2026  
**Last Updated:** 2026-05-10 13:45 UTC  
**Status:** ✅ Production Ready  
**Support:** Refer to individual documentation files

---

### 🎯 Next Steps

1. **View Dashboard:** Open `INFRASTRUCTURE_DASHBOARD.html` in browser
2. **Read Guide:** Start with `DASHBOARD_GUIDE.md`
3. **Deploy:** Follow `ansible/DEPLOYMENT_SUMMARY.md`
4. **Monitor:** Access Kibana & Grafana URLs
5. **Maintain:** Use `VALIDATION_CHECKLIST.md`

---

For detailed information on specific workflows or components, refer to the appropriate documentation file listed in this index.

Happy automating! 🚀
