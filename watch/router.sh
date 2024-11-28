#!/bin/sh

/sbin/ip rule del fwmark 1 table 100 2>/dev/null;
/sbin/ip route del local default dev lo table 100 2>/dev/null;
/sbin/ip -6 rule del fwmark 1 table 101 2>/dev/null;
/sbin/ip -6 route del local ::/0 dev lo table 101 2>/dev/null;
/sbin/ip rule add fwmark 1 table 100;
/sbin/ip route add local default dev lo table 100;
/sbin/ip -6 rule add fwmark 1 table 101;
/sbin/ip -6 route add local ::/0 dev lo table 101