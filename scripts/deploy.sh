#!/bin/bash

# RV1106 RTSP HDMI Automated Deployment Script
# Version: 1.0
# Purpose: Deploy nrkipc RK628 HDMI version to fresh RV1106 board

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DEFAULT_PASSWORD="luckfox"
NRKIPC_FILE="nrkipc_release_rk628f_v1r3.zip"

# Check arguments
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No board IP provided${NC}"
    echo "Usage: $0 <board_ip> [password]"
    echo "Example: $0 192.168.0.174"
    echo "Example: $0 192.168.0.174 mypassword"
    exit 1
fi

BOARD_IP=$1
PASSWORD=${2:-$DEFAULT_PASSWORD}

# Check if nrkipc file exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NRKIPC_PATH="$PROJECT_ROOT/bin/$NRKIPC_FILE"

if [ ! -f "$NRKIPC_PATH" ]; then
    echo -e "${RED}Error: $NRKIPC_FILE not found in bin directory${NC}"
    echo "Expected location: $NRKIPC_PATH"
    exit 1
fi

echo "================================================"
echo "RV1106 RTSP HDMI Deployment Script"
echo "================================================"
echo -e "Board IP: ${GREEN}$BOARD_IP${NC}"
echo -e "Password: ${GREEN}$PASSWORD${NC}"
echo -e "Package: ${GREEN}$NRKIPC_FILE${NC}"
echo "================================================"
echo ""

# Function to execute SSH commands
ssh_exec() {
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$BOARD_IP "$1"
}

# Function to copy files
scp_copy() {
    sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$1" root@$BOARD_IP:"$2"
}

# Step 1: Test connection
echo -e "${YELLOW}[1/6] Testing connection to board...${NC}"
if ssh_exec "echo 'Connected successfully'" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Connection successful${NC}"
else
    echo -e "${RED}✗ Cannot connect to board at $BOARD_IP${NC}"
    exit 1
fi

# Step 2: Transfer nrkipc package
echo -e "${YELLOW}[2/6] Transferring nrkipc package...${NC}"
scp_copy "$NRKIPC_PATH" "/root/"
echo -e "${GREEN}✓ Package transferred${NC}"

# Step 3: Extract and install
echo -e "${YELLOW}[3/6] Installing nrkipc...${NC}"
ssh_exec "cd /root && unzip -o $NRKIPC_FILE && cd release && chmod +x install.sh && ./install.sh" > /dev/null 2>&1
echo -e "${GREEN}✓ Installation complete${NC}"

# Step 4: Fix CAC file if needed
echo -e "${YELLOW}[4/6] Configuring ISP settings...${NC}"
ssh_exec "mkdir -p /etc/iqfiles/CAC_sc4336_OT01_40IRC_F16 && \
         if [ ! -f /etc/iqfiles/CAC_sc4336_OT01_40IRC_F16/cac_map_hw_1920x1080.bin ]; then \
             cp /etc/iqfiles/CAC_sc4336_OT01_40IRC_F16/cac_map_hw_2560x1440.bin \
                /etc/iqfiles/CAC_sc4336_OT01_40IRC_F16/cac_map_hw_1920x1080.bin 2>/dev/null || true; \
         fi"
echo -e "${GREEN}✓ ISP configured${NC}"

# Step 5: Prepare runtime environment and start service
echo -e "${YELLOW}[5/6] Starting RTSP service...${NC}"
ssh_exec "killall nrkipc 2>/dev/null || true; \
         cp /root/release/bin/nrkipc /tmp/ && \
         cp /root/release/configs/nrkipc.conf /tmp/ && \
         cp -r /root/release/htdocs /tmp/ && \
         mkdir -p /tmp/log && \
         chmod +x /tmp/nrkipc && \
         cd /tmp && \
         export LD_LIBRARY_PATH=/oem/usr/lib && \
         nohup ./nrkipc > /tmp/nrkipc.log 2>&1 & \
         sleep 2"
echo -e "${GREEN}✓ Service started${NC}"

# Step 6: Verify deployment
echo -e "${YELLOW}[6/6] Verifying deployment...${NC}"
echo ""

# Check process
PROCESS_CHECK=$(ssh_exec "ps aux | grep nrkipc | grep -v grep" 2>/dev/null || echo "")
if [ ! -z "$PROCESS_CHECK" ]; then
    echo -e "${GREEN}✓ nrkipc process running${NC}"
    CPU_USAGE=$(echo "$PROCESS_CHECK" | awk '{print $3}')
    echo "  CPU Usage: $CPU_USAGE%"
else
    echo -e "${RED}✗ nrkipc process not found${NC}"
fi

# Check ports
RTSP_PORT=$(ssh_exec "netstat -tln | grep 1554" 2>/dev/null || echo "")
WEB_PORT=$(ssh_exec "netstat -tln | grep 3689" 2>/dev/null || echo "")

if [ ! -z "$RTSP_PORT" ]; then
    echo -e "${GREEN}✓ RTSP server listening on port 1554${NC}"
else
    echo -e "${RED}✗ RTSP port 1554 not active${NC}"
fi

if [ ! -z "$WEB_PORT" ]; then
    echo -e "${GREEN}✓ Web interface listening on port 3689${NC}"
else
    echo -e "${RED}✗ Web port 3689 not active${NC}"
fi

# Check hardware acceleration
INTERRUPTS=$(ssh_exec "cat /proc/interrupts | grep rkvenc | awk '{print \$2}'" 2>/dev/null || echo "0")
if [ "$INTERRUPTS" != "0" ]; then
    echo -e "${GREEN}✓ Hardware encoder active ($INTERRUPTS interrupts)${NC}"
else
    echo -e "${YELLOW}⚠ Hardware encoder not yet active (connect HDMI source)${NC}"
fi

echo ""
echo "================================================"
echo -e "${GREEN}Deployment Complete!${NC}"
echo "================================================"
echo -e "Web Interface: ${GREEN}http://$BOARD_IP:3689/${NC}"
echo -e "RTSP Main Stream: ${GREEN}rtsp://$BOARD_IP:1554/ch0${NC}"
echo -e "RTSP Sub Stream: ${GREEN}rtsp://$BOARD_IP:1554/ch1${NC}"
echo "================================================"
echo ""
echo "To test the stream:"
echo "  VLC: Media -> Open Network Stream -> rtsp://$BOARD_IP:1554/ch0"
echo "  ffmpeg: ffprobe rtsp://$BOARD_IP:1554/ch0"
echo ""