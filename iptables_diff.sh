#!/bin/bash

function usage() {
	cat << EOF
Usage: $0 <OPTIONS>
Prints iptables command for change from chain FROM to TO
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

[ -n "$from" ] || { echo "No FROM chain specified" ; exit 1; }
[ -n "$to" ] || { echo "No TO chain specified" ; exit 1; }

temp=$(mktemp)
cp $from $temp

{
	diff --ed $from $to
	echo w
} | ed -s $temp

cat $from $temp | uniq -u
rm $temp