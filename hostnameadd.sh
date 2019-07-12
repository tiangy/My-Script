#!/bin/bash
#

HOSTN=$(awk -F' ' {'print $2'} /home/ngis/nfs/sn2hosts | cut -d'.' -f1 | xargs)
#HOSTSUM=$(cat /root/sn2host |grep -v ^$|grep -v cnw|wc -l)
#HOSTCN=$(awk -F'[,|, | ]+' {'print $2'} /root/sn2host | cut -d'.' -f2 | xargs)
HOSTNCN=$(cat /home/ngis/nfs/sn2hosts | head -1 | awk -F' ' {'print $2'} | cut -d'.' -f2)

for host in $HOSTN; do
    if ssh $host 'grep "HOSTNAME=" /etc/sysconfig/network' &> /dev/null; then
	echo "$host,HOSTNAME已经设置。"
    else
        ssh $host "echo HOSTNAME=\\\"$host\.$HOSTNCN\\\" >> /etc/sysconfig/network"
        echo "修改$host完成"
    fi
done
