# 🚀 RV1106 RTSP Quick Start

## ⚡ 30-Second Setup

### Prerequisites
- Fresh flashed RV1106 board
- Board connected to network (gets DHCP IP)
- HDMI source connected

### Find Board IP
```bash
# Check router DHCP list or scan network
nmap -sn 192.168.0.0/24 | grep -B2 "MAC"
```

### Deploy in ONE Command
```bash
./scripts/deploy.sh 192.168.0.xxx
```

That's it! ✅

## 📺 Access Your Stream

- **Web**: `http://192.168.0.xxx:3689/`
- **RTSP**: `rtsp://192.168.0.xxx:1554/ch0`
- **VLC**: File → Open Network → Paste RTSP URL

## 🎯 Success Indicators

✅ Script shows all green checkmarks  
✅ CPU usage ~10%  
✅ Stream plays in VLC  

## 🔥 Manual Speed Run (if script fails)

```bash
# 1. Copy file (from this folder)
scp bin/nrkipc_release_rk628f_v1r3.zip root@192.168.0.xxx:/root/

# 2. SSH and run these 5 commands
ssh root@192.168.0.xxx
cd /root && unzip -o nrkipc_release_rk628f_v1r3.zip
cd release && ./install.sh
cp bin/nrkipc configs/nrkipc.conf /tmp/ && cp -r htdocs /tmp/ && mkdir -p /tmp/log
cd /tmp && export LD_LIBRARY_PATH=/oem/usr/lib && ./nrkipc &
```

## ⚠️ Remember

- Password: `luckfox`
- File MUST be: `nrkipc_release_rk628f_v1r3.zip` (RK628 version!)
- Run from `/tmp` not `/oem`

---
**Time to stream: <5 minutes** 🎬