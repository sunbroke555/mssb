#!/bin/sh

# 如果代理变量非空，则设置 curl 命令使用代理
if [ -n "$proxy" ]; then
    CURL_COMMAND="curl --progress-bar --show-error -x $proxy -o"
else
    CURL_COMMAND="curl --progress-bar --show-error -o"
fi

# 定义一个函数来处理下载结果
download_file() {
    local url=$1
    local destination=$2
    local description=$3

    echo "## 正在更新 ${description}..."
    if $CURL_COMMAND "$destination" "$url"; then
        echo "[$(date)] ${description} 更新成功。"
    else
        echo "[$(date)] ${description} 更新失败，请检查网络连接或 URL 是否正确。"
        exit 1  # 如果下载失败，则退出脚本
    fi
}

# 开始更新 MosDNS 文件
echo "[$(date)] 开始更新 MosDNS 文件..."

download_file "https://raw.githubusercontent.com/lingkai995/geoip/refs/heads/release/apple-cn.txt" "/mssb/mosdns/apple-cn.txt" "apple-cn.txt"
download_file "https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt" "/mssb/mosdns/china_ip_list.txt" "china_ip_list.txt"
download_file "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt" "/mssb/mosdns/direct-list.txt" "direct-list.txt"
download_file "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/proxy-list.txt" "/mssb/mosdns/proxy-list.txt" "proxy-list.txt"
download_file "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/reject-list.txt" "/mssb/mosdns/reject-list.txt" "reject-list.txt"

echo "[$(date)] MosDNS 文件更新完成！"

# 重启 MosDNS 服务
echo "[$(date)] 正在通过 Supervisor 重启 MosDNS 服务..."
if supervisorctl restart mosdns; then
    echo "[$(date)] MosDNS 服务重启成功。"
else
    echo "[$(date)] MosDNS 服务重启失败，请检查 Supervisor 配置。"
    exit 1  # 如果重启失败，退出脚本
fi

# 完成更新和重启日志
echo "[$(date)] MosDNS 更新和重启流程成功完成。"
