#!/bin/bash

# 检查操作类型
case "$1" in
  start)
    echo "Enabling IP forwarding..."
    sysctl -w net.ipv4.ip_forward=1
    sysctl -w net.ipv6.conf.all.forwarding=1

    echo "Adding IP rules and routes..."
    ip rule add fwmark 1 table 100
    ip route add local default dev lo table 100
    ip -6 rule add fwmark 1 table 101
    ip -6 route add local ::/0 dev lo table 101
    ;;
  stop)
    echo "Removing IP rules and routes..."
    ip rule del fwmark 1 table 100
    ip route del local default dev lo table 100
    ip -6 rule del fwmark 1 table 101
    ip -6 route del local ::/0 dev lo table 101
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac
