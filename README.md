With the introduction of Document Based Replication post 8.12 in Jira https://confluence.atlassian.com/enterprise/document-based-replication-in-jira-data-center-1021214730.html , we have changed the way index replication works in Jira data center. We have increased database, network and disk usage from the prior versions of Jira. In order to understand the impact from such changes, we collect a number of statistics https://confluence.atlassian.com/jirakb/troubleshooting-performance-with-jira-stats-1041829254.html, which provide valuable information about the performance of the instance. 

The checkforme tool attempts to capture and present these statistics in a graph format for easy understanding, when a Jira engineer is troubleshooting the following in a customers instance
```
    1. Index Replication

    2. Cache Replication

    3. Network speed

    4. I/O speed
```
**Prerequisite :** 

MAC OSX :```brew install gnuplot ```

Ubuntu : ```sudo apt-get install -y gnuplot```

**Running the Script:**

Run the script in the following format. We strongly recommend running it with the date in the format provided.

```./checkforme.sh <Unzipped support folder path> <date in YYYY-MM-DD format>```

The output of the script would be a list of suggestions on what to expect from the statistics to be plotted. 
![alt text](https://github.com/shrivatsaa/Jira-performance-Statistics/blob/main/images/Script_Output.png?raw=true)

The output for each statistics would be plotted in gnuplot window separately with the threshold defined for each of the stats in the plot header.

|            |        |
:-------------------------:|:-------------------------:
![alt text](https://github.com/shrivatsaa/Jira-performance-Statistics/blob/main/images/Disk_Write_Speed.png?raw=true)  | ![alt text](https://github.com/shrivatsaa/Jira-performance-Statistics/blob/main/images/DB_Read_Speed.png?raw=true)
![alt text](https://github.com/shrivatsaa/Jira-performance-Statistics/blob/main/images/DB_Update_Speed.png?raw=true) | ![alt text](https://github.com/shrivatsaa/Jira-performance-Statistics/blob/main/images/Index_Replication_Time.png?raw=true)
![alt text](https://github.com/shrivatsaa/Jira-performance-Statistics/blob/main/images/Lucene_commit_Speed.png?raw=true)  | ![alt text](https://github.com/shrivatsaa/Jira-performance-Statistics/blob/main/images/TimeToSend_Cache.png?raw=true)
![alt text](https://github.com/shrivatsaa/Jira-performance-Statistics/blob/main/images/index_Add_Speed.png?raw=true)  | ![alt text](https://github.com/shrivatsaa/Jira-performance-Statistics/blob/main/images/DBR_Receive_Time.png?raw=true)


