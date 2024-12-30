#!/bin/bash

# 日志输出函数
log() {
    echo "[$(date)] $1"
}

# 系统更新和软件包安装
update_system() {
    log "更新系统..."
    if ! apt update && apt -y upgrade; then
        log "系统更新失败！退出脚本。"
        exit 1
    fi

    log "安装必要的软件包..."
    if ! apt install -y supervisor inotify-tools curl git wget tar gawk sed cron unzip nano; then
        log "软件包安装失败！退出脚本。"
        exit 1
    fi
}

# 设置时区
set_timezone() {
    log "设置时区为Asia/Shanghai"
    if ! timedatectl set-timezone Asia/Shanghai; then
        log "时区设置失败！退出脚本。"
        exit 1
    fi
    log "时区设置成功"
}

# 检测系统架构
detect_architecture() {
    ARCH="amd64"
    case "$(uname -m)" in
        "aarch64")
            ARCH="arm64"
            log "检测到 CPU 架构为 arm64。"
            ;;
        "x86_64")
            ARCH="amd64"
            log "检测到 CPU 架构为 amd64。"
            ;;
        *)
            log "无法识别的 CPU 架构：$(uname -m)。脚本退出。"
            exit 1
            ;;
    esac
}

install_mosdns() {
  # 下载并安装 MosDNS
  log "开始下载 MosDNS..."
  LATEST_MOSDNS_VERSION=$(curl -sL -o /dev/null -w %{url_effective} https://github.com/IrineSistiana/mosdns/releases/latest | awk -F '/' '{print $NF}')
  MOSDNS_URL="https://github.com/IrineSistiana/mosdns/releases/download/${LATEST_MOSDNS_VERSION}/mosdns-linux-${ARCH}.zip"

  log "从 $MOSDNS_URL 下载 MosDNS..."
  if curl -L -o /tmp/mosdns.zip "$MOSDNS_URL"; then
      log "MosDNS 下载成功。"
  else
      log "MosDNS 下载失败，请检查网络连接或 URL 是否正确。"
      exit 1
  fi

  log "解压 MosDNS..."
  if unzip -o /tmp/mosdns.zip -d /usr/local/bin; then
      log "MosDNS 解压成功。"
  else
      log "MosDNS 解压失败，请检查压缩包是否正确。"
      exit 1
  fi

  log "设置 MosDNS 可执行权限..."
  if chmod +x /usr/local/bin/mosdns; then
      log "设置权限成功。"
  else
      log "设置权限失败，请检查文件路径和权限设置。"
      exit 1
  fi
}

install_filebrower() {
  # 下载并安装 Filebrowser
    log "开始下载 Filebrowser..."
    LATEST_FILEBROWSER_VERSION=$(curl -sL -o /dev/null -w %{url_effective} https://github.com/filebrowser/filebrowser/releases/latest | awk -F '/' '{print $NF}')
    FILEBROWSER_URL="https://github.com/filebrowser/filebrowser/releases/download/${LATEST_FILEBROWSER_VERSION}/linux-${ARCH}-filebrowser.tar.gz"

    log "从 $FILEBROWSER_URL 下载 Filebrowser..."
    if curl -L --fail -o /tmp/filebrowser.tar.gz "$FILEBROWSER_URL"; then
        log "Filebrowser 下载成功。"
    else
        log "Filebrowser 下载失败，请检查网络连接或 URL 是否正确。"
        exit 1
    fi

    log "解压 Filebrowser..."
    if tar -zxvf /tmp/filebrowser.tar.gz -C /usr/local/bin; then
        log "Filebrowser 解压成功。"
    else
        log "Filebrowser 解压失败，请检查压缩包是否正确。"
        exit 1
    fi

    log "设置 Filebrowser 可执行权限..."
    if chmod +x /usr/local/bin/filebrowser; then
        log "Filebrowser 设置权限成功。"
    else
        log "Filebrowser 设置权限失败，请检查文件路径和权限设置。"
        exit 1
    fi
}

check_and_copy_folder() {

    log "复制配置文件..."
    cp supervisord.conf /etc/supervisor/ || { log "复制 supervisord.conf 失败！退出脚本。"; exit 1; }
    cp -r watch / || { log "复制 watch 目录失败！退出脚本。"; exit 1; }

    # 复制 mssb/sing-box 目录
    log "复制 mssb/sing-box 目录..."
    check_and_copy_folder "fb"
    check_and_copy_folder "mosdns"
    if [ -d "/mssb/sing-box" ]; then
        log "/mssb/sing-box 目录已存在，跳过替换。"
    else
        cp -r mssb/sing-box /mssb || { log "复制 mssb/sing-box 目录失败！退出脚本。"; exit 1; }
        log "成功复制 mssb/sing-box 目录到 /mssb"
    fi



    log "设置脚本可执行权限..."
    chmod +x /watch/*.sh || { log "设置 /watch/*.sh 权限失败！退出脚本。"; exit 1; }

}

reload_service() {
  # 重启 Supervisor
    log "重启 Supervisor..."
    if ! supervisorctl stop all; then
        log "停止 Supervisor 失败！"
        exit 1
    fi
    log "Supervisor 停止成功。"
    sleep 2

    if ! supervisorctl reload; then
        log "重启 Supervisor 失败！"
        exit 1
    fi
    log "Supervisor 重启成功。"


}

# 定义定时任务的表达式和任务脚本的路径
cron_jobs=(
    # 每周一凌晨 4:00 执行更新 MosDNS 的脚本
    "0 4 * * 1 /watch/update_mosdns.sh"


    # 每周一凌晨 4:15 执行更新中国节点的脚本
    #"15 4 * * 1 /watch/update_cn.sh"
)

# 函数：将任务添加到 crontab 中

# 添加任务到 crontab
add_cron_jobs() {
    # 先删除现有的重复任务（如果存在）
    (crontab -l | grep -v -e "# update_mosdns") | crontab -

    for job in "${cron_jobs[@]}"; do
        # 检查任务是否已存在
        if (crontab -l | grep -q -F "$job"); then
            log "定时任务已存在：$job"
        else
            # 将新的任务添加到 crontab 中
            (crontab -l; echo "$job") | crontab -
            log "定时任务已成功添加：$job"
        fi
    done
}



# 主函数
main() {
    update_system
    set_timezone
    detect_architecture
    install_filebrower
    install_mosdns
    check_and_copy_folder
    reload_service
    add_cron_jobs
    log "脚本执行完成。"
}

main
