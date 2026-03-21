#!/usr/bin/env bash
# install_vmcluster.sh
# Installs VictoriaMetrics *cluster* via Docker/Podman + systemd on this host.

set -euo pipefail

# -------- Defaults (override with flags) --------------------------------------
IP_LIST=( "10.6.106.176" "10.55.1.85" "10.13.1.120" )
VM_TAG="latest"                 # use "latest" or a specific tag
DATA_DIR="/iona/victoria-metrics/storage"
RETENTION="12"                     # months
ENGINE=""                          # docker|podman (auto-detect if empty)
# -----------------------------------------------------------------------------

# Parse CLI flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ips)        shift; read -r -a IP_LIST <<< "$1" ;;
    --tag)        shift; VM_TAG="$1" ;;
    --data-dir)   shift; DATA_DIR="$1" ;;
    --retention)  shift; RETENTION="$1" ;;
    --engine)     shift; ENGINE="$1" ;;
    -h|--help)
      echo "Usage: $0 [--ips \"ipA ipB ipC\"] [--tag vX.Y.Z|latest] [--data-dir PATH] [--retention MONTHS] [--engine docker|podman]"
      exit 0;;
    *) echo "[ERROR] Unknown arg: $1" >&2; exit 1;;
  esac
  shift || true
done

# Validate IPs
if [[ ${#IP_LIST[@]} -ne 3 ]]; then
  echo "[ERROR] --ips must provide exactly 3 IPs" >&2
  exit 1
fi

# Require root
if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] Please run as root (sudo)." >&2
  exit 1
fi

export http_proxy=http://cloudproxy.nat.bt.com:8080 && export https_proxy=http://cloudproxy.nat.bt.com:8080 && export no_proxy=$(hostname -i)

# Detect container runtime (or honor --engine)
RUNTIME_BIN=""
if [[ -n "$ENGINE" ]]; then
  command -v "$ENGINE" >/dev/null 2>&1 || { echo "[ERROR] Engine '$ENGINE' not found"; exit 1; }
  RUNTIME_BIN="$(command -v "$ENGINE")"
else
  if   command -v docker >/dev/null 2>&1; then RUNTIME_BIN="$(command -v docker)"
  elif command -v podman >/dev/null 2>&1; then RUNTIME_BIN="$(command -v podman)"
  else
    echo "[INFO] No Docker/Podman found. Installing podman..."
    if   command -v dnf >/dev/null 2>&1; then dnf install -y podman
    elif command -v yum >/dev/null 2>&1; then yum install -y podman
    else echo "[ERROR] Neither dnf nor yum found to install podman"; exit 1
    fi
    RUNTIME_BIN="$(command -v podman)"
  fi
fi
RUNTIME_NAME="$(basename "$RUNTIME_BIN")"

# SELinux volume label suffix for podman
VOLUME_SUFFIX=""
if [[ "$RUNTIME_NAME" == "podman" ]]; then
  VOLUME_SUFFIX=":Z"
fi

# Prepare data dir
mkdir -p "$DATA_DIR"
if [[ "$RUNTIME_NAME" == "podman" ]]; then
  chcon -t container_file_t "$DATA_DIR" 2>/dev/null || true
fi

# Images
IMG_STORAGE="docker.io/victoriametrics/vmstorage:${VM_TAG}"
IMG_INSERT="docker.io/victoriametrics/vminsert:${VM_TAG}"
IMG_SELECT="docker.io/victoriametrics/vmselect:${VM_TAG}"

# Pull images (fail fast if no internet)
"$RUNTIME_BIN" pull "$IMG_STORAGE"
"$RUNTIME_BIN" pull "$IMG_INSERT"
"$RUNTIME_BIN" pull "$IMG_SELECT"

# --- systemd units ------------------------------------------------------------
cat > /etc/systemd/system/vmstorage.service <<UNIT
[Unit]
Description=VictoriaMetrics vmstorage (cluster)
After=network-online.target
Wants=network-online.target

[Service]
Restart=always
RestartSec=5
ExecStart=${RUNTIME_BIN} run --rm \
  --name vmstorage \
  -p 61982:8482 \
  -p 61900:8400 \
  -p 61901:8401 \
  -v ${DATA_DIR}:/storage${VOLUME_SUFFIX} \
  ${IMG_STORAGE} \
    -storageDataPath=/storage \
    -vminsertAddr=:8400 \
    -vmselectAddr=:8401 \
    -retentionPeriod=${RETENTION}
ExecStop=${RUNTIME_BIN} stop vmstorage

[Install]
WantedBy=multi-user.target
UNIT

cat > /etc/systemd/system/vminsert.service <<UNIT
[Unit]
Description=VictoriaMetrics vminsert (cluster)
After=network-online.target vmstorage.service
Wants=network-online.target vmstorage.service

[Service]
Restart=always
RestartSec=5
ExecStart=${RUNTIME_BIN} run --rm \
  --name vminsert \
  -p 61980:8480 \
  ${IMG_INSERT} \
    -storageNode=${IP_LIST[0]}:61900 \
    -storageNode=${IP_LIST[1]}:61900 \
    -storageNode=${IP_LIST[2]}:61900
ExecStop=${RUNTIME_BIN} stop vminsert

[Install]
WantedBy=multi-user.target
UNIT

cat > /etc/systemd/system/vmselect.service <<UNIT
[Unit]
Description=VictoriaMetrics vmselect (cluster)
After=network-online.target vmstorage.service
Wants=network-online.target vmstorage.service

[Service]
Restart=always
RestartSec=5
ExecStart=${RUNTIME_BIN} run --rm \
  --name vmselect \
  -p 61981:8481 \
  ${IMG_SELECT} \
    -storageNode=${IP_LIST[0]}:61901 \
    -storageNode=${IP_LIST[1]}:61901 \
    -storageNode=${IP_LIST[2]}:61901
ExecStop=${RUNTIME_BIN} stop vmselect

[Install]
WantedBy=multi-user.target
UNIT

# Start services
systemctl daemon-reload
systemctl enable --now vmstorage
sleep 2
systemctl enable --now vminsert vmselect

# Health checks
echo "[INFO] Waiting for services to bind..."
for s in vmstorage vminsert vmselect; do
  for i in {1..40}; do
    case "$s" in
      vmstorage) url="http://127.0.0.1:61982/metrics" ;;
      vminsert)  url="http://127.0.0.1:61980/metrics" ;;
      vmselect)  url="http://127.0.0.1:61981/metrics" ;;
    esac
    if curl -fsS "$url" >/dev/null 2>&1; then
      echo "  - $s is up"
      break
    fi
    sleep 1
    [[ $i -eq 40 ]] && echo "[WARN] $s not responding on ${url#http://} yet" >&2
  done
done