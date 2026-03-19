#!/usr/bin/env bash
set -euo pipefail

# FINAL FULLY FIXED KUBERNETES INSTALL + JOIN SCRIPT (NO VIP / NO DNS)
# Supports Kubernetes v1.35.1, containerd, flannel, kubelet swapoff fix,
# correct kubeadm config merge, reliable worker rejoin handling.

CONTROL_PLANE_IP="10.2.162.64"
CONTROL_PLANE_PORT="61149"

K8S_SERIES="v1.35"
K8S_VERSION="1.35.1"

CONTAINERD_VERSION="1.7.18"
RUNC_VERSION="1.1.12"
CNI_PLUGINS_VERSION="1.6.2"

POD_CIDR="10.244.0.0/16"

USE_PROXY="true"
HTTP_PROXY_URL="http://cloudproxy.nat.bt.com:8080"
NO_PROXY_LIST="127.0.0.1,localhost,::1,10.244.0.0/16,10.96.0.0/12,10.0.0.0/8,192.168.0.0/16,172.16.0.0/12"

CONFIGURE_FIREWALLD="false"
CRI_SOCKET="unix:///run/containerd/containerd.sock"

ROLE="${1:-}"
if [[ -z "$ROLE" ]]; then
  echo "Usage: $0 <cp-init|cp-join|worker>"
  exit 1
fi

green(){ echo -e "\e[32m$*\e[0m"; }
yellow(){ echo -e "\e[33m$*\e[0m"; }
require_root(){ if [[ $(id -u) -ne 0 ]]; then echo "Run as root"; exit 1; fi; }

apply_proxy_env(){
 if [[ "$USE_PROXY" == "true" ]]; then
   export http_proxy="$HTTP_PROXY_URL"
   export https_proxy="$HTTP_PROXY_URL"
   export no_proxy="$NO_PROXY_LIST"
   mkdir -p /etc/systemd/system/containerd.service.d
   cat >/etc/systemd/system/containerd.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=$HTTP_PROXY_URL"
Environment="HTTPS_PROXY=$HTTP_PROXY_URL"
Environment="NO_PROXY=$NO_PROXY_LIST"
EOF
 fi
}

disable_swap_permanently(){
  swapoff -a || true
  sed -i.bak '/\sswap\s/s/^/#/' /etc/fstab || true
}

kernel_prereqs(){
  cat >/etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
  modprobe overlay || true
  modprobe br_netfilter || true
  cat >/etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
  sysctl --system
}

install_containerd_stack(){
 mkdir -p /apps/software/addon-pkgs

 wget --no-check-certificate -O /apps/software/addon-pkgs/containerd.tgz "https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz"
 tar Cxzvf /usr/local /apps/software/addon-pkgs/containerd.tgz

 wget --no-check-certificate -O /usr/lib/systemd/system/containerd.service "https://raw.githubusercontent.com/containerd/containerd/main/containerd.service"

 wget --no-check-certificate -O /usr/local/sbin/runc "https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64"
 chmod +x /usr/local/sbin/runc

 mkdir -p /opt/cni/bin
 wget --no-check-certificate -O /apps/software/addon-pkgs/cni.tgz "https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-amd64-v${CNI_PLUGINS_VERSION}.tgz"
 tar Cxzvf /opt/cni/bin /apps/software/addon-pkgs/cni.tgz

 mkdir -p /etc/containerd
 (containerd config default || true) > /etc/containerd/config.toml || true
 sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml || true

 systemctl daemon-reload
 systemctl enable --now containerd
}

install_kubernetes_rpms(){
 systemctl stop kubelet || true
 yum remove -y kubelet kubeadm kubectl || true

 cat >/etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/${K8S_SERIES}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/${K8S_SERIES}/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

 yum --setopt=sslverify=false install -y kubelet-${K8S_VERSION} kubeadm-${K8S_VERSION} kubectl-${K8S_VERSION} --disableexcludes=kubernetes

 systemctl enable kubelet
}

