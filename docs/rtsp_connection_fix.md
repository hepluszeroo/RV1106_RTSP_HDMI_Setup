# RTSP Connection Refused Fix
# RTSP连接被拒绝解决方案

## Problem / 问题
- Web interface shows video (网页可以看到画面) ✅
- RTSP connection refused (RTSP连接被拒绝) ❌

## Quick Diagnosis / 快速诊断

### 1. Check RTSP Port / 检查RTSP端口
```bash
ssh root@[board_ip]
netstat -tln | grep 1554
# Should show: 0.0.0.0:1554 LISTEN
```

### 2. Check Process / 检查进程
```bash
ps aux | grep nrkipc
# Should show nrkipc process running
```

## Common Solutions / 常见解决方案

### Solution 1: Firewall Issue / 防火墙问题
```bash
# On board / 在板子上
iptables -L
# If firewall rules exist, disable:
iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
```

### Solution 2: RTSP Server Not Started / RTSP服务未启动
```bash
# Check logs / 查看日志
cat /tmp/nrkipc.log | grep rtsp

# Restart service / 重启服务
killall nrkipc
cd /tmp
export LD_LIBRARY_PATH=/oem/usr/lib
./nrkipc &
```

### Solution 3: Wrong RTSP URL / RTSP地址错误
```
Correct URLs / 正确的地址:
- Main stream: rtsp://[board_ip]:1554/ch0
- Sub stream:  rtsp://[board_ip]:1554/ch1

NOT / 不是:
- rtsp://[board_ip]/ch0 ❌
- rtsp://[board_ip]:554/ch0 ❌
- rtsp://[board_ip]:1554 ❌
```

### Solution 4: Network Configuration / 网络配置
```bash
# Check if board and client are on same network
# 检查板子和客户端是否在同一网络
ping [board_ip]

# Check routing / 检查路由
route -n
```

### Solution 5: RTSP Authentication / RTSP认证
```bash
# Edit config to disable authentication
# 编辑配置禁用认证
vi /tmp/nrkipc.conf

# Look for auth settings and comment out
# 查找认证设置并注释掉
```

## Testing RTSP Connection / 测试RTSP连接

### Method 1: Using curl / 使用curl
```bash
curl -v rtsp://[board_ip]:1554/ch0
# Should return: RTSP/1.0 200 OK
```

### Method 2: Using VLC / 使用VLC
1. Open VLC
2. Media → Open Network Stream / 媒体 → 打开网络串流
3. Enter: `rtsp://[board_ip]:1554/ch0`
4. Click Play / 点击播放

### Method 3: Using ffprobe / 使用ffprobe
```bash
ffprobe rtsp://[board_ip]:1554/ch0
# Should show stream information
```

## Full Reset Procedure / 完全重置步骤
```bash
# 1. Kill all processes / 停止所有进程
killall nrkipc 2>/dev/null

# 2. Clear temp files / 清理临时文件
rm -rf /tmp/nrkipc* /tmp/log /tmp/htdocs

# 3. Re-extract from source / 重新解压
cd /root/release
cp bin/nrkipc /tmp/
cp configs/nrkipc.conf /tmp/
cp -r htdocs /tmp/
mkdir -p /tmp/log
chmod +x /tmp/nrkipc

# 4. Start with debug / 带调试启动
cd /tmp
export LD_LIBRARY_PATH=/oem/usr/lib
./nrkipc 2>&1 | tee debug.log

# 5. Check for errors / 检查错误
grep -i error debug.log
```

## Verify Working State / 验证工作状态
```bash
# All should return positive results:
ps aux | grep nrkipc          # Process running
netstat -tln | grep 1554      # Port listening
curl -I http://[ip]:3689/     # Web working
curl rtsp://[ip]:1554/        # RTSP responding
```

## If Still Not Working / 如果仍然不工作

### Check these files exist / 检查这些文件存在:
```bash
ls -la /tmp/nrkipc
ls -la /tmp/nrkipc.conf
ls -la /tmp/htdocs/
ls -la /tmp/log/
```

### Check library path / 检查库路径:
```bash
echo $LD_LIBRARY_PATH
# Should show: /oem/usr/lib

ls -la /oem/usr/lib/*.so
# Should list library files
```

### Check hardware status / 检查硬件状态:
```bash
cat /proc/interrupts | grep venc
# Should show non-zero numbers if encoding
```

## Contact Support / 联系支持
If web works but RTSP doesn't, provide:
1. Output of `netstat -tln`
2. Output of `ps aux | grep nrkipc`
3. Contents of `/tmp/nrkipc.log`
4. Exact RTSP URL being used
5. Error message from VLC/player