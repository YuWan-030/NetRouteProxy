#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

INSTALL_DIR="/opt/netrouteproxy"
SERVICE_NAME="nr"

echo -e "${GREEN}===== 开始安装 NetRouteProxy ====${NC}"

# 检查root
if [ "$(id -u)" -ne 0 ]; then
   echo -e "${RED}错误：请使用root用户运行此脚本。${NC}"
   exit 1
fi

# 安装依赖
echo -e "${YELLOW}正在检测curl...${NC}"
if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}未找到curl，正在安装...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y curl
    elif command -v yum &> /dev/null; then
        yum install -y curl
    else
        echo -e "${RED}无法识别包管理器，请手动安装curl。${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}正在检测Python3...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}未找到Python3，正在安装...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y python3 python3-pip
    elif command -v yum &> /dev/null; then
        yum install -y python3 python3-pip
    else
        echo -e "${RED}无法识别包管理器，请手动安装Python3。${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}正在检测unzip...${NC}"
if ! command -v unzip &> /dev/null; then
    echo -e "${YELLOW}未找到unzip，正在安装...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y unzip
    elif command -v yum &> /dev/null; then
        yum install -y unzip
    else
        echo -e "${RED}无法识别包管理器，请手动安装unzip。${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}正在下载 NetRouteProxy 源码...${NC}"
curl -L -o NetRouteProxy-main.zip https://github.com/Azizi030/NetRouteProxy/archive/refs/heads/main.zip
if [ $? -ne 0 ]; then
    echo -e "${RED}下载失败，请检查网络连接或URL是否正确。${NC}"
    exit 1
fi

echo -e "${YELLOW}正在解压...${NC}"
unzip -q NetRouteProxy-main.zip
if [ $? -ne 0 ]; then
    echo -e "${RED}解压失败，请检查压缩包是否损坏。${NC}"
    exit 1
fi
rm NetRouteProxy-main.zip

# 安装文件到指定目录
mkdir -p "$INSTALL_DIR"
cp -rf NetRouteProxy-main/* "$INSTALL_DIR"

# 安装依赖
cd "$INSTALL_DIR"
if [ -f "requirements.txt" ]; then
    echo -e "${YELLOW}正在安装Python依赖...${NC}"
    python3 -m pip install -r requirements.txt
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}依赖安装完成。${NC}"
    else
        echo -e "${RED}依赖安装失败，请手动安装。${NC}"
    fi
fi

# 创建 systemd 服务配置（服务名为nr）
echo -e "${YELLOW}正在配置 systemd 服务...${NC}"
cat > /etc/systemd/system/${SERVICE_NAME}.service <<EOF
[Unit]
Description=NetRouteProxy Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 $INSTALL_DIR/main.py
WorkingDirectory=$INSTALL_DIR
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ${SERVICE_NAME}
systemctl restart ${SERVICE_NAME}

echo -e "${GREEN}NetRouteProxy 已安装并作为系统服务运行!${NC}"
echo -e "${GREEN}你可以使用如下命令管理:${NC}"
echo -e "${YELLOW}systemctl start nr${NC}"
echo -e "${YELLOW}systemctl stop nr${NC}"
echo -e "${YELLOW}systemctl restart nr${NC}"
echo -e "${YELLOW}systemctl status nr${NC}"

echo -e "${GREEN}Web管理面板可通过以下地址访问:${NC}"
for ip in $(hostname -I); do
    echo -e "${GREEN}http://$ip:8088${NC}"
done