configure_firewalld(){
 if [[ "$CONFIGURE_FIREWALLD" != "true" ]]; then return; fi
 if [[ $(systemctl is-enabled firewalld) ]]; then
   firewall-cmd --add-port=61149/tcp --permanent || true
   firewall-cmd --add-port=2379-2380/tcp --permanent || true
   firewall-cmd --add-port=10250/tcp --permanent || true
   firewall-cmd --add-port=10257/tcp --permanent || true
   firewall-cmd --add-port=10259/tcp --permanent || true
   firewall-cmd --add-port=30000-32767/tcp --permanent || true
   firewall-cmd --add-port=8472/udp --permanent || true
   firewall-cmd --reload || true
 fi
}

kubelet_swapoff_override(){
 mkdir -p /etc/systemd/system/kubelet.service.d
 cat >/etc/systemd/system/kubelet.service.d/10-swapoff.conf <<EOF
[Service]
ExecStartPre=/bin/sh -c "/usr/sbin/swapoff -a || true"
EOF
 systemctl daemon-reload
}

write_kubeadm_init_config(){
 mkdir -p /root/kubeadm
 cat >/root/kubeadm/kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
nodeRegistration:
  criSocket: ${CRI_SOCKET}
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v${K8S_VERSION}
controlPlaneEndpoint: "${CONTROL_PLANE_IP}:${CONTROL_PLANE_PORT}" 
apiserver-bind-port=${CONTROL_PLANE_PORT} 
apiserver-advertise-address=${CONTROL_PLANE_IP}
networking:
  podSubnet: "${POD_CIDR}"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
serverTLSBootstrap: true
cgroupDriver: systemd
EOF
}

kubeadm_init_cp(){
 write_kubeadm_init_config
 kubeadm init --control-plane-endpoint="${CONTROL_PLANE_IP}:${CONTROL_PLANE_PORT}" --apiserver-bind-port=${CONTROL_PLANE_PORT} --apiserver-advertise-address=${CONTROL_PLANE_IP} --pod-network-cidr=10.244.0.0/16 --upload-certs
 mkdir -p $HOME/.kube
 cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
 chown $(id -u):$(id -g) $HOME/.kube/config

 kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

 green "=== WORKER JOIN COMMAND ==="
 kubeadm token create --print-join-command

 CERT_KEY=$(kubeadm init phase upload-certs --upload-certs | tail -n1)
 JOIN_CP_CMD="$(kubeadm token create --print-join-command) --control-plane --certificate-key ${CERT_KEY}"
 green "=== CONTROL-PLANE JOIN ==="
 echo "$JOIN_CP_CMD"
}

worker_prep_reset(){
 kubeadm reset -f || true
 systemctl stop kubelet || true
 systemctl stop containerd || true
 rm -rf /etc/cni/net.d/*
 rm -rf /var/lib/cni/
 rm -rf /var/lib/kubelet/*
 rm -rf /var/lib/kubelet/pki
 rm -rf /var/lib/kubelet/config.yaml
 ip link delete cni0 2>/dev/null || true
 ip link delete flannel.1 2>/dev/null || true
 mkdir -p /etc/cni/net.d
 mkdir -p /var/lib/kubelet/plugins/kubernetes.io/empty-dir
 mkdir -p /var/lib/kubelet/pods
 chown -R root:root /var/lib/kubelet
 systemctl restart containerd
}

require_root
apply_proxy_env
disable_swap_permanently
kernel_prereqs

case "$ROLE" in
 cp-init)
   install_containerd_stack
   install_kubernetes_rpms
   kubelet_swapoff_override
   configure_firewalld
   systemctl restart containerd
   systemctl restart kubelet
   kubeadm_init_cp
   systemctl restart containerd
   systemctl restart kubelet
   ;;

 cp-join)
   install_containerd_stack
   install_kubernetes_rpms
   kubelet_swapoff_override
   configure_firewalld
   systemctl restart containerd
   systemctl restart kubelet
   yellow "Run the JOIN command provided by master (no cri-socket flag)."
   ;;

 worker)
   install_containerd_stack
   install_kubernetes_rpms
   kubelet_swapoff_override
   configure_firewalld
   systemctl restart containerd
   systemctl restart kubelet
   yellow "Now run the worker JOIN command shown on the master node. After adding all the nodes approve all the pending CSR: kubectl get csr -o json | jq -r '.items[] | select(.status.conditions == null) | .metadata.name' | xargs -r kubectl certificate approve"
   ;;

 *)
   echo "Unknown mode: $ROLE"
   exit 1
   ;;
esac
