#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 检查是否为root用户
if [ "$(id -u)" -ne 0 ]; then
   echo -e "${RED}错误：请使用root用户运行此脚本。${NC}"
   exit 1
fi

echo -e "${GREEN}===== 开始安装 NetRouteProxy ====${NC}"

# 检测并安装curl
echo -e "${YELLOW}正在检测curl...${NC}"
if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}未找到curl，正在安装...${NC}"
    # 检测系统包管理器
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y curl
    elif command -v yum &> /dev/null; then
        yum install -y curl
    else
        echo -e "${RED}错误：无法识别系统包管理器，请手动安装curl。${NC}"
        exit 1
    fi
    echo -e "${GREEN}curl安装完成。${NC}"
else
    echo -e "${GREEN}已安装curl。${NC}"
fi

# 检测并安装Python3
echo -e "${YELLOW}正在检测Python3...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}未找到Python3，正在安装...${NC}"
    # 检测系统包管理器
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y python3 python3-pip
    elif command -v yum &> /dev/null; then
        yum install -y python3 python3-pip
    else
        echo -e "${RED}错误：无法识别系统包管理器，请手动安装Python3。${NC}"
        exit 1
    fi
    echo -e "${GREEN}Python3安装完成。${NC}"
else
    echo -e "${GREEN}已安装Python3。${NC}"
fi

# 检测并安装unzip
echo -e "${YELLOW}正在检测unzip...${NC}"
if ! command -v unzip &> /dev/null; then
    echo -e "${YELLOW}未找到unzip，正在安装...${NC}"
    # 检测系统包管理器
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y unzip
    elif command -v yum &> /dev/null; then
        yum install -y unzip
    else
        echo -e "${RED}错误：无法识别系统包管理器，请手动安装unzip。${NC}"
        exit 1
    fi
    echo -e "${GREEN}unzip安装完成。${NC}"
else
    echo -e "${GREEN}已安装unzip。${NC}"
fi

# 下载软件压缩包
echo -e "${YELLOW}正在下载NetRouteProxy...${NC}"
curl -L -o NetRouteProxy-main.zip https://github.com/Azizi030/NetRouteProxy/archive/refs/heads/main.zip
if [ $? -ne 0 ]; then
    echo -e "${RED}错误：下载失败，请检查网络连接或URL是否正确。${NC}"
    exit 1
fi
echo -e "${GREEN}下载完成。${NC}"

# 解压压缩包
echo -e "${YELLOW}正在解压...${NC}"
unzip -q NetRouteProxy-main.zip
if [ $? -ne 0 ]; then
    echo -e "${RED}错误：解压失败，请检查压缩包是否损坏。${NC}"
    exit 1
fi
echo -e "${GREEN}解压完成。${NC}"

# 清理压缩包
rm NetRouteProxy-main.zip

# 直接指定解压后的目录名
dir_name="NetRouteProxy-main"
if [ ! -d "$dir_name" ]; then
    echo -e "${RED}错误：未找到解压后的目录。${NC}"
    exit 1
fi

# 进入目录并运行程序
echo -e "${YELLOW}正在准备运行程序...${NC}"
cd "$dir_name" || exit

# 检查是否需要安装依赖
if [ -f "requirements.txt" ]; then
    echo -e "${YELLOW}正在安装Python依赖...${NC}"
    python3 -m pip install -r requirements.txt
    if [ $? -ne 0 ]; then
        echo -e "${RED}警告：依赖安装失败，请手动安装。${NC}"
    else
        echo -e "${GREEN}依赖安装完成。${NC}"
    fi
fi

# 查找主程序文件
main_file=""
for file in main.py *.py; do
    if [ -f "$file" ]; then
        main_file="$file"
        break
    fi
done

if [ -z "$main_file" ]; then
    echo -e "${RED}错误：未找到主程序文件。${NC}"
    exit 1
fi

# 前台运行程序并显示日志
echo -e "${GREEN}===== NetRouteProxy 安装部署完成 ====${NC}"
echo -e "${GREEN}程序目录: $(pwd)${NC}"
echo -e "${GREEN}===== 正在前台运行程序，按 Ctrl+C 停止 ====${NC}"
python3 "$main_file"
