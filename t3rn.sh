#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/t3rn.sh"
LOGFILE="$HOME/executor/executor.log"
EXECUTOR_DIR="$HOME/executor"

# 检查是否以 root 用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以 root 用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到 root 用户，然后再次运行此脚本。"
    exit 1
fi

# 检查并安装 Node.js 和 npm
function install_node_npm() {
    if ! command -v npm &> /dev/null || ! command -v node &> /dev/null; then
        echo "Node.js 或 npm 未安装，正在安装 Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
        if [ $? -eq 0 ]; then
            echo "Node.js 和 npm 安装成功，版本信息："
            node -v
            npm -v
        else
            echo "Node.js 安装失败，请检查网络或包管理器配置。"
            exit 1
        fi
    else
        echo "Node.js 和 npm 已安装，继续执行。"
        node -v
        npm -v
    fi
}

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1) 执行脚本（最新版）"
        echo "2) 查看日志"
        echo "3) 删除节点"
        echo "4) 安装 v63.1.sh"
        echo "5) 安装 v57.sh"
        echo "6) 安装 v58.sh"
        echo "7) 安装 v59.sh"
        echo "8) 安装 v62.sh"
        echo "9) 退出"
        
        read -p "请输入你的选择 [1-9]: " choice
        
        case $choice in
            1)
                execute_script
                ;;
            2)
                view_logs
                ;;
            3)
                delete_node
                ;;
            4)
                install_v63_1
                ;;
            5)
                install_v57
                ;;
            6)
                install_v58
                ;;
            7)
                install_v59
                ;;
            8)
                install_v62
                ;;
            9)
                echo "退出脚本。"
                exit 0
                ;;
            *)
                echo "无效的选择，请重新输入。"
                read -n 1 -s -r -p "按任意键继续..."
                ;;
        esac
    done
}

# 执行脚本函数
function execute_script() {
    # 检查并安装 Node.js 和 npm
    install_node_npm

    # 检查 pm2 是否安装，如果没有安装则自动安装
    if ! command -v pm2 &> /dev/null; then
        echo "pm2 未安装，正在安装 pm2..."
        sudo npm install -g pm2
        if [ $? -eq 0 ]; then
            echo "pm2 安装成功。"
        else
            echo "pm2 安装失败，请检查 npm 配置。"
            exit 1
        fi
    else
        echo "pm2 已安装，继续执行。"
    fi

    # 检查 tar 是否安装，如果没有安装则自动安装
    if ! command -v tar &> /dev/null; then
        echo "tar 未安装，正在安装 tar..."
        sudo apt-get update && sudo apt-get install -y tar
        if [ $? -eq 0 ]; then
            echo "tar 安装成功。"
        else
            echo "tar 安装失败，请检查包管理器配置。"
            exit 1
        fi
    else
        echo "tar 已安装，继续执行。"
    fi

    # 创建 executor 目录（如果不存在）
    mkdir -p "$EXECUTOR_DIR"
    cd "$EXECUTOR_DIR" || { echo "无法切换到 $EXECUTOR_DIR"; exit 1; }

    # 下载最新版本的文件
    echo "正在下载最新版本的 executor..."
    curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | \
    grep -Po '"tag_name": "\K.*?(?=")' | \
    xargs -I {} wget -q https://github.com/t3rn/executor-release/releases/download/{}/executor-linux-{}.tar.gz

    # 检查下载是否成功
    if [ $? -eq 0 ]; then
        echo "下载成功。"
    else
        echo "下载失败，请检查网络连接或下载地址。"
        exit 1
    fi

    # 解压文件到当前目录
    echo "正在解压文件..."
    tar -xzf executor-linux-*.tar.gz

    # 检查解压是否成功
    if [ $? -eq 0 ]; then
        echo "解压成功。"
    else
        echo "解压失败，请检查 tar.gz 文件。"
        exit 1
    fi

    # 检查解压后的文件名是否包含 'executor'
    echo "正在检查解压后的文件或目录名称是否包含 'executor'..."
    if ls | grep -q 'executor'; then
        echo "检查通过，找到包含 'executor' 的文件或目录。"
    else
        echo "未找到包含 'executor' 的文件或目录，可能文件名不正确。"
        exit 1
    fi

    # 提示用户输入环境变量的值，给 EXECUTOR_MAX_L3_GAS_PRICE 设置默认值为 100
    read -p "请输入 EXECUTOR_MAX_L3_GAS_PRICE 的值 [默认 100]: " EXECUTOR_MAX_L3_GAS_PRICE
    EXECUTOR_MAX_L3_GAS_PRICE="${EXECUTOR_MAX_L3_GAS_PRICE:-100}"

    # 设置环境变量
    export ENVIRONMENT=testnet
    export LOG_LEVEL=debug
    export LOG_PRETTY=false
    export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,unichain-sepolia,monad-testnet,optimism-sepolia,l2rn'
    export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
    export EXECUTOR_MAX_L3_GAS_PRICE="$EXECUTOR_MAX_L3_GAS_PRICE"
    export EXECUTOR_PROCESS_BIDS_ENABLED=true
    export EXECUTOR_PROCESS_ORDERS_ENABLED=true
    export EXECUTOR_PROCESS_CLAIMS_ENABLED=true
    export NETWORKS_DISABLED="blast-sepolia"
    export RPC_ENDPOINTS='{
        "l2rn": ["https://t3rn-b2n.blockpi.network/v1/rpc/public", "https://b2n.rpc.caldera.xyz/http"],
        "mont": ["https://testnet-rpc.monad.xyz"],
        "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
        "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
        "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
        "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"]
    }'

    # 提示用户输入私钥
    read -p "请输入 EVM私钥 的值: " PRIVATE_KEY_LOCAL

    # 设置私钥变量
    export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"

    # 删除压缩文件
    echo "删除压缩包..."
    rm -f executor-linux-*.tar.gz

    # 切换目录到 executor/bin
    echo "切换目录并准备使用 pm2 启动 executor..."
    cd "$EXECUTOR_DIR/executor/executor/bin" || { echo "无法切换到 executor/executor/bin 目录"; exit 1; }
    
    # 使用 pm2 启动 executor
    echo "通过 pm2 启动 executor..."
    pm2 start ./executor --name "executor" --log "$LOGFILE" --env NODE_ENV=testnet

    # 显示 pm2 进程列表
    pm2 list

    echo "executor 已通过 pm2 启动。"

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 查看日志函数
function view_logs() {
    if [ -f "$LOGFILE" ]; then
        echo "实时显示日志文件内容（按 Ctrl+C 退出）："
        tail -f "$LOGFILE"
    else
        echo "日志文件不存在。"
        read -n 1 -s -r -p "按任意键返回主菜单..."
    fi
}

