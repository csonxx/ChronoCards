#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}[Deploy] ChronoCards 部署开始...${NC}"

# 1. Build Flutter Web
echo -e "${YELLOW}[1/3] Build Flutter Web...${NC}"
cd /root/.openclaw/workspace-server/ChronoCards/app
if flutter build web --release; then
    echo -e "${GREEN}[OK] Flutter Web 构建成功${NC}"
else
    echo -e "${RED}[FAIL] Flutter Web 构建失败${NC}"
    exit 1
fi

# 2. Build Go Backend
echo -e "${YELLOW}[2/3] Build Go Backend...${NC}"
cd /root/.openclaw/workspace-server/ChronoCards/server
if go build -o chronocards-server .; then
    echo -e "${GREEN}[OK] Go Backend 构建成功${NC}"
else
    echo -e "${RED}[FAIL] Go Backend 构建失败${NC}"
    exit 1
fi

# 3. Docker Compose up
echo -e "${YELLOW}[3/3] Docker Compose up...${NC}"
if docker-compose up -d --build; then
    echo -e "${GREEN}[OK] 容器启动成功${NC}"
else
    echo -e "${RED}[FAIL] 容器启动失败${NC}"
    exit 1
fi

echo -e "${GREEN}[Deploy] 部署完成!${NC}"
echo "服务状态:"
docker-compose ps
