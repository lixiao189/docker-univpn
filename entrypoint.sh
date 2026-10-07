#!/bin/bash
set -euo pipefail

CONFIG_DIR="/home/vpnuser/UniVPN"
CONFIG_FILE="${CONFIG_DIR}/sysconfig.ini"
PROFILE_DIR="${CONFIG_DIR}/config"
PROFILE_NAME="${VPN_PROFILE_NAME:-school.ini}"
PROFILE_FILE="${PROFILE_DIR}/${PROFILE_NAME}"
KEEPER_SCRIPT="/usr/local/bin/univpn-keeper.sh"

echo "========================================="
echo "UniVPN Container Initialization"
echo "========================================="

echo "Running as user: $(whoami) (UID=$(id -u), GID=$(id -g))"
echo "Home directory: $HOME"

missing=0
for name in VPN_USERNAME VPN_PASSWORD VPN_SERVER_IP VPN_SERVER_PORT; do
    if [ -z "${!name:-}" ]; then
        echo "ERROR: ${name} is not set. Copy .env.example to .env and fill it in."
        missing=1
    fi
done
if [ "$missing" -ne 0 ]; then
    exit 1
fi

case "$VPN_SERVER_IP" in
    *[!0-9.]*)
        echo "ERROR: VPN_SERVER_IP must be an IPv4 address"
        exit 1
        ;;
esac
case "$VPN_SERVER_PORT" in
    ''|*[!0-9]*)
        echo "ERROR: VPN_SERVER_PORT must be a number"
        exit 1
        ;;
esac
if [ "$VPN_SERVER_PORT" -lt 1 ] || [ "$VPN_SERVER_PORT" -gt 65535 ]; then
    echo "ERROR: VPN_SERVER_PORT must be between 1 and 65535"
    exit 1
fi
case "$PROFILE_NAME" in
    *[/\\]*|.|..)
        echo "ERROR: VPN_PROFILE_NAME must be a file name, not a path"
        exit 1
        ;;
esac

mkdir -p "$PROFILE_DIR"

cat > "$CONFIG_FILE" <<EOF
[GLOBAL]
ClientName = 
ClientVersion = 
ClientCustomized = 
ClientLogLevel = 1

[ADVANCED]
ClientDetectLatestVersion = 1
ClientAutoBoot = 1
ClientLanguageID = 1000
ClientServerCheck = 1
ClientShowLogFlag = 0
ClientLastAccessSession = ${PROFILE_NAME}
ClientSwitchNetwork = 0
ClientTcpBufferSize = 0
ClientMtuValue = 1300

ClientReConnectTimeValue = 5
[PROXY]
ProxyType = 0
ProxyAddr = 
ProxyPort = 0
ProxyUser = 
ProxyInfo = 

[Session0]
ConnectType = 1
RemPwd = 0
AuthType = 0
AutoLogin = 1
LastLoginAddr = ${VPN_SERVER_IP}:${VPN_SERVER_PORT}
ProfileName = ${PROFILE_NAME}
ProfileUser = ${VPN_USERNAME}
ProfileInfo = 

[Session1]
ProfileInfo = 
EOF

cat > "$PROFILE_FILE" <<EOF
[GLOBAL]
sign_certificate = 
encryp_certificate = 
iConnectionType = 1
Description = 
GatewayAddress = ${VPN_SERVER_IP}
GatewayPort = ${VPN_SERVER_PORT}
TunnelMode = 2
PreflinkEnable = 0
DefaultGateway = -1
iroutecoverEnable = 1
icertificateEnable = 0
igmalgorithmEnable = 0
PreflinkTotal = 0
EOF

echo "Wrote gateway ${VPN_SERVER_IP}:${VPN_SERVER_PORT} to ${PROFILE_NAME}"

echo ""
echo "Configuration:"
echo "  VPN_SERVER: ${VPN_SERVER_IP}:${VPN_SERVER_PORT}"
echo "  VPN_PROFILE: ${PROFILE_NAME}"
echo "  AUTO_RECONNECT: ${AUTO_RECONNECT:-true}"
echo "  RECONNECT_PING_TARGET: ${RECONNECT_PING_TARGET:-8.8.8.8}"
echo "  RECONNECT_GRACE_PERIOD: ${RECONNECT_GRACE_PERIOD:-60}s"
echo "  HEALTH_CHECK_INTERVAL: ${HEALTH_CHECK_INTERVAL:-10}s"
echo "  VPN_USERNAME: ***set***"
echo "  VPN_PASSWORD: ***set***"

echo "========================================="
echo "Starting UniVPN Keeper..."
echo "========================================="
echo ""

if [ $# -eq 0 ]; then
    exec "$KEEPER_SCRIPT"
else
    exec "$@"
fi
