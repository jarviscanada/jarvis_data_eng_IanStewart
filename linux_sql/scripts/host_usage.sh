#!/bin/bash

psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

export PGPASSWORD=$psql_password 
# Check # of args
if [ "$#" -ne 5 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

vmstat_mb=$(vmstat --unit M -t)
hostname=$(hostname -f)

memory_free=$(echo "$vmstat_mb" | tail -1 | awk -v col="4" '{print $col}')
cpu_idle=$(echo "$vmstat_mb" | tail -1 | awk -v col="15" '{print $col}')
cpu_kernel=$(echo "$vmstat_mb" | tail -1 | awk -v col="14" '{print $col}')
disk_io=$(vmstat --unit M -d | tail -1 | awk -v col="10" '{print $col}')
disk_available=$(df -h /home | egrep "^/dev/sda2" | awk '{print $4}'| awk '{print substr($0, 1, length-1)}')
timestamp=$(echo "$vmstat_mb" | tail -1 | awk '{print $18, $19}')

host_id_col=$(psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "(SELECT id FROM host_info WHERE hostname='$hostname')")
host_id=$(echo "$host_id_col" | tail -1 | awk '{print $1}' | cut -c2- | xargs)

insert_stmt="INSERT INTO host_usage(timestamp, host_id, memory_free, cpu_idle, cpu_kernel, disk_io, disk_available ) VALUES('$timestamp', '$host_id', '$memory_free', '$cpu_idle', '$cpu_kernel', '$disk_io', '$disk_available')"


psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"
exit $?
