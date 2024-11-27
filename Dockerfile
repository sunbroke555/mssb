# 使用 Alpine 基础镜像
FROM alpine:3.18
USER root

# 安装必要的工具和 tzdata 来配置时区
RUN apk update && \
    apk add --no-cache \
    ca-certificates iproute2 curl git wget lsof tar gawk sed unzip nano nftables procps inotify-tools tzdata bash dcron supervisor && \
    rm -rf /var/cache/apk/*

# 设置时区为 Asia/Shanghai
RUN ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

# 设置环境变量 TZ 为 Asia/Shanghai
ENV TZ=Asia/Shanghai

# 设置工作目录
WORKDIR /mssb
ARG TARGETARCH
# TAG 值，根据 TARGETARCH 设置为不同的值
# 下载并安装 MosDNS
RUN LATEST_RELEASE_URL="https://github.com/IrineSistiana/mosdns/releases/latest" && \
    LATEST_VERSION=$(curl -sL -o /dev/null -w %{url_effective} $LATEST_RELEASE_URL | awk -F '/' '{print $NF}') && \
    DOWNLOAD_URL="https://github.com/IrineSistiana/mosdns/releases/download/${LATEST_VERSION}/mosdns-linux-${TARGETARCH}.zip" && \
    echo "正在下载 MosDNS: 架构=${TARGETARCH}, 版本=${LATEST_VERSION}" && \
    curl -L --fail -o /tmp/mosdns.zip $DOWNLOAD_URL && \
    unzip -o /tmp/mosdns.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/mosdns && \
    rm -rf /tmp/*

# 下载并安装 Sing-box
RUN TAG=$([ "$TARGETARCH" = "arm64" ] && echo "armv8" || echo "$TARGETARCH") && \
    SING_BOX_URL="https://raw.githubusercontent.com/herozmy/herozmy-private/main/sing-box-puernya/sing-box-linux-${TAG}.tar.gz" && \
    echo "正在下载 Sing-box: 架构=${TARGETARCH}, 标签=${TAG}" && \
    wget -O /tmp/sing-box.tar.gz $SING_BOX_URL && \
    tar -zxvf /tmp/sing-box.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/sing-box && \
    rm -rf /tmp/*

# 下载并安装 Filebrowser
RUN LATEST_RELEASE_URL="https://github.com/filebrowser/filebrowser/releases/latest" && \
    LATEST_VERSION=$(curl -sL -o /dev/null -w %{url_effective} $LATEST_RELEASE_URL | awk -F '/' '{print $NF}') && \
    DOWNLOAD_URL="https://github.com/filebrowser/filebrowser/releases/download/${LATEST_VERSION}/linux-${TARGETARCH}-filebrowser.tar.gz" && \
    echo "正在下载 Filebrowser: 架构=${TARGETARCH}, 版本=${LATEST_VERSION}" && \
    curl -L --fail -o /tmp/filebrowser.tar.gz $DOWNLOAD_URL && \
    tar -zxvf /tmp/filebrowser.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/filebrowser && \
    rm -rf /tmp/*

# 复制配置文件和脚本
COPY mssb /mssb/
COPY watch /watch/
# 给予监听脚本可执行权限
RUN chmod +x /watch/watch_mosdns.sh /watch/watch_sing_box.sh /watch/update_mosdns.sh /watch/update_sb.sh /watch/update_cn.sh
# 添加 cron 任务，/etc/cron.d
RUN echo "0 4 * * 1 root /watch/update_mosdns.sh >> /dev/stdout 2>&1" > /etc/cron.d/update_file && \
    echo "10 4 * * 1 root /watch/update_sb.sh >> /dev/stdout 2>&1" >> /etc/cron.d/update_file && \
    echo "15 4 * * 1 root /watch/update_cn.sh >> /dev/stdout 2>&1" >> /etc/cron.d/update_file && \
    chmod 0644 /etc/cron.d/update_file
# 应用 cron 配置
RUN crontab -l | cat - /etc/cron.d/update_file | crontab -
# 配置 supervisord 文件
COPY supervisord.conf /etc/supervisord.conf
# 暴露端口
EXPOSE 53/tcp 53/udp 6666/tcp 6666/udp 9090/tcp 8080/tcp 8088/tcp 7891/tcp
# 设置 supervisord 为默认启动命令
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
