# UniVPN CLI (linux/arm64)

Unofficial Docker image for the Leagsoft UniVPN **CLI** client, built for native **linux/arm64**. There is no GUI, VNC, or amd64 image in this tree.

The client binary is included at `bin/univpn-linuxarm-64-10781.21.0.0831.zip` so the image can be built offline. It is proprietary; you are responsible for complying with the vendor's license. This repository does not grant any license to that software.

| Field | Value |
| :---- | :---- |
| Client | `10781.21.0.0831` (`univpn-linuxarm-64`) |
| Base | Ubuntu 24.04 (glibc required by `UniVPNCS`) |
| Platform | `linux/arm64` only. Do not build under QEMU `linux/amd64`. |
| SOCKS5 | Dante on `127.0.0.1:1080` |
| HTTP | Tinyproxy on `127.0.0.1:8888` |

## Build

```bash
docker build --platform linux/arm64 -t univpn-cli:arm64 .
```

## Run

Create `.env` from `.envexample` and a config directory (the client writes profiles under `univpn_config/`):

```bash
cp .envexample .env
mkdir -p univpn_config
./run-cli.sh
```

`run-cli.sh` starts a container named `univpn` from `univpn-cli:arm64`, with `NET_ADMIN`, `/dev/net/tun`, and `univpn_config` mounted at `/home/vpnuser/UniVPN`. Override with `IMAGE`, `NAME`, `ENV_FILE`, or `CONFIG_DIR`.

```bash
docker logs -f univpn
```

## Auto-reconnect

`univpn-keeper.sh` starts the CLI client. With `AUTO_RECONNECT=true` it waits `RECONNECT_GRACE_PERIOD` seconds, then pings `RECONNECT_PING_TARGET`. A failed ping kills the client so the keeper starts it again.

Restart the client without recreating the container:

```bash
docker exec univpn reconnect
```

Dante waits for `DANTE_INTERFACE` (default `cnem_vnic`). After the tunnel is up, check the interface name:

```bash
docker exec univpn ip -br link
```

## License

The Dockerfile and scripts are [MIT](LICENSE). The UniVPN client in `./bin` is proprietary.
