#!/bin/bash -e
#
# This script processes a list of domains to check which nameservers
# are used. If a list of IPs is given it will also check if the
# IPs are pointing to the domain or not.
#

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' #no color

trap ctrl_c INT

function ctrl_c {
	echo
	echo "Aborted! Doing some cleanup..."
	rm -rfv ns/
	rm -fv fetch_*_result.txt
	rm -fv duplicate_domains.txt
	exit 1
}

function checkFileExist {
	if [ ! -e "$1" ] ; then
		echo "File '${1}' doesn't exist";
		exit 1
	fi
}

function linecount {
	wc -l "$1"|cut -d' ' -f1
}

function filecleanup (){

	#check for empty lines and remove them
	grep -qc '^$' "$DOMAINS_LIST" && sed -i '/^$/d' "$DOMAINS_LIST" && echo -e "${RED}[Cleanup]${NC} Removed blank lines from $DOMAINS_LIST"

	#check if the file is sorted propertly if not, do so
	sort --check=quiet "$DOMAINS_LIST" || ( sort "$DOMAINS_LIST" --output "$DOMAINS_LIST" && echo -e "${RED}[Cleanup]${NC} Sorted $DOMAINS_LIST" )

	#check for dupes and remove them
	uniques=$(uniq -cd "$DOMAINS_LIST")
	if [ ! -z "$uniques" ]
	then
		sort --unique "$DOMAINS_LIST" --output "$DOMAINS_LIST"
		echo "$uniques" >> duplicate_domains.txt
		echo -e "${RED}[Cleanup]${NC} Removed duplicates: $(linecount duplicate_domains.txt) (see duplicate_domains.txt for a list)"
	fi

}

function fetchDNSrecords {
	TYPE=$1
	DOMAINS_LIST=$2
	if [ ! -e fetch_"$TYPE"_result.txt ]; then
		echo "Scanning $(linecount "$DOMAINS_LIST") domains for $TYPE records..."
		while IFS= read -r domain
		do
			dig "$TYPE" +noall +answer "$domain" >> fetch_"$TYPE"_result.txt &
		done < "$DOMAINS_LIST"
		wait
	else
		echo "Found fetch_${TYPE}_result.txt, using as cache"
	fi
}

function analyseRecords {
	recordtype=$1
	case $recordtype in
		NS|ns)
			rm -rf NS/*
			mkdir -p NS
			while IFS= read -r domain
			do
				if grep -qcw "$domain" fetch_NS_result.txt;
				then
					echo "$domain" >> NS/resolving_domains.txt
					echo "$domain" >> "NS/$(grep -w "$domain" fetch_NS_result.txt|awk '{print $5}'|awk -F. '{print $2}'|sort|uniq).domainlist"

				else
					echo "$domain" >> NS/non_resolving_domains.txt
				fi

			done < "$DOMAINS_LIST"
			wait

			echo "Nameserver distribution:"
			wc -l NS/*.domainlist
			;;

		A|a)
			rm -rf A/*
			mkdir -p A
			grep -f "$IPS_LIST" fetch_A_result.txt >> A/aligned_domains.txt
			grep -vf "$IPS_LIST" fetch_A_result.txt >> A/unaligned_domains.txt
			;;

		AAAA|aaaa)
			rm -rf AAAA/*
			grep -f "$IPV6_LIST" fetch_AAAA_result.txt >> AAAA/aligned_IPV6_domains.txt
			grep -vf "$IPV6_LIST" fetch_AAAA_result.txt >> AAAA/unaligned_IPV6_domains.txt
			;;
	esac
}

function match_WWW_to_non_WWW {
	echo todo
}

function printSummary {
	echo -e "Resolving domains    : ${GREEN}$(linecount NS/resolving_domains.txt)${NC}"
	if [ -e NS/non_resolving_domains.txt ]; then
		echo -e "Non-resolving domains: ${RED}$(linecount NS/non_resolving_domains.txt)${NC}"
	fi

	if [ -e A/aligned_domains.txt ]; then
		echo -e "Aligned IPV4 domains: ${GREEN}$(linecount A/aligned_domains.txt)${NC}"
	fi
	if [ -e A/unaligned_domains.txt ]; then
		echo -e "Unaligned IPV4 domains: ${RED}$(linecount A/unaligned_domains.txt)${NC}"
	fi
	if [ -e AAAA/aligned_IPV6_domains.txt ]; then
		echo -e "Aligned IPV6 domains: ${GREEN}$(linecount AAAA/aligned_IPV6_domains.txt)${NC}"
	fi
	if [ -e AAAA/unaligned_IPV6_domains.txt ]; then
		echo -e "Unaligned IPV6 domains: ${RED}$(linecount AAAA/aligned_IPV6_domains.txt)${NC}"
	fi
	#do a checksum
	nstotal=$(wc -l NS/*.domainlist|grep total|awk '{print $1}')
	resolvingtotal=$(linecount NS/resolving_domains.txt)
	if [ "$nstotal" != "$resolvingtotal" ]; then
		echo "Checksum not okay, results may be inaccurate!"
	else
		echo "Checksum Ok!"
	fi

}

#Handle parameters
while [[ $# -gt 1 ]]
do
	key="$1"

	case $key in
		-d|--domainslist)
			DOMAINS_LIST="$2"
			checkFileExist "$DOMAINS_LIST"
			shift # past argument
			;;
		-i|--ipslist)
			IPS_LIST="$2"
			checkFileExist "$IPS_LIST"
			shift # past argument
			;;
		-6|--ipv6list)
			IPV6_LIST="$2"
			checkFileExist "$IPS_LIST"
			shift # past argument
			;;
		-w|--match-www)
			#todo
			shift # past argument
			;;
		*)
			echo unknown option
			;;
	esac
	shift # past argument or value
done

if [[ -n $1 ]]; then
	echo "Last line of file specified as non-opt/last argument:"
	exit 1
fi

if [ -z "$DOMAINS_LIST" ]; then
	echo "A list of domains is required, use -d or --domainslist to specify a file"
	exit 1
else
	filecleanup "$DOMAINS_LIST"
	fetchDNSrecords NS "$DOMAINS_LIST"
	analyseRecords NS
	if [ ! -z "$IPS_LIST" ]; then
		fetchDNSrecords A NS/resolving_domains.txt
		analyseRecords A
	fi
	if [ ! -z "$IPV6_LIST" ]; then
		fetchDNSrecords AAAA NS/resolving_domains.txt
		analyseRecords AAAA
	fi
	printSummary
fi

