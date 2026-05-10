# 📊 Dashboard Access & Quick Start Guide

## 🎯 Accessing the Dashboard

### Interactive HTML Dashboard
**File:** `INFRASTRUCTURE_DASHBOARD.html`

#### How to Open
1. **Option A - Using Browser**
   - Double-click: `c:\Users\sbm26\Automation-Script\INFRASTRUCTURE_DASHBOARD.html`
   - Opens in default web browser automatically

2. **Option B - From VS Code**
   - Right-click on file → "Open with Live Server" (if Live Server extension installed)
   - Or: Open in browser → File → Open

3. **Option C - Local Server**
   ```powershell
   # Using Python (Windows)
   python -m http.server 8000
   
   # Then visit: http://localhost:8000/INFRASTRUCTURE_DASHBOARD.html
   ```

#### Features
- ✅ **7 Interactive Tabs**: Overview, Architecture, Workflows, Components, Topology, Services, Deployment
- ✅ **Responsive Design**: Works on desktop, tablet, mobile
- ✅ **Interactive Diagrams**: Mermaid.js flowcharts and diagrams
- ✅ **SVG Architecture Diagram**: Detailed infrastructure layout
- ✅ **Data Tables**: IP addresses, services, integration matrix
- ✅ **No Server Required**: Pure HTML/CSS/JavaScript

---

## 📖 Documentation Files

### 1. DATA_WORKFLOW_DOCUMENTATION.md
**Location:** `c:\Users\sbm26\Automation-Script\DATA_WORKFLOW_DOCUMENTATION.md`

**Contents:**
- Executive summary of infrastructure
- Complete data workflows (6 workflows detailed)
- Network topology and IP schema
- Component specifications
- Deployment pipeline with validation
- Integration patterns
- Monitoring & observability setup

**Best for:**
- Understanding data flows
- Reference material
- Pre-deployment planning
- Troubleshooting guide

### 2. INFRASTRUCTURE_DASHBOARD.html
**Location:** `c:\Users\sbm26\Automation-Script\INFRASTRUCTURE_DASHBOARD.html`

**Best for:**
- Visual learning
- Quick reference
- Sharing with stakeholders
- Real-time monitoring access

---

## 🗺️ Dashboard Navigation Guide

### Tab 1: Overview
**What's here:**
- All 6 major components (cards)
- Quick statistics
- Key features list

**Use when:** You need quick overview of entire infrastructure

---

### Tab 2: Architecture
**What's here:**
- System architecture diagram (SVG)
- Component relationships (Mermaid graph)
- Data flow paths
- Orchestration connections

**Use when:** Understanding how components connect together

---

### Tab 3: Data Workflows
**What's here:**
- 6 complete workflows:
  1. Kubernetes cluster setup
  2. Kafka cluster ID distribution
  3. Event streaming pipeline
  4. CI/CD build pipeline
  5. Unified logging
  6. Metrics collection

**Use when:** Tracing data from source to destination

**Each workflow includes:**
- Purpose & objective
- Step-by-step flow
- Data elements in transit
- Error handling/verification

---

### Tab 4: Components
**What's here:**
- Kubernetes cluster details (3 nodes)
- Kafka KRaft cluster (3 nodes)
- Jenkins CI/CD setup
- ELK Stack (3 components)
- Monitoring Stack (2 components)

**Use when:** Need component-specific details

---

### Tab 5: Network Topology
**What's here:**
- Network diagram (Mermaid graph)
- IP address schema table
- Communication patterns
- Port mappings
- Protocol information

**Use when:** Planning network access or troubleshooting connectivity

---

### Tab 6: Services Matrix
**What's here:**
- Integration matrix table
- What each service provides/consumes
- Data types exchanged
- Frequency of communication

**Use when:** Understanding service dependencies

---

### Tab 7: Deployment Pipeline
**What's here:**
- Sequential deployment flowchart
- Installation order (7 steps)
- Key features per component
- Validation checklist
- Verification commands

**Use when:** Planning or executing deployment

---

## 🚀 Quick Reference Commands

### Verify Infrastructure Health

```bash
# Kubernetes
kubectl get nodes                   # Should show 3 nodes (1 control, 2 workers)
kubectl cluster-info                # API server accessible
kubectl get pods -A                 # All system pods running

# Kafka
ansible kafka -i ansible/inventory/hosts.yml -m command -a "cat /opt/kafka/cluster.id"
# Should show same UUID on all 3 nodes

# Jenkins
curl http://203.0.113.42:8080/api/json
# HTTP 200 response

# Elasticsearch
curl http://ES_IP:9200/_cluster/health
# Should show: "status": "green", "number_of_nodes": 3

# Kibana
curl http://KIBANA_IP:5601/api/status
# HTTP 200 response

# Victoria Metrics
curl http://VM_IP:61990/health
# HTTP 200 response
```

---

## 📋 Deployment Checklist

### Pre-Deployment
- [ ] Review infrastructure requirements in Overview tab
- [ ] Check network topology for IP conflicts
- [ ] Verify SSH connectivity to all target hosts
- [ ] Confirm Ansible inventory is updated

