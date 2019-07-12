#!/bin/bash
#

HOSTN=$(awk -F' ' {'print $2'} /home/ngis/nfs/sn2hosts | cut -d'.' -f1 | xargs)			#获取sn2hosts中的主机名，并排列。
#HOSTNN=$(awk -F' ' {'print $2'} /home/ngis/nfs/sn2hosts | xargs)			
#HOSTSUM=$(cat /root/sn2host |grep -v ^$|grep -v cnw|wc -l)				
HOSTNCN=$(cat /home/ngis/nfs/sn2hosts | head -1 | awk -F' ' {'print $2'} | cut -d'.' -f2)			#获取CDN节点号。
OPTION=$*
FUNCTIONS=(
oobset
hostnameadd
synchosts
clearos
rehost
all
)

#获取帮助信息
function usage () {
	echo -e "\e[31m此脚步只能在merge1中运行，并需要merge1能正常链接到各主机，使用前请检查。\e[0m"
	echo -e "usage: \n\t $0 hostnameadd \n\t $0 oobset hostnameadd \n\t $0 all\ndiscription:\n\t oobset    用来修正没有TTY或没有OOB地址的主机，会跳过LVS和merge1。\n\t hostnameadd    用来修正服务器/etc/sysconfig/network目录下没有HOSTNAME一行的错误。\n\t synchosts    同步merge1上的hosts,resolv.conf到所有主机。 \n\t clearos    清除sn2hosts文件中的系统。 \n\t rehost    重启所有sn2hosts中的主机。  \n\t all    执行oobset,hostnameadd,synchosts。\n\t 如需执行多种功能请用空格隔开。"
}

#传输setoob.sh脚步到sn2hosts中的各主机，然后执行并重启该主机。此功能有待更新。
function oobset () {
	for host in $HOSTN; do
		#case $host in
			#lvs*)
			#	echo -e "\e[32m跳过$host，一般来说，LVS已经设置好了\e[0m"
			#	;;
			#merge1|console1)
			#	echo -e "\e[32m跳过merge1和cnosole1\e[0m"
			#	;;
			#*)	
			scp /home/ngis/added/setoob.sh $host:/tmp
			ssh $host 'sh /tmp/setoob.sh 10.120.8.X &>/dev/null &'
			echo -e "\e[31m后台执行setoob.sh，等待3秒...\e[0m"
			sleep 3
			#ssh $host 'reboot' &> /dev/null
			echo -e "\e[32m------------------等待冷重启!-------------------\e[0m"
			#;;
		#esac
	done

	echo -e "\e[41mOJBK啊OJBK\e[0m"
}

#批量重启主机。
function rehost () {
	read -p "请先确认sn2hosts文件中没有在线主机，如确认，请输入 yes ：" over

	if [[ $over == "yes" ]]; then
		for host in $HOSTN; do
			case $host in
				merge1|console1)
					echo -e "\e[32m跳过merge1和cnosole1\e[0m"
					;;
				*)
					ssh $host 'reboot' &> /dev/null
					echo -e "\e[32m重启$host!\e[0m"
					;;
			esac
		done
	else
		echo "退出!"
		exit 888
	fi
}

#检查sn2hosts各主机/etc/sysconfig/network中无HOSTNAME一行的主机，并向其中添加与主机对应的HOSTNAME。
function hostnameadd () {
	for host in $HOSTN; do
		if ssh $host "grep "HOSTNAME=\"$host\.$HOSTCN\"" /etc/sysconfig/network" &> /dev/null; then
			echo "$host,HOSTNAME已经设置。"
		else
			sed -i '/^HOSTNAME=.*/d' /etc/sysconfig/network
			ssh $host "echo HOSTNAME=\\\"$host\.$HOSTNCN\\\" >> /etc/sysconfig/network"
      		fi
	done

	echo -e "\e[41mOJBK啊OJBK\e[0m"
}

#同步hosts与resolv文件。
function synchosts () {
	for host in $HOSTN; do
		scp /etc/hosts $host:/etc/hosts
		scp /etc/resolv.conf $host:/etc/resolv.conf
	done
}

#选项检测功能。
function checkoptions () {
	if [ -z "$OPTION" ]; then
		usage
	fi

	for t in $OPTION; do
		for j in ${FUNCTIONS[@]}; do
			if [[ $t = $j ]]; then
				local test1=1
				break
			else
				local test1=2
			fi
		done
	done

	if [[ $test1 -eq 2 ]]; then
		echo -e "\e[41m输入功能中有无效功能，请联系田工(TEL:18074065988)添加!\e[0m"
		usage
		exit 999
	fi
}

#清除所有sn2hosts文件中所有主机系统。
function clearos () {
	read -p "操作危险，请确认sn2hosts文件中没有无需删除系统的设备，输入：yes 确认。" over
	if [[ $over = "yes" ]]; then
		for i in $HOSTN; do
			ssh $i 'dd if=/dev/zero of=/dev/sda bs=512k count=1'
		done
	else
		echo "退出！"
		exit 888
	fi
}

#主体运行逻辑。
function main () {
	checkoptions
	for m in $OPTION; do
		case $m in 
			oobset|OOBSET)
				oobset
				;;
			hostnameadd|HOSTNAMEADD)
				hostnameadd
				;;
			synchosts|SYNCHOSTS)
				synchosts
				;;
			clearos|CLEAROS)
				clearos
				;;
			rehost|REHOST)
				rehost
				;;
			all|ALL)
				oobset
				hostnameadd
				synchosts
				exit 0
				;;
			*)
				usage
				;;
		esac
	done
}

main
