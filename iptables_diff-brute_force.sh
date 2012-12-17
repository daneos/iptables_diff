#!/bin/bash

function usage() {
	cat << EOF
Usage: $0 <OPTIONS>
Prints iptables commands for change from chain FROM to TO
Options:
-f FROM chain (file)
-t TO chain (file)
-d destination script (file)
-T generate test
-h Prints this help message
Example: $0 -f ipt_from -t /root/ipt -d setipt.sh -T 
EOF
}

while getopts "hTf:t:d:" OPTION; do
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
	d)
		dest="$OPTARG"
		;;
	T)
		gentest=1
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
[ -n "$dest" ] || { echo "No destination specified"; usage; exit 1; }

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

echo $(head -1 $0) > $dest
destf=$(mktemp)

if [ "$gentest" ]; then
	testf=$(mktemp)
	echo "set -e" > $testf
	echo "chain=DIFFTMP\$RANDOM" >> $testf
	echo "trap 'iptables -X \$chain; echo -e \"\e[1;31mAn error occured, could not add all rules to test chain. Maybe some jump/goto targets do not exist?\e[00m\"' EXIT" >> $testf
	echo "iptables -N \$chain" >> $testf
fi

cat $to | while read line
do
	if [ "$gentest" ]; then
		echo "iptables $(echo $line | sed -e '/^-./ s/ [A-Za-z]* / \$chain /')" >> $testf
	fi
	echo "iptables $line" >> $destf
done

numln=$(cat $from | wc -l)
cat $from | while read line
do
	if [ "$numln" == "0" ]; then
		exit 0
	fi
	echo "iptables -D $(echo $line | cut -d' ' -f2) $numln"  >> $destf
	(( numln-- ))
done

if [ "$gentest" ]; then
	echo "iptables -X \$chain" >> $testf
	echo "set +e" >> $testf
	echo "trap - EXIT" >> $testf
	cat $testf >> $dest
	rm $testf
fi

cat $destf >> $dest
rm $destf
chmod +x $dest