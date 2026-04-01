#!/bin/bash
# Quick Start Script for Ansible Automation
# Usage: source quickstart.sh or bash quickstart.sh

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Ansible Infrastructure Automation - Quick Start         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ANSIBLE_DIR="$SCRIPT_DIR"

echo -e "${BLUE}1. Checking prerequisites...${NC}"
echo ""

# Check Ansible installation
if command -v ansible &> /dev/null; then
    echo -e "${GREEN}✓${NC} Ansible is installed"
    ansible --version | head -n 1
else
    echo -e "${YELLOW}✗${NC} Ansible is not installed"
    echo "Install with: pip install ansible"
    exit 1
fi

echo ""

# Check SSH key
if [ -f ~/.ssh/id_rsa ]; then
    echo -e "${GREEN}✓${NC} SSH key found at ~/.ssh/id_rsa"
else
    echo -e "${YELLOW}⚠${NC} SSH private key not found"
    echo "Generate with: ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa"
fi

echo ""
echo -e "${BLUE}2. Checking inventory...${NC}"
echo ""

INVENTORY="$ANSIBLE_DIR/inventory/hosts.yml"
if [ -f "$INVENTORY" ]; then
    echo -e "${GREEN}✓${NC} Inventory file found"
    HOSTS_COUNT=$(grep -c "ansible_host:" "$INVENTORY" || echo "0")
    echo "  Found $HOSTS_COUNT hosts in inventory"
else
    echo -e "${YELLOW}✗${NC} Inventory file not found: $INVENTORY"
    exit 1
fi

echo -e "${BLUE}3. Key Features...${NC}"
echo ""

cat << 'EOF'
✓ Dynamic Token/Cluster ID Handling:
  - Kubernetes: Auto-generates and distributes join tokens
  - Kafka: Auto-generates and distributes cluster IDs
  - No manual token copying required!

✓ Serial Deployment:
  - Control planes/leaders deploy first
  - Workers/followers join automatically
  - Proper sequencing ensures cluster formation

✓ Production Ready:
  - Error handling and retries
  - Service health checks
  - Comprehensive logging
EOF

echo ""
echo -e "${BLUE}4. Available deployment options...${NC}"

echo ""
echo -e "${BLUE}4. Available deployment options...${NC}"
echo ""

cat << 'EOF'
┌─ FULL DEPLOYMENT ─────────────────────────────────────┐
│ Deploy all components (K8s + Kafka + Jenkins):        │
│ $ ansible-playbook playbooks/site.yml                 │
└───────────────────────────────────────────────────────┘

┌─ INDIVIDUAL COMPONENTS ───────────────────────────────┐
│ Kubernetes cluster:                                    │
│ $ ansible-playbook playbooks/kubernetes.yml           │
│                                                        │
│ Kafka KRaft cluster:                                   │
│ $ ansible-playbook playbooks/kafka.yml                │
│                                                        │
│ Jenkins & Maven:                                       │
│ $ ansible-playbook playbooks/jenkins_maven.yml        │
└───────────────────────────────────────────────────────┘

┌─ ADVANCED OPTIONS ────────────────────────────────────┐
│ Verbose output (debug):                                │
│ $ ansible-playbook playbooks/site.yml -vvv            │
│                                                        │
│ Specific host group:                                   │
│ $ ansible-playbook playbooks/site.yml -l kubernetes   │
│                                                        │
│ Override variables:                                    │
│ $ ansible-playbook playbooks/site.yml \               │
│   -e "k8s_version=1.35.1" \                            │
│   -e "jenkins_version=2.440.3"                         │
│                                                        │
│ Check mode (dry-run):                                  │
│ $ ansible-playbook playbooks/site.yml --check         │
│                                                        │
│ List hosts:                                            │
│ $ ansible-inventory -i inventory/hosts.yml --list     │
│                                                        │
│ Syntax check:                                          │
│ $ ansible-playbook playbooks/site.yml --syntax-check  │
└───────────────────────────────────────────────────────┘

EOF

echo -e "${BLUE}5. Pre-deployment checklist...${NC}"
echo ""

cat << 'EOF'
Before running deployment:

[ ] Update inventory/hosts.yml with correct IP addresses
[ ] Update ansible_ssh_user and connection details
[ ] Verify SSH key access works: ssh -i ~/.ssh/id_rsa root@<target>
[ ] Ensure target hosts have internet connectivity
[ ] Check target hosts meet minimum resource requirements:
    - Kubernetes: 4GB RAM, 2 CPU cores
    - Kafka: 8GB RAM, 4 CPU cores  
    - Jenkins: 4GB RAM, 2 CPU cores
[ ] Review and update proxy settings if behind corporate proxy
[ ] Backup existing configurations on target hosts (if any)
[ ] Plan for any firewall rules needed post-deployment

EOF

echo -e "${BLUE}6. Recommended next steps...${NC}"
echo ""

cat << 'EOF'
1. Update inventory configuration:
   $ vi inventory/hosts.yml

2. Run connectivity test:
   $ ansible all -i inventory/hosts.yml -m ping

3. Run syntax check:
   $ ansible-playbook playbooks/site.yml --syntax-check

4. Do a dry-run (check mode):
   $ ansible-playbook playbooks/site.yml --check

5. Deploy with verbose output:
   $ ansible-playbook playbooks/site.yml -v

6. Monitor deployment progress:
   $ tail -f /var/log/ansible.log

EOF

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "For full documentation, see README.md"
echo "═══════════════════════════════════════════════════════════"
echo ""
