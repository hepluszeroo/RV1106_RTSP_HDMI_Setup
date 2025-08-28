# Troubleshooting Guide

## Common Issues and Solutions

### 🔴 Permission Denied Error

**Symptom**: `sh: ./nrkipc: Permission denied`

**Solution**:
```bash
# Run from /tmp instead of /oem
cp /oem/usr/bin/nrkipc /tmp/
chmod +x /tmp/nrkipc
cd /tmp && ./nrkipc
```

### 🔴 No Video Capture (0 Interrupts)

**Symptom**: Hardware interrupts stay at 0

**Check HDMI Detection**:
```bash
dmesg | grep rk628
# Should show: rk628_csi_s_stream: on: 1, 1920x1080@60
```

**Solutions**:
1. Verify HDMI cable is connected
2. Check source is outputting 1920x1080@60Hz
3. Power cycle the board with HDMI connected

### 🔴 High CPU Usage (>20%)

**Check for Hardware Acceleration**:
```bash
cat /proc/interrupts | grep venc
# Should show increasing numbers, not 0
```

**Solutions**:
1. Kill duplicate processes: `killall nrkipc`
2. Restart service from /tmp
3. Verify LD_LIBRARY_PATH is set

### 🔴 RTSP Connection Timeout

**Check Service Status**:
```bash
ps aux | grep nrkipc
netstat -tln | grep 1554
```

**Solutions**:
1. Restart nrkipc service
2. Check firewall settings
3. Verify network connectivity

### 🔴 "Config file errors" Message

**Symptom**: `Could not open config file ./nrkipc.conf`

**Solution**:
```bash
cp /root/release/configs/nrkipc.conf /tmp/
cd /tmp && ./nrkipc
```

### 🔴 Web Interface Not Loading

**Check Port**:
```bash
netstat -tln | grep 3689
```

**Solutions**:
1. Copy htdocs folder: `cp -r /root/release/htdocs /tmp/`
2. Restart nrkipc
3. Clear browser cache

### 🔴 Stream Stuttering or Low FPS

**Check Performance**:
```bash
# Calculate actual FPS
INT1=$(cat /proc/interrupts | grep rkvenc | awk '{print $2}')
sleep 2
INT2=$(cat /proc/interrupts | grep rkvenc | awk '{print $2}')
echo "FPS: $(( (INT2 - INT1) / 2 ))"
```

**Solutions**:
1. Check network bandwidth
2. Reduce bitrate in config
3. Ensure hardware acceleration is active

## Diagnostic Commands

### Full System Check
```bash
# Process status
ps aux | grep nrkipc

# Network ports
netstat -tln | grep -E "3689|1554"

# Hardware interrupts
cat /proc/interrupts | grep -E "rkcif|venc"

# System load
top -bn1 | head -10

# HDMI status
dmesg | grep -E "rk628|hdmi" | tail -10
```

### Quick Health Check Script
```bash
#!/bin/bash
echo "=== nrkipc Health Check ==="
echo -n "Process: "
ps aux | grep nrkipc | grep -v grep > /dev/null && echo "✓ Running" || echo "✗ Not running"

echo -n "RTSP Port: "
netstat -tln | grep 1554 > /dev/null && echo "✓ Active" || echo "✗ Inactive"

echo -n "Web Port: "
netstat -tln | grep 3689 > /dev/null && echo "✓ Active" || echo "✗ Inactive"

echo -n "Hardware Encoder: "
INT=$(cat /proc/interrupts | grep rkvenc | awk '{print $2}')
[ "$INT" -gt "0" ] && echo "✓ Active ($INT interrupts)" || echo "✗ Inactive"
```

## Recovery Procedures

### Complete Service Restart
```bash
# Kill existing process
killall nrkipc 2>/dev/null

# Clean temporary files
rm -f /tmp/nrkipc.log

# Restart service
cd /tmp
export LD_LIBRARY_PATH=/oem/usr/lib
./nrkipc &
```

### Fresh Installation
```bash
# Remove old installation
rm -rf /root/release /tmp/nrkipc* /tmp/htdocs

# Re-deploy
cd /root
unzip -o nrkipc_release_rk628f_v1r3.zip
cd release && ./install.sh

# Start fresh
cp bin/nrkipc /tmp/
cp configs/nrkipc.conf /tmp/
cp -r htdocs /tmp/
mkdir -p /tmp/log
cd /tmp && export LD_LIBRARY_PATH=/oem/usr/lib
./nrkipc &
```

## Performance Optimization

### Reduce CPU Usage
1. Ensure hardware acceleration is active
2. Lower output resolution if needed
3. Reduce bitrate in configuration

### Improve Stream Quality
1. Increase bitrate (may increase CPU)
2. Ensure stable network connection
3. Use wired connection instead of WiFi

## Contact Support

If issues persist after trying these solutions:
1. Collect diagnostic output (all commands above)
2. Note exact error messages
3. Document reproduction steps
4. Check GitHub issues for similar problems