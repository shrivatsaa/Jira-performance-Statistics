#!/bin/sh

usage="Run the script in the format ./checkforme.sh <folder name of unzipped support.zip folder>";

FolderPath=$1;
ApplogPath=$FolderPath/application-logs
Filename=""
header=""
red=$'\e[1;31m'
green=$'\e[1;32m'
blue=$'\e[1;34m'
white=$'\e[0m'
magenta=$'\e[1;35m'
combo=$'\e[3;4m'
cyan=$'\e[1;36m'
bold=$(tput bold)
normal=$(tput sgr0)

if ! which gnuplot >/dev/null; then printf $red'You do not have gnuplot installed. Please install gnuplot and rerun the script'$white
    exit
fi

#Get the date if give or assign to the current date
if [[ $2 != "" ]] ; then {
  checkdate=$2
} 
else {
  checkdate=$(date +"%Y-%m-%d")
}
fi

PlotGraphs()
{
for FILE in $(ls $Filename); do
    Title=$(echo $FILE | awk -F "/" '{print substr($NF,5)}');
    Header=$header;
    gnuplot -persist <<- EOF
        set term qt font "Arial,12"
        set xdata time
        set timefmt "%H:%M:%S"
        set format x "%H:%M"
        set xlabel "Time"
        set ylabel "ms"
        set title "$Title"
        set grid
        set autoscale
        plot "${FILE}" u 1:2 title "${Header}" with lines
EOF
done
}

