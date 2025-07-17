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
echo -e "${GREEN}===== 正在前台运行 NetRouteProxy，按 Ctrl+C 停止 ====${NC}"
python3 "$main_file"
