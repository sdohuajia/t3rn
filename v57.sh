#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/t3rn.sh"
LOGFILE="$HOME/executor/executor.log"
EXECUTOR_DIR="$HOME/executor"

# 检查是否以 root 用户运行
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以 root 用户权限运行。请使用 'sudo -i' 然后重试。"
    exit 1
fi

# 检查并安装 pm2
if ! command -v pm2 &> /dev/null; then
    echo "正在安装 pm2..."
    sudo npm install -g pm2 || { echo "pm2 安装失败"; exit 1; }
fi

# 检查并安装 tar
if ! dpkg -s tar &> /dev/null; then
    echo "正在安装 tar..."
    sudo apt-get update && sudo apt-get install -y tar || { echo "tar 安装失败"; exit 1; }
fi

# 下载最新版本的 executor
echo "正在下载 v57 executor..."
wget -O executor-linux-0.57.0.tar.gz https://github.com/t3rn/executor-release/releases/download/v0.57.0/executor-linux-v0.57.0.tar.gz || { echo "下载失败"; exit 1; }

# 解压文件
echo "正在解压文件..."
tar -xzf executor-linux-0.57.0.tar.gz || { echo "解压失败"; exit 1; }
rm executor-linux-0.57.0.tar.gz

# 检查解压后目录
if [ ! -d "$EXECUTOR_DIR/executor/bin" ]; then
    echo "错误：未找到 executor 目录！"
    exit 1
fi

# 询问用户输入环境变量
read -p "请输入 EXECUTOR_MAX_L3_GAS_PRICE 的值 [默认 100]: " EXECUTOR_MAX_L3_GAS_PRICE
EXECUTOR_MAX_L3_GAS_PRICE="${EXECUTOR_MAX_L3_GAS_PRICE:-100}"

# 设置环境变量
export ENVIRONMENT=testnet
export LOG_LEVEL=debug
export LOG_PRETTY=false
export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,unichain-sepolia,optimism-sepolia,l2rn'
export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
export EXECUTOR_MAX_L3_GAS_PRICE="$EXECUTOR_MAX_L3_GAS_PRICE"

# 新增的环境变量
export EXECUTOR_PROCESS_BIDS_ENABLED=true
export EXECUTOR_PROCESS_ORDERS_ENABLED=true
export EXECUTOR_PROCESS_CLAIMS_ENABLED=true
export NETWORKS_DISABLED="blast-sepolia"

# 提示用户输入 Alchemy Key
read -p "请输入 KEY ALCHEMY (留空使用默认公共RPC): " KEYALCHEMY

# 判断用户是否输入了 KEYALCHEMY
if [[ -n "$KEYALCHEMY" ]]; then
    export RPC_ENDPOINTS='{
        "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
        "arbt": ["https://arb-sepolia.g.alchemy.com/v2/'"$KEYALCHEMY"'"],
        "bast": ["https://base-sepolia.g.alchemy.com/v2/'"$KEYALCHEMY"'"],
        "opst": ["https://opt-sepolia.g.alchemy.com/v2/'"$KEYALCHEMY"'"],
        "unit": ["https://unichain-sepolia.g.alchemy.com/v2/'"$KEYALCHEMY"'"]
    }'
else
    export RPC_ENDPOINTS='{
        "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
        "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
        "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
        "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
        "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"]
    }'
fi

# 显示最终使用的 RPC
echo "RPC_ENDPOINTS 已设置为:"
echo "$RPC_ENDPOINTS"

read -p "请输入 PRIVATE_KEY_LOCAL 的值: " PRIVATE_KEY_LOCAL
export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"

# 进入 executor 目录并启动
cd "$EXECUTOR_DIR/executor/bin" || { echo "切换目录失败"; exit 1; }
pm2 start ./executor --name "executor" --log "$LOGFILE" --env NODE_ENV=testnet
pm2 list
echo "executor 已通过 pm2 启动。"
