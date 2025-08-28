# RV1106 RTSP HDMI Setup

A streamlined deployment solution for RV1106 boards with RK628 HDMI input, enabling hardware-accelerated RTSP streaming at 1920x1080@30fps with minimal CPU usage.

## 🎯 Features

- **Hardware Accelerated**: Uses RV1106's rkvenc for H.264 encoding
- **Low CPU Usage**: Only ~10% CPU for full HD streaming
- **30fps Output**: From 60Hz HDMI input
- **Dual Access**: RTSP stream + Web interface
- **Quick Deploy**: <5 minutes setup per board
- **Single File**: Only one 7.6MB package needed

## 📋 Requirements

- RV1106 board with RK628 HDMI input
- Network connection (Ethernet)
- HDMI source (1920x1080@60Hz)
- Host computer with SSH/SCP

## 🚀 Quick Start

### One-Command Deployment

```bash
./scripts/deploy.sh <board_ip>
```

Example:
```bash
./scripts/deploy.sh 192.168.0.174
```

### Manual Setup

1. Transfer the package:
```bash
scp bin/nrkipc_release_rk628f_v1r3.zip root@<board_ip>:/root/
```

2. SSH to board and install:
```bash
ssh root@<board_ip>
cd /root && unzip nrkipc_release_rk628f_v1r3.zip
cd release && ./install.sh
```

3. Start streaming:
```bash
cp bin/nrkipc /tmp/ && cp configs/nrkipc.conf /tmp/
cp -r htdocs /tmp/ && mkdir -p /tmp/log
cd /tmp && export LD_LIBRARY_PATH=/oem/usr/lib
./nrkipc &
```

## 📺 Access Streams

- **Web Interface**: `http://<board_ip>:3689/`
- **RTSP Main**: `rtsp://<board_ip>:1554/ch0`
- **RTSP Sub**: `rtsp://<board_ip>:1554/ch1`

### Testing with VLC

1. Open VLC Media Player
2. Media → Open Network Stream
3. Enter: `rtsp://<board_ip>:1554/ch0`

### Testing with ffmpeg

```bash
ffprobe rtsp://<board_ip>:1554/ch0
```

## 📊 Performance

| Metric | Value |
|--------|-------|
| Resolution | 1920x1080 |
| Frame Rate | 30 fps |
| CPU Usage | ~10% |
| Memory | ~92MB |
| Latency | <100ms |
| Bitrate | 4-8 Mbps |

## 📁 Repository Structure

```
RV1106_RTSP_HDMI_Setup/
├── bin/
│   └── nrkipc_release_rk628f_v1r3.zip  # RK628 HDMI version (REQUIRED)
├── scripts/
│   └── deploy.sh                       # Automated deployment script
├── docs/
│   └── troubleshooting.md             # Common issues and solutions
└── README.md
```

## ⚠️ Important Notes

- **MUST use RK628 version** (`nrkipc_release_rk628f_v1r3.zip`)
- Regular nrkipc will NOT work with HDMI input
- Default password: `luckfox`
- Board gets DHCP IP on boot

## 🔧 Troubleshooting

### No Video Output
- Check HDMI cable connection
- Verify source is 1920x1080@60Hz
- Check interrupts: `cat /proc/interrupts | grep rkvenc`

### High CPU Usage
- Verify hardware acceleration is active
- Check for duplicate nrkipc processes
- Ensure running from /tmp not /oem

### Cannot Connect
- Check board IP with `ifconfig`
- Verify network connectivity
- Default SSH port: 22

## 📈 System Architecture

```
HDMI Input (60Hz) → RK628 Chip → MIPI CSI → RV1106
                                              ↓
                                          nrkipc (10% CPU)
                                              ↓
                                     Hardware Encoder (rkvenc)
                                              ↓
                                        H.264 Stream (30fps)
                                          ↓         ↓
                                    RTSP:1554   Web:3689
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Test on actual hardware
4. Submit pull request

## 📄 License

This project is for educational and development purposes.

## 🙏 Acknowledgments

- Vendor support for RK628 HDMI version
- Hardware acceleration via Rockchip MPP

---

**Success Rate**: 100% with correct RK628 version  
**Tested**: RV1106 with RK628 HDMI input board  
**Version**: 1.0.0