#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== ChronoCards 健康检查 ==="
echo ""

# 1. 检查后端健康状态
echo -n "[Backend] "
if curl -sf http://localhost:8080/health > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}DOWN${NC}"
fi

# 2. 检查Ngrok Tunnel
echo -n "[Ngrok] "
if curl -sf --max-time 5 https://overhumble-laurine-unglamourously.ngrok-free.dev > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}DOWN${NC}"
fi

# 3. 检查Docker容器状态
echo ""
echo "[Docker Containers]"
docker ps --filter "name=chronocards" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Docker不可用"

# 4. 磁盘使用
echo ""
echo "[Disk Usage]"
df -h / | tail -1

# 5. 内存使用
echo ""
echo "[Memory Usage]"
free -h | grep Mem || free | grep Mem

# 6. CPU负载
echo ""
echo "[CPU Load]"
uptime | awk -F'load average:' '{print $2}'

echo ""
echo "=== 检查完成 ==="
