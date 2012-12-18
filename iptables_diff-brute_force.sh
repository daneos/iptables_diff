#!/bin/bash

function usage()
{
	cat <<- EOF
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

function gentestcode()
{
	cat <<- EOF
		set -e
		chain=DIFFTMP\$RANDOM
		trap 'iptables -X \$chain; echo \"An error occured, could not add all rules to test chain. Maybe some jump/goto targets do not exist?\"' EXIT
		iptables -N \$chain
	EOF
	sed -e '/^-./ s/ [A-Za-z]* / \$chain /' -e '/^-./ s/^-/iptables -/' $to
	cat <<- EOF
		iptables -X \$chain
		set +e
		trap - EXIT
	EOF
}

function genscript()
{
	sed -e '/^-./ s/^-/iptables -/' $to
	numln=$(wc -l < $from)
	while read line
	do
		if [ "$numln" == "0" ]; then
			exit 0
		fi
		chain=$(echo $line | cut -d' ' -f2)
		echo "iptables -D $chain $numln"
		(( numln-- ))
	done < $from
}

head -1 $0 > $dest
if [ "$gentest" ]; then
	gentestcode >> $dest
fi
genscript >> $dest
chmod +x $dest