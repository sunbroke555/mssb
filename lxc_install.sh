#!/bin/bash

# 记录当前时间
echo "[$(date)] 开始下载MosDNS..."

# 判断 CPU 架构
if [[ $(uname -m) == "aarch64" ]]; then
    TARGETARCH="arm64"
    echo "[$(date)] 检测到 CPU 架构为 arm64。"
elif [[ $(uname -m) == "x86_64" ]]; then
    TARGETARCH="amd64"
    echo "[$(date)] 检测到 CPU 架构为 amd64。"
else
    TARGETARCH="未知"
    echo "[$(date)] 无法识别的 CPU 架构：$(uname -m)，脚本退出。"
    exit 1  # 退出状态为 1，表示错误退出
fi
# 获取系统架构
TARGETARCH=$(uname -m)
LATEST_RELEASE_URL="https://github.com/IrineSistiana/mosdns/releases/latest"
LATEST_VERSION=$(curl -sL -o /dev/null -w %{url_effective} $LATEST_RELEASE_URL | awk -F '/' '{print $NF}')
MOSDNS_URL="https://github.com/IrineSistiana/mosdns/releases/download/${LATEST_VERSION}/mosdns-linux-${TARGETARCH}.zip"

# 下载最新的 MosDNS
echo "[$(date)] 正在从 $MOSDNS_URL 下载 MosDNS..."
if curl -L -o /tmp/mosdns.zip $MOSDNS_URL; then
    echo "[$(date)] MosDNS 下载成功。"
else
    echo "[$(date)] MosDNS 下载失败，请检查网络连接或 URL 是否正确。"
    exit 1
fi

# 解压并安装 MosDNS
echo "[$(date)] 正在解压 MosDNS..."
if unzip -o /tmp/mosdns.zip -d /usr/local/bin; then
    echo "[$(date)] MosDNS 解压成功。"
else
    echo "[$(date)] MosDNS 解压失败，请检查压缩包是否正确。"
    exit 1
fi

# 设置执行权限
echo "[$(date)] 正在设置 MosDNS 可执行权限..."
if chmod +x /usr/local/bin/mosdns; then
    echo "[$(date)] 设置执行权限成功。"
else
    echo "[$(date)] 设置执行权限失败，请检查文件路径和权限设置。"
    exit 1
fi

LATEST_RELEASE_URL="https://github.com/filebrowser/filebrowser/releases/latest" && \
LATEST_VERSION=$(curl -sL -o /dev/null -w %{url_effective} $LATEST_RELEASE_URL | awk -F '/' '{print $NF}') && \
DOWNLOAD_URL="https://github.com/filebrowser/filebrowser/releases/download/${LATEST_VERSION}/linux-${TARGETARCH}-filebrowser.tar.gz" && \
echo "正在下载 Filebrowser: 架构=${TARGETARCH}, 版本=${LATEST_VERSION}" && \
curl -L --fail -o /tmp/filebrowser.tar.gz $DOWNLOAD_URL && \
tar -zxvf /tmp/filebrowser.tar.gz -C /usr/local/bin && \
chmod +x /usr/local/bin/filebrowser

