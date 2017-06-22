#!/bin/bash
#
# stefanhr@nyherji.is 26.10.2016
#
# This script generates another script that loops through all directory type storagepools
# and generates dedupstats for nodes that store data in that pool.
#
# You need to fill in ISP system administrator info below.
# The sleep variable causes n seconds delay between every generate dedupstats run.
#
userid=
password=
sleep=15

if [ "$userid" = "" ] || [ "$password" = "" ]; then
     echo "ISP(TSM) admin user or password not set!!!!!!"
     exit
fi

/usr/bin/dsmadmc -id=$userid -pass=$password  -dataonly=yes "q db" > /dev/null
retval=$?
if [ $retval -ne 0 ]; then
     echo "Could not connect to IPS(TSM) server with supplied username/password!"
     exit
fi

dsmadmc -id=$userid -pass=$password -dataonly=yes "select STGPOOL_NAME from stgpools where (stg_type='DIRECTORY' or stg_type='CLOUD') and POOLTYPE='PRIMARY'" > /tmp/stgpools.list.$$
for i in `cat /tmp/stgpools.list.$$`; do
dsmadmc -id=$userid -pass=$password -dataonly=yes -commad "select STGPOOL_NAME,NODE_NAME from occupancy where STGPOOL_NAME='$i' and NODE_NAME!=''" >> /tmp/stgpool_node.list.$$
done

cat /tmp/stgpool_node.list.$$ | sort -u > /tmp/stgpool_node.sorted.$$

echo > /tmp/generate_dedupstats.sh
chmod 700 /tmp/generate_dedupstats.sh

for i in `cat /tmp/stgpool_node.sorted.$$`; do
echo $i ,$userid,$password | awk -F"," '{print "dsmadmc -id=" $3 " -pass=" $4 "  \"generate dedupstats " $1 " " $2 "\""}'  >> /tmp/generate_dedupstats.sh
echo sleep $sleep >> /tmp/generate_dedupstats.sh
done

echo "The generate_dedupstats.sh script is ready, please audit the script before running!!!!"

# Remove remark on next two lines to run generate_dedupstats.sh without audit
# /tmp/generate_dedupstats.sh
# rm /tmp/generate_dedupstats.sh

rm /tmp/stgpools.list.$$
rm /tmp/stgpool_node.list.$$
rm /tmp/stgpool_node.sorted.$$
