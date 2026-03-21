#!/usr/bin/env bash
# Production‑ready VictoriaMetrics single-node setup script
# Updated to avoid IP binding issues discovered during debugging

set -euo pipefail

# ---------------- DEFAULT VALUES ----------------
VM_TAG="latest"
DATA_DIR="/apps/victoria-metrics/storage"
RETENTION="12"              # months
ENGINE=""                   # docker|podman
HTTP_PORT="61990"           # Host port exposed to Prometheus / Grafana
EXTRA_ARGS=""               # Optional VM extra config flags
# --------------------------------------------------

usage() {
cat <<USAGE
Usage: $0 [options]

Options:
  --tag <version>            VictoriaMetrics tag (default: latest)
  --data-dir <dir>           Storage directory (default: /apps/victoria-metrics/storage)
  --retention <months>       Retention period in months (default: 12)
  --http-port <port>         Host port exposed for VM HTTP API (default: 61990)
  --engine <docker|podman>   Force runtime (auto-detect if omitted)
  --extra-args "<args>"      Additional arguments for VictoriaMetrics
  -h, --help                 Show this help

Example:
  sudo bash $0 --http-port 61990 --data-dir /data/vm
USAGE
}

# ---------------- PARSE ARGUMENTS ----------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)        shift; VM_TAG="$1" ;;
    --data-dir)   shift; DATA_DIR="$1" ;;
    --retention)  shift; RETENTION="$1" ;;
    --http-port)  shift; HTTP_PORT="$1" ;;
    --engine)     shift; ENGINE="$1" ;;
    --extra-args) shift; EXTRA_ARGS="$1" ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "[ERROR] Unknown argument: $1"; usage; exit 1 ;;
  esac
  shift
done

# Validate port
if ! [[ "$HTTP_PORT" =~ ^[0-9]+$ ]] || ((HTTP_PORT < 1 || HTTP_PORT > 65535)); then
  echo "[ERROR] Invalid port: $HTTP_PORT"; exit 1
fi

# ---------------- RUNTIME DETECTION ----------------
if [[ -n "$ENGINE" ]]; then
  command -v "$ENGINE" >/dev/null || { echo "[ERROR] Runtime $ENGINE not found"; exit 1; }
  RUNTIME_BIN=$(command -v "$ENGINE")
else
  if command -v docker >/dev/null; then RUNTIME_BIN=$(command -v docker)
  elif command -v podman >/dev/null; then RUNTIME_BIN=$(command -v podman)
  else
    echo "[INFO] No runtime found; installing podman..."
    if command -v dnf >/dev/null; then sudo dnf install -y podman
    elif command -v yum >/dev/null; then sudo yum install -y podman
    fi
    RUNTIME_BIN=$(command -v podman)
  fi
fi

RUNTIME_NAME=$(basename "$RUNTIME_BIN")

# Podman SELinux label
VOLUME_SUFFIX=""
if [[ "$RUNTIME_NAME" == "podman" ]]; then
  VOLUME_SUFFIX=":Z"
fi

# ---------------- PREPARE STORAGE ----------------
sudo mkdir -p "$DATA_DIR"
if [[ "$RUNTIME_NAME" == "podman" ]]; then
  sudo chcon -t container_file_t "$DATA_DIR" || true
fi

# ---------------- PULL IMAGE ----------------
IMAGE="docker.io/victoriametrics/victoria-metrics:${VM_TAG}"
"$RUNTIME_BIN" pull "$IMAGE"

# ---------------- CREATE SYSTEMD UNIT ----------------
cat <<EOF | sudo tee /etc/systemd/system/victoria-metrics.service >/dev/null
[Unit]
Description=VictoriaMetrics Single Node
After=network-online.target
Wants=network-online.target

[Service]
Restart=always
RestartSec=5
ExecStart=${RUNTIME_BIN} run --rm \
  --name victoria-metrics \
  -p ${HTTP_PORT}:8428 \
  -v ${DATA_DIR}:/storage${VOLUME_SUFFIX} \
  ${IMAGE} \
    -storageDataPath=/storage \
    -retentionPeriod=${RETENTION} \
    -httpListenAddr=:8428 \
    ${EXTRA_ARGS}
ExecStop=${RUNTIME_BIN} stop victoria-metrics

[Install]
WantedBy=multi-user.target
EOF

# ---------------- ENABLE SERVICE ----------------
sudo systemctl daemon-reload
sudo systemctl enable --now victoria-metrics

echo ""
echo "===================================================="
echo " VictoriaMetrics single-node setup completed!"
echo "===================================================="
echo "  URL: http://<HOST-IP>:${HTTP_PORT}"
echo "  Metrics:          /metrics"
echo "  PromQL endpoint:  /api/v1/query"
echo "  Remote write:     /api/v1/write"
echo ""
echo " Example Prometheus remote_write:"
echo "   remote_write:"
echo "     - url: \"http://<HOST-IP>:${HTTP_PORT}/api/v1/write\""
echo ""
echo "Check status:"
echo "   systemctl status victoria-metrics"
echo ""
echo "Test metrics:"
echo "   curl http://127.0.0.1:${HTTP_PORT}/metrics | head"
echo ""