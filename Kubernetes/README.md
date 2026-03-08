# Kubernetes Installation Scripts

This folder contains scripts for automating the installation, configuration, and reset of Kubernetes clusters using kubeadm, containerd, and Flannel CNI.

## Files

- `k8s_install.sh`: A bash script that installs Kubernetes components (kubelet, kubeadm, kubectl), containerd runtime, and configures networking. It supports three modes: initializing a control plane (`cp-init`), joining additional control planes (`cp-join`), and adding worker nodes (`worker`).

- `reset_k8s.sh`: A bash script to reset a Kubernetes node, removing all cluster configurations, containers, and related files. Use with caution as it performs a full cleanup.

## Usage

### k8s_install.sh
Run the script as root with one of the following arguments:

- `cp-init`: Initialize the first control plane node.
- `cp-join`: Join an additional control plane node.
- `worker`: Join a worker node.

#### Detailed Steps for k8s_install.sh

1. **Prepare the Node**:
   - Ensure the node has root access and internet connectivity.
   - Edit the script variables (e.g., `CONTROL_PLANE_IP`, `K8S_VERSION`) if needed.
   - If behind a proxy, set `USE_PROXY="true"` and update proxy URLs.

2. **Run the Script**:
   - For the first control plane: `sudo ./k8s_install.sh cp-init`
     - This installs containerd, Kubernetes RPMs, configures kernel modules, disables swap, and initializes the cluster with Flannel CNI.
     - Outputs join commands for additional nodes.
   - For additional control planes: `sudo ./k8s_install.sh cp-join`
     - Installs components and prepares for joining.
     - Run the provided join command from the first master.
   - For workers: `sudo ./k8s_install.sh worker`
     - Installs components and prepares for joining.
     - Run the worker join command from the master.

3. **Post-Installation**:
   - For workers, on the master, approve CSRs: `kubectl get csr -o json | jq -r '.items[] | select(.status.conditions == null) | .metadata.name' | xargs -r kubectl certificate approve`
   - Verify cluster: `kubectl get nodes`

### reset_k8s.sh
Run as root to reset the node:

```bash
sudo ./reset_k8s.sh
```

#### Detailed Steps for reset_k8s.sh

1. **Backup Data**: If needed, back up any important data before resetting.
2. **Run the Script**: Execute `sudo ./reset_k8s.sh` to stop services, remove Kubernetes configurations, clean up directories, and uninstall packages.
3. **Reboot**: Optionally reboot the node after reset.

## Prerequisites

- Root privileges.
- Internet access for downloading binaries (for install script).
- OS: RHEL/CentOS-based (uses yum).
- Proxy configuration if behind a proxy (edit `USE_PROXY` and related variables in `k8s_install.sh`).

## Configuration

For `k8s_install.sh`, customize variables at the top:

- `CONTROL_PLANE_IP`: IP of the first master.
- `K8S_VERSION`: Kubernetes version (e.g., 1.35.1).
- `POD_CIDR`: Pod network CIDR (default: 10.244.0.0/16 for Flannel).
- Proxy settings if applicable.

## Notes

- `k8s_install.sh` disables swap permanently and configures kernel modules.
- Firewall rules are optional (set `CONFIGURE_FIREWALLD=true` in `k8s_install.sh`).
- Tested with Kubernetes v1.35.1, containerd 1.7.18, etc.
- `reset_k8s.sh` is destructive; back up data if needed.