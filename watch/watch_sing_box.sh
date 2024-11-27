#!/bin/bash

# 需要监听的目录
CONFIG_DIR="/mssb/sing-box"

# 使用 inotifywait 监听特定文件类型的变动
while true; do
  inotifywait -e modify,create,delete -r $CONFIG_DIR --include '.*\.(txt|yaml|json|srs|yml)$'
  echo "Sing-box 配置文件发生变化，重启 Sing-box 服务..."

  # 通过 supervisorctl 重启 Sing-box 服务
  supervisorctl restart sing-box
done
