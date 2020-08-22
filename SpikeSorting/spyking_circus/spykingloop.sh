#!/bin/bash
source /data/usr/local/anaconda/etc/profile.d/conda.sh

conda activate circus
for i in 5 6
do
	cd /data/EphysAnalysis/cluster/AG_day2/shank$i/merged_2019-Dec-23__05-00-08_18-27-11
	spyking-circus merged_2019-Dec-23__05-00-08_18-27-11.dat -c 15
	spyking-circus merged_2019-Dec-23__05-00-08_18-27-11.dat -m converting -e merged -c 15
done
