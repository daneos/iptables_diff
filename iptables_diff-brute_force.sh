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
	testf="$(ls -l /proc/$$/fd/1 | cut -d' ' -f10).test"
	echo $(head -1 $0)
	echo $(head -1 $0) > $testf
	echo "set -e" >> $testf
	echo "chain=DIFFTEMPTEST" >> $testf
	echo "trap 'iptables -X \$chain; echo -e \"\e[1;31mAn error occured, could not add all rules to chain. Maybe some jump/goto targets do not exist?\e[00m\"' EXIT" >> $testf
	echo "iptables -N \$chain" >> $testf
fi

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
	if ! [ -t 1 ]; then
		echo "iptables $(echo $line | sed -e '/^-./ s/ [A-Za-z]* / \$chain /')" >> $testf
	fi
	echo "iptables $line"
done

numln=$(cat $from | wc -l)
cat $from | while read line
do
	if [ "$numln" == "0" ]; then
		exit 0
	fi
	echo "iptables -D $(echo $line | cut -d' ' -f2) $numln"
	(( numln-- ))
done

if ! [ -t 1 ]; then
	echo "iptables -X \$chain" >> $testf
	echo "trap - EXIT" >> $testf
	chmod +x /proc/$$/fd/1
	chmod +x $testf
fi