CheckDBRstat()
{

printf $magenta'Refer https://confluence.atlassian.com/jirakb/troubleshooting-performance-with-jira-stats-1041829254.html for DBR and other indexing related stats and its significance.\n\n'$white

printf $combo'Running Disk speed checks..\n'$white 

#Checking disk speed using timeToAddMillis in the cache replication stats (ideally should be ~ 1ms)
printf $green'Looking at local disk speed using cache replication stats timeToAddMillis. Output on graph titled DiskWriteSpeed.\n'$white 
printf $cyan'Ideally should be around 1ms........\n\n'$white 
grep -h "$checkdate.*Cache replication queue stats per node:" $ApplogPath/atlassian-jira.log* | grep total | awk '{print $17}' | jq '. | [.timestampMillis, .timeToAddMillis.avg] | @csv' | sed 's/"//g' | gawk -F "," '{print strftime("%Y-%m-%d %H:%M:%S",substr($1,1,10)),$2}' | awk '{print $2,$3}' | sort -nk1,2 > $ApplogPath/PlotDiskWriteSpeed
#Exit if there are no data for the current date.
if [[ $(wc -l < $ApplogPath/PlotDiskWriteSpeed) -eq 0 ]] ; then {
  echo $red'No statistics logged for the date for cache replication. Exiting. Please rerun the script with a specific date in the past after checking the logs\n'$white
  rm $ApplogPath/PlotDiskWriteSpeed
  exit
}
fi
Filename=$(pwd)/$ApplogPath/PlotDiskWriteSpeed;
header="timeToAddMillis <= 1ms";
PlotGraphs
#------------------------------------------------------------
printf $combo'Running DB performance speed checks..\n'$white 

#Check DB performance using getIssueVersionMillis to read from the database(ideally should be < 5ms)
printf $green'Looking at Index writer stats that conditionally updates index on local disk with index changes. Output on graph titled DBReadSpeed.\n'$white
printf $cyan'Measures DB read speed and should be ideally be less than 5ms.....\n\n'$white 
grep -h "$checkdate.*versioning-stats-0.*total" $ApplogPath/atlassian-jira.log* | awk '{printf "%s ",$2;{for(i=1;i<=NF;i++)if ($i ~ /getIssueVersionMillis/){print $i}}}' | sed 's/,$//g' | awk '{printf "%s ",substr($1,1,8);print $2| "jq .getIssueVersionMillis.avg";close("jq .getIssueVersionMillis.avg")}' | sort -nk1 > $ApplogPath/PlotDBReadSpeed
Filename=$(pwd)/$ApplogPath/PlotDBReadSpeed;
header="getIssueVersionMillis <= 5ms";
PlotGraphs

#Check DB performance using incrementIssueVersionMillis to update the database with DB changes(ideally should be < 10ms)
printf $green'Looking at Index writer stats that conditionally updates index on local disk with index changes. Output on graph titled DBUpdateSpeed.\n'$white
printf $cyan'Measures DB update speed and should be ideally be less than 10ms.....\n\n'$white 
grep -h "$checkdate.*versioning-stats-0.*total" $ApplogPath/atlassian-jira.log* | awk '{printf "%s ",$2;{for(i=1;i<=NF;i++)if ($i ~ /incrementIssueVersionMillis/){print $i}}}' | sed 's/,$//g' | awk '{printf "%s ",substr($1,1,8);print $2| "jq .incrementIssueVersionMillis.avg";close("jq .incrementIssueVersionMillis.avg")}' | sort -nk1 > $ApplogPath/PlotDBUpdateSpeed
Filename=$(pwd)/$ApplogPath/PlotDBUpdateSpeed;
header="incrementIssueVersionMillis <= 10ms";
PlotGraphs
#------------------------------------------------------------
printf $combo'Running internode network latency checks..\n'$white 

#Checking network latency using timeToSendMillis in the cache replication stats (ideally should be < 10ms)
printf $green'Looking at lnetwork latency using timeToSendMillis. Output on graph titled TimetoSendCacheChanges.\n'$white 
printf $cyan'Ideally should be around 10ms........\n\n'$white 
grep -h "$checkdate.*VIA-INVALIDATION.*Cache replication queue stats per node:" $ApplogPath/atlassian-jira.log* | grep total | awk '{print $17}' | jq '. | [.timestampMillis, .timeToSendMillis.avg] | @csv' | sed 's/"//g' | gawk -F "," '{print strftime("%Y-%m-%d %H:%M:%S",substr($1,1,10)),$2}' | awk '{print $2,$3}' | sort -nk1,2 > $ApplogPath/PlotTimetoSendCacheChanges
Filename=$(pwd)/$ApplogPath/PlotTimetoSendCacheChanges;
header="timeToSendMillis <= 10ms";
PlotGraphs

#Checking disk, network and index commit speed (ideally should be < 100ms)
printf $green'Looking at receiveDBRMessageDelayedInMillis that measures serialization/de-serialization + time spend in the LocalQ + time to send the message from another node.\n'$white 
printf $cyan'Output on graph titled DBRReceiveTime and should be ideally be less than 100ms.....\n\n'$white 
grep -h "$checkdate.*TotalAndSnapshotDBRReceiverStats.*total" $ApplogPath/atlassian-jira.log* | awk '{printf "%s ",$2;{for(i=1;i<=NF;i++)if ($i ~ /receiveDBRMessage/){print $i}}}' | awk '{printf "%s ",substr($1,1,8);print $2| "jq .receiveDBRMessageDelayedInMillis.avg";close("jq .receiveDBRMessageDelayedInMillis.avg")}' | sort -nk1 > $ApplogPath/PlotDBRReceiveTime
Filename=$(pwd)/$ApplogPath/PlotDBRReceiveTime;
header="receiveDBRMessageDelayedInMillis <= 100ms";
PlotGraphs
#------------------------------------------------------------
printf $combo'Running Lucene Read/write performance checks....\n'$white 

#Check disk speed using updateDocumentsWithVersionMillis to write to index the document changes (ideally should be < 50ms)
printf $green'Looking at Index writer stats that conditionally updates index on local disk with index changes. Output on graph titled IndexAddSpeed.\n'$white
printf $cyan'Measures I/O and should be ideally be less than 50ms.....\n\n'$white 
grep -h "$checkdate.*index-writer-stats-ISSUE.*total" $ApplogPath/atlassian-jira.log* | awk '{printf "%s ",$2;{for(i=1;i<=NF;i++)if ($i ~ /addDocumentsMillis/){print $i}}}' | sed 's/,$//g' | awk '{printf "%s ",substr($1,1,8);print $2| "jq .updateDocumentsWithVersionMillis.avg";close("jq .updateDocumentsWithVersionMillis.avg")}' | sort -nk1 > $ApplogPath/PlotIndexAddSpeed
Filename=$(pwd)/$ApplogPath/PlotIndexAddSpeed;
header="updateDocumentsWithVersionMillis <= 50ms";
PlotGraphs

#Checking disk, network and index commit speed ((ideally should be < 150ms))
printf $green'Looking at TotalAndSnapshotDBRReceiverStats that measures conditional index updates on remote disk with index changes. Output on graph titled LuceneCommitSpeed.\n'$white
printf $cyan'Measures I/O and should be ideally be less than 150ms.....\n\n'$white 
grep -h "$checkdate.*TotalAndSnapshotDBRReceiverStats.*total" $ApplogPath/atlassian-jira.log* | awk '{printf "%s ",$2;{for(i=1;i<=NF;i++)if ($i ~ /receiveDBRMessage/){print $i}}}' | awk '{printf "%s ",substr($1,1,8);print $2| "jq .processDBRMessageUpdateWithRelatedIndexInMillis.avg";close("jq .processDBRMessageUpdateWithRelatedIndexInMillis.avg")}' | sort -nk1 > $ApplogPath/PlotLuceneCommitSpeed
Filename=$(pwd)/$ApplogPath/PlotLuceneCommitSpeed;
header="processDBRMessageUpdateWithRelatedIndexInMillis <= 150ms";
PlotGraphs
#------------------------------------------------------------
printf $combo'Running DBR and DBR efficiency checks....\n'$white 

#Check Document based replication related statistics
printf $green'Looking at Index writer stats that logs the indexes that were handled by DBR. Output on graph titled PlotDBRStat.\n'$white
printf $cyan'Measures DBR efficiency and should be ideally be more than 90 percent .....\n\n'$white 
grep -h "$checkdate.*NodeReindexServiceThread.*INFO.*INDEX-REPLAY.*total" $ApplogPath/atlassian-jira.log* | awk '{print $2,$15,$16}' | while read line; do printf "%s %s\n" "$(echo $line | awk '{print substr($1,1,8)}')" "$(echo $line |awk '{print $2,$3}' | jq -r ".|[.timeInMillis.avg,.updateIndexInMillis.ISSUE.avg,.filterOutAlreadyIndexedBeforeCounter.ISSUE.sum,.filterOutAlreadyIndexedAfterCounter.ISSUE.sum] | @tsv" | awk '{if ($3=="") {$3=1;$4=1}}{printf "%s %s %s",$1/100,$2/100,(1-($4/$3))*100}')";done | sort -k1,2 > $ApplogPath/PlotDBRStat
header="DBR Efficiency >= 90";
Filename=$(pwd)/$ApplogPath/PlotDBRStat

for FILE in $(ls $Filename); do
    Header=$header;
    gnuplot -persist <<- EOF
        set term qt font "Arial,12"
        set xdata time
        set timefmt "%H:%M:%S"
        set format x "%H:%M"
        set xlabel "Time"
        set ylabel "Percent"
        set title "DBR Efficiency"
        set grid
        set autoscale
        plot "${FILE}" using 1:4 title "${Header}" with lines
EOF
done

printf $green'Looking at Time to process and time to update index from the index replication stats run every 5 minutes.\n'$white
printf $cyan'Time to process the batch and update the index should be both under 5 seconds .....\n\n'$white 

for FILE in $(ls $Filename); do
    gnuplot -persist <<- EOF
        set term qt font "Arial,12"
        set xdata time
        set timefmt "%H:%M:%S"
        set format x "%H:%M"
        set xlabel "Time"
        set ylabel "Sec"
        set title "Index Replication Time"
        set grid
        set autoscale
        plot "${FILE}" using 1:2 title "timeInMillis <= 5s" with lines, "${FILE}" using 1:3 title "updateIndexInMillis <= 5s" with lines

EOF
done
}

CheckDBRstat

#Clean up the created data files
rm $ApplogPath/Plot* > /dev/null

exit

 