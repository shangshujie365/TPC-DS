#!/bin/bash
set -e

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $PWD/../functions.sh
source_bashrc

GEN_DATA_SCALE=$1
EXPLAIN_ANALYZE=$2

if [[ "$GEN_DATA_SCALE" == "" || "$EXPLAIN_ANALYZE" == "" ]]; then
        echo "You must provide the scale as a parameter in terms of Gigabytes and true/false on running queries with EXPLAIN ANALYZE."
        echo "Example: ./rollout.sh 100 false"
        echo "This will create 100 GB of data for this test."
        exit 1
fi  

step=sql
init_log $step

for i in $(ls $PWD/*.sql); do

	id=`echo $i | awk -F '.' '{print $1}'`
	schema_name=`echo $i | awk -F '.' '{print $2}'`
	table_name=`echo $i | awk -F '.' '{print $3}'`

	echo "psql -A -q -t -P pager=off -v ON_ERROR_STOP=1 -f $i | wc -l"
	start_log
	if [ "$EXPLAIN_ANALYZE" == "false" ]; then
		tuples=$(psql -A -q -t -P pager=off -v ON_ERROR_STOP=1 -f $i | wc -l)
		#remove the extra line that \timing adds
		tuples=$(($tuples-1))
	else
		filename=$(basename $i | awk -F '.' '{print $1}')
		logfile=$PWD/../log/$filename.log
		psql -A -q -t -P pager=off -v ON_ERROR_STOP=1 -f $i 2>&1 > $logfile
		tuples="0"
	fi
	log $tuples
done

end_step $step