# 删除节点函数
function delete_node() {
    echo "正在停止节点进程..."

    # 使用 pm2 停止和删除 executor 进程
    pm2 stop "executor" 2>/dev/null
    pm2 delete "executor" 2>/dev/null

    # 删除 executor 所在的目录
    if [ -d "$EXECUTOR_DIR" ]; then
        echo "正在删除节点目录..."
        rm -rf "$EXECUTOR_DIR"
        echo "节点目录已删除。"
    else
        echo "节点目录不存在，可能已被删除。"
    fi

    echo "节点删除操作完成。"

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 安装 v63.1.sh 函数
function install_v63_1() {
    echo "正在下载并安装 v63.1.sh..."
    wget -O v63.1.sh https://raw.githubusercontent.com/sdohuajia/t3rn/main/v63.1.sh
    if [ $? -eq 0 ]; then
        sed -i 's/\r$//' v63.1.sh
        chmod +x v63.1.sh
        ./v63.1.sh
        echo "v63.1.sh 安装成功。"
    else
        echo "v63.1.sh 下载失败，请检查网络或URL。"
    fi

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 安装 v57.sh 函数
function install_v57() {
    echo "正在下载并安装 v57.sh..."
    wget -O v57.sh https://raw.githubusercontent.com/sdohuajia/t3rn/main/v57.sh
    if [ $? -eq 0 ]; then
        sed -i 's/\r$//' v57.sh
        chmod +x v57.sh
        ./v57.sh
        echo "v57.sh 安装成功。"
    else
        echo "v57.sh 下载失败，请检查网络或URL。"
    fi

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 安装 v58.sh 函数
function install_v58() {
    echo "正在下载并安装 v58.sh..."
    wget -O v58.sh https://raw.githubusercontent.com/sdohuajia/t3rn/main/v58.sh
    if [ $? -eq 0 ]; then
        sed -i 's/\r$//' v58.sh
        chmod +x v58.sh
        ./v58.sh
        echo "v58.sh 安装成功。"
    else
        echo "v58.sh 下载失败，请检查网络或URL。"
    fi

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 安装 v59.sh 函数
function install_v59() {
    echo "正在下载并安装 v59.sh..."
    wget -O v59.sh https://raw.githubusercontent.com/sdohuajia/t3rn/main/v59.sh
    if [ $? -eq 0 ]; then
        sed -i 's/\r$//' v59.sh
        chmod +x v59.sh
        ./v59.sh
        echo "v59.sh 安装成功。"
    else
        echo "v59.sh 下载失败，请检查网络或URL。"
    fi

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 安装 v62.sh 函数
function install_v62() {
    echo "正在下载并安装 v62.sh..."
    wget -O v62.sh https://raw.githubusercontent.com/sdohuajia/t3rn/main/v62.sh
    if [ $? -eq 0 ]; then
        sed -i 's/\r$//' v62.sh
        chmod +x v62.sh
        ./v62.sh
        echo "v62.sh 安装成功。"
    else
        echo "v62.sh 下载失败，请检查网络或URL。"
    fi

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 启动主菜单
main_menu
