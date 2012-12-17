#!/bin/bash

function usage() {
	cat << EOF
Usage: $0 <OPTIONS>
Prints iptables commands for change from chain FROM to TO
Options:
-f FROM chain (file)
-t TO chain (file)
-h Prints this help message
Example: $0 -f ipt_from -t /root/ipt 
EOF
}

while getopts "hf:t:" OPTION; do
	case $OPTION in
	h)
		usage
		exit 1
		;;
	f)
		from="$OPTARG"
		;;
	t)
		to="$OPTARG"
		;;
	*)
		echo "Invalid option"
		usage
		exit 1;
		;;
	?)
		usage
		exit 0
		;;
	esac
done

[ -n "$from" ] || { echo "No FROM chain specified"; usage; exit 1; }
[ -n "$to" ] || { echo "No TO chain specified"; usage; exit 1; }

# --- not sure if troll or working --- #
# diff --suppress-common-lines -d $from $to | while read line
# do
	# if [ "$(echo $line | cut -d' ' -f1)" == "<" ]; then
		# if [ "$(echo $line | cut -d' ' -f2)" != "-P" ]; then
			# echo $line | sed -e 's/-A /-D /' -e 's/[<>]/iptables/'
		# fi
	# elif [ "$(echo $line | cut -d' ' -f1)" == ">" ]; then
		# echo $line | sed -e 's/[<>]/iptables/'
	# fi
# done

if ! [ -t 1 ]; then
	echo $(head -1 $0)
fi

numln=$(cat $from | wc -l)
cat $to | while read line
do
	if [ "$(echo $line | grep -e '-j' -e '--jump' -e '-g' -e '--goto')" ]
	then
		if [ "$(echo $line | grep -F -e 'ACCEPT
CHECKSUM
CLASSIFY
CLUSTERIP
CONNMARK
CONNSECMARK
CT
DNAT
DROP
DSCP
ECN
IDLETIMER
IMQ
LOG
MARK
MASQUERADE
MIRROR
NETMAP
NFLOG
NFQUEUE
NOTRACK
RATEEST
REDIRECT
REJECT
SAME
SECMARK
SET
SNAT
TARPIT
TCPMSS
TCPOPTSTRIP
TEE
TOS
TPROXY
TRACE
TTL
ULOG')" ]; then
			echo "iptables $line"
			continue
		else
			echo "# --- jump or goto detected, make sure that target exists --- #"
			echo "iptables $line"
			echo "# ----------------------------------------------------------- #"
			if ! [ -t 1 ]; then
				echo "Jump or goto in TO chain, make sure that target exists" >&2
				echo ">> $line" >&2
			fi
			continue
		fi
	fi
	echo "iptables $line"
done

i=1
cat $from | while read line
do
	if [ "$i" -gt "$numln" ]; then
		exit 0
	fi
	echo "iptables -D $(echo $line | cut -d' ' -f2) $i"
	(( i++ ))
done

if ! [ -t 1 ]; then
	chmod +x /proc/$$/fd/1
fi