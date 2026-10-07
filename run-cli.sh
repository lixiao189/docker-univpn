#!/bin/sh
set -eu

cd "$(dirname "$0")"

IMAGE="${IMAGE:-univpn-cli:arm64}"
NAME="${NAME:-univpn}"
ENV_FILE="${ENV_FILE:-.env}"
CONFIG_DIR="${CONFIG_DIR:-$(pwd)/univpn_config}"

if [ ! -f "$ENV_FILE" ]; then
  echo "missing env file: $ENV_FILE (copy .env.example to .env)" >&2
  exit 1
fi

require_env() {
  key="$1"
  if ! grep -Eq "^${key}=.+" "$ENV_FILE"; then
    echo "missing ${key} in $ENV_FILE" >&2
    exit 1
  fi
}

require_env VPN_USERNAME
require_env VPN_PASSWORD
require_env VPN_SERVER_IP
require_env VPN_SERVER_PORT

mkdir -p "$CONFIG_DIR"

if docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
  echo "removing existing container: $NAME"
  docker rm -f "$NAME" >/dev/null
fi

set --
if [ -n "${SPOOF_MAC:-}" ]; then
  set -- --mac-address "$SPOOF_MAC"
fi

docker run -d \
  --name "$NAME" \
  --platform linux/arm64 \
  --restart unless-stopped \
  --cap-add NET_ADMIN \
  --device /dev/net/tun:/dev/net/tun \
  --env-file "$ENV_FILE" \
  -e DEBUG_MODE="${DEBUG_MODE:-true}" \
  -p 127.0.0.1:1080:1080 \
  -p 127.0.0.1:8888:8888 \
  -v "$CONFIG_DIR:/home/vpnuser/UniVPN" \
  "$@" \
  "$IMAGE"

echo "started $NAME ($IMAGE)"
echo "logs: docker logs -f $NAME"
