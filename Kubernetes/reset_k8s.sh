#!/bin/bash
echo "Starting Reset"
kubeadm reset
systemctl stop kubelet
#systemctl stop docker
rm -rf /var/lib/cni/
rm -rf /var/lib/kubelet/*
rm -rf /etc/cni/
rm -rf /opt/cni/bin/*
rm -rf /usr/local/sbin/runc
ifconfig cni0 down
ifconfig flannel.1 down
#ifconfig docker0 down
ip link delete cni0
ip link delete flannel.1
#systemctl restart docker.service
systemctl daemon-reload
systemctl restart kubelet
yum remove -y kubelet kubeadm kubectl
rm -rf /etc/kubernetes
rm -rf /var/lib/etcd
rm -rf /var/lib/kubelet

echo "Reset completed"