### Deployment
- [ ] Start with Kubernetes (Tab 7, Step 1)
- [ ] Follow sequential order as shown in Deployment tab
- [ ] Monitor each step with validation commands
- [ ] Check logs if any step fails

### Post-Deployment
- [ ] Run all verification commands in Deployment tab
- [ ] Access Kibana and create index patterns
- [ ] Set up Grafana dashboards
- [ ] Configure alerting rules
- [ ] Test end-to-end data flow

---

## 🔍 Troubleshooting Guide

### Issue: Can't open dashboard in browser
**Solution:**
1. Check file exists: `INFRASTRUCTURE_DASHBOARD.html`
2. Try different browser (Chrome, Firefox, Edge)
3. Check browser console (F12) for JavaScript errors
4. Use local server method (Python http.server)

### Issue: Mermaid diagrams not rendering
**Solution:**
1. Check internet connection (CDN needed)
2. Try refreshing page (Ctrl+F5)
3. Check browser console for CDN errors
4. Ensure JavaScript enabled

### Issue: Data workflow not clear
**Solution:**
1. Read corresponding section in DATA_WORKFLOW_DOCUMENTATION.md
2. Check Tab 3: Data Workflows for detailed flow
3. Compare with network topology (Tab 5)
4. Review component details (Tab 4)

---

## 📊 Key Data Points

### Kubernetes
- **Version:** 1.35.1
- **Nodes:** 3 (1 control, 2 workers)
- **Pod Network:** 10.244.0.0/16
- **Service Network:** 10.96.0.0/12

### Kafka
- **Version:** 4.0.0
- **Nodes:** 3 (KRaft mode, no Zookeeper)
- **Quorum:** 1@203.0.113.70:9093, 2@203.0.113.71:9093, 3@203.0.113.72:9093
- **Cluster ID:** Auto-generated UUID

### Jenkins
- **Version:** 2.440.3
- **URL:** http://203.0.113.42:8080
- **Maven:** 3.9.9

### Elasticsearch
- **Version:** 9.1.2
- **Nodes:** 3 (1 master, 2 data)
- **Indices:** logs-* (rollover daily)

### Victoria Metrics
- **Port:** 61990
- **Retention:** 12 months (default)
- **Data Dir:** /apps/victoria-metrics/storage

---

## 🎓 Learning Paths

### For DevOps Engineers
1. Start: Tab 1 (Overview)
2. Then: Tab 2 (Architecture)
3. Deep dive: Tab 3 (Workflows)
4. Implement: Tab 7 (Deployment)

### For System Administrators
1. Start: Tab 5 (Network Topology)
2. Review: Tab 4 (Components)
3. Monitor: Tab 6 (Services Matrix)
4. Reference: Tab 7 (Deployment Pipeline)

### For Developers
1. Focus: Tab 3 (Workflows) - Application → Kafka
2. Reference: Tab 4 (Components) - Jenkins section
3. Deploy: Tab 7 (Deployment) - CI/CD section

### For Security/Compliance
1. Review: Tab 5 (Network Topology) - Security groups
2. Audit: Tab 6 (Services Matrix) - Data flows
3. Check: DATA_WORKFLOW_DOCUMENTATION.md - Full details

---

## 📈 Metrics Dashboard Access

### After deployment, access monitoring UIs:

```
Kibana Dashboard:
  URL: http://<ES_MASTER_IP>:5601
  Use for: Log searching, visualization, analysis

Grafana Dashboard:
  URL: http://<GRAFANA_IP>:3000
  Use for: Metrics visualization, alerting, trending

Victoria Metrics:
  URL: http://<VM_IP>:61990
  Use for: Direct metric query API

Jenkins:
  URL: http://203.0.113.42:8080
  Use for: Build pipeline management
```

---

## 📞 Support References

### Documentation Files in Project
- `README.md` - Setup guide
- `QUICK_REFERENCE.md` - Common commands
- `VALIDATION_CHECKLIST.md` - Pre/post deployment checks
- `TOKEN_CLUSTER_ID_FLOW.md` - Token/ID flow details
- `MONITORING_DEBUG.md` - Troubleshooting guide

### External Resources
- Kubernetes: https://kubernetes.io/docs/
- Kafka: https://kafka.apache.org/
- Elasticsearch: https://www.elastic.co/guide/
- Ansible: https://docs.ansible.com/
- Victoria Metrics: https://victoriametrics.com/

---

## ✨ Dashboard Features Highlight

✅ **Interactive Tabs** - 7 tabs covering all aspects  
✅ **Visual Diagrams** - SVG and Mermaid diagrams  
✅ **Data Tables** - IP schemes, services, integration matrix  
✅ **Workflow Details** - 6 complete workflows documented  
✅ **Responsive Design** - Works on all devices  
✅ **No Dependencies** - Pure HTML, opens in any browser  
✅ **Self-Contained** - All resources included  
✅ **Professional Styling** - Gradient backgrounds, card layouts  
✅ **Print-Friendly** - Can print for documentation  
✅ **Accessible** - WCAG compliance considerations  

---

**Last Updated:** May 10, 2026  
**Dashboard Version:** 1.0  
**Status:** ✅ Production Ready

For questions or updates, refer to the main documentation files in the automation-script directory.
