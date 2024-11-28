#!/bin/bash

# 定义操作类型：start 或 stop
ACTION=$1

# 定义规则函数
add_rules() {
    echo "添加 TProxy 路由规则..."
    /sbin/ip rule add fwmark 1 table 100
    /sbin/ip route add local default dev lo table 100
    /sbin/ip -6 rule add fwmark 1 table 101
    /sbin/ip -6 route add local ::/0 dev lo table 101
    echo "TProxy 路由规则已添加。"
}

delete_rules() {
    echo "删除 TProxy 路由规则..."
    /sbin/ip rule del fwmark 1 table 100
    /sbin/ip route del local default dev lo table 100
    /sbin/ip -6 rule del fwmark 1 table 101
    /sbin/ip -6 route del local ::/0 dev lo table 101
    echo "TProxy 路由规则已删除。"
}

# 根据操作执行对应命令
case "$ACTION" in
    start)
        add_rules
        ;;
    stop)
        delete_rules
        ;;
    restart)
        delete_rules
        sleep 1
        add_rules
        ;;
    *)
        echo "用法: $0 {start|stop|restart}"
        exit 1
        ;;
esac
