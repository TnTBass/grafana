#!/bin/bash
##      .SYNOPSIS
##      Grafana Dashboard for Veeam Enterprise Manager v9.5 U4 - Using RestAPI to InfluxDB Script
## 
##      .DESCRIPTION
##      This Script will query the Veeam Enterprise Manager RestAPI and send the data directly to InfluxDB, which can be used to present it to Grafana. 
##      The Script and the Grafana Dashboard it is provided as it is, and bear in mind you can not open support Tickets regarding this project. It is a Community Project
##	
##      .Notes
##      NAME:  veeam_enterprisemanager.sh
##      ORIGINAL NAME: veeam_enterprisemanager.sh
##      LASTEDIT: 03/01/2020
##      VERSION: 1.0
##      KEYWORDS: Veeam, InfluxDB, Grafana
   
##      .Link
##      https://jorgedelacruz.es/
##      https://jorgedelacruz.uk/

##
# Configurations
##
# Endpoint URL for InfluxDB
veeamInfluxDBURL="http://YOURINFLUXSERVERIP" #Your InfluxDB Server, http://FQDN or https://FQDN if using SSL
veeamInfluxDBPort="8086" #Default Port
veeamInfluxDB="telegraf" #Default Database
veeamInfluxDBUser="USER" #User for Database
veeamInfluxDBPassword="PASSWORD" #Password for Database

# Endpoint URL for login action
veeamUsername="YOUREMUSER" #Your username, if using domain based account, please add it like user@domain.com (if you use domain\account it is not going to work!)
veeamPassword="YOUREMPASSWORD"
veeamAuth=$(echo -ne "$veeamUsername:$veeamPassword" | base64);
veeamRestServer="YOUREMSERVERIP"
veeamRestPort="9398" #Default Port
veeamSessionId=$(curl -X POST "https://$veeamRestServer:$veeamRestPort/api/sessionMngr/?v=latest" -H "Authorization:Basic $veeamAuth" -H "Content-Length: 0" -H "Accept: application/json" -k --silent | awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1' | jq --raw-output ".SessionId")
veeamXRestSvcSessionId=$(echo -ne "$veeamSessionId" | base64);

##
# Veeam Enterprise Manager Overview. Overview of Backup Infrastructure and Job Status
##
veeamEMUrl="https://$veeamRestServer:$veeamRestPort/api/reports/summary/overview"
veeamEMOUrl=$(curl -X GET "$veeamEMUrl" -H "Accept:application/json" -H "X-RestSvcSessionId: $veeamXRestSvcSessionId" -H "Cookie: X-RestSvcSessionId=$veeamXRestSvcSessionId" -H "Content-Length: 0" 2>&1 -k --silent | awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1')

    veeamBackupServers=$(echo "$veeamEMOUrl" | jq --raw-output ".BackupServers")
    veeamProxyServers=$(echo "$veeamEMOUrl" | jq --raw-output ".ProxyServers")    
    veeamRepositoryServers=$(echo "$veeamEMOUrl" | jq --raw-output ".RepositoryServers")
    veeamRunningJobs=$(echo "$veeamEMOUrl" | jq --raw-output ".RunningJobs")    
    veeamScheduledJobs=$(echo "$veeamEMOUrl" | jq --raw-output ".ScheduledJobs")
    veeamSuccessfulVmLastestStates=$(echo "$veeamEMOUrl" | jq --raw-output ".SuccessfulVmLastestStates")    
    veeamWarningVmLastestStates=$(echo "$veeamEMOUrl" | jq --raw-output ".WarningVmLastestStates")
    veeamFailedVmLastestStates=$(echo "$veeamEMOUrl" | jq --raw-output ".FailedVmLastestStates")
    
    #echo "veeam_em_overview,host=$veeamRestServer veeamBackupServers=$veeamBackupServers,veeamProxyServers=$veeamProxyServers,veeamRepositoryServers=$veeamRepositoryServers,veeamRunningJobs=$veeamRunningJobs,veeamScheduledJobs=$veeamScheduledJobs,veeamSuccessfulVmLastestStates=$veeamSuccessfulVmLastestStates,veeamWarningVmLastestStates=$veeamWarningVmLastestStates,veeamFailedVmLastestStates=$veeamFailedVmLastestStates"
    curl -i -XPOST "$veeamInfluxDBURL:$veeamInfluxDBPort/write?precision=s&db=$veeamInfluxDB" -u "$veeamInfluxDBUser:$veeamInfluxDBPassword" --data-binary "veeam_em_overview,host=$veeamRestServer veeamBackupServers=$veeamBackupServers,veeamProxyServers=$veeamProxyServers,veeamRepositoryServers=$veeamRepositoryServers,veeamRunningJobs=$veeamRunningJobs,veeamScheduledJobs=$veeamScheduledJobs,veeamSuccessfulVmLastestStates=$veeamSuccessfulVmLastestStates,veeamWarningVmLastestStates=$veeamWarningVmLastestStates,veeamFailedVmLastestStates=$veeamFailedVmLastestStates"

##
# Veeam Enterprise Manager Overview. Overview of Virtual Machines
##
veeamEMUrl="https://$veeamRestServer:$veeamRestPort/api/reports/summary/vms_overview"
veeamEMOVMUrl=$(curl -X GET "$veeamEMUrl" -H "Accept:application/json" -H "X-RestSvcSessionId: $veeamXRestSvcSessionId" -H "Cookie: X-RestSvcSessionId=$veeamXRestSvcSessionId" -H "Content-Length: 0" 2>&1 -k --silent | awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1')

    veeamProtectedVms=$(echo "$veeamEMOVMUrl" | jq --raw-output ".ProtectedVms")
    veeamBackedUpVms=$(echo "$veeamEMOVMUrl" | jq --raw-output ".BackedUpVms")    
    veeamReplicatedVms=$(echo "$veeamEMOVMUrl" | jq --raw-output ".ReplicatedVms")
    veeamRestorePoints=$(echo "$veeamEMOVMUrl" | jq --raw-output ".RestorePoints")    
    veeamFullBackupPointsSize=$(echo "$veeamEMOVMUrl" | jq --raw-output ".FullBackupPointsSize")
    veeamIncrementalBackupPointsSize=$(echo "$veeamEMOVMUrl" | jq --raw-output ".IncrementalBackupPointsSize")    
    veeamReplicaRestorePointsSize=$(echo "$veeamEMOVMUrl" | jq --raw-output ".ReplicaRestorePointsSize")
    veeamSourceVmsSize=$(echo "$veeamEMOVMUrl" | jq --raw-output ".SourceVmsSize")    
    veeamSuccessBackupPercents=$(echo "$veeamEMOVMUrl" | jq --raw-output ".SuccessBackupPercents")
    
    #echo "veeam_em_overview_vms,host=$veeamRestServer veeamProtectedVms=$veeamProtectedVms,veeamBackedUpVms=$veeamBackedUpVms,veeamReplicatedVms=$veeamReplicatedVms,veeamRestorePoints=$veeamRestorePoints,veeamFullBackupPointsSize=$veeamFullBackupPointsSize,veeamIncrementalBackupPointsSize=$veeamIncrementalBackupPointsSize,veeamReplicaRestorePointsSize=$veeamReplicaRestorePointsSize,veeamSourceVmsSize=$veeamSourceVmsSize,veeamSuccessBackupPercents=$veeamSuccessBackupPercents"
    curl -i -XPOST "$veeamInfluxDBURL:$veeamInfluxDBPort/write?precision=s&db=$veeamInfluxDB" -u "$veeamInfluxDBUser:$veeamInfluxDBPassword" --data-binary "veeam_em_overview_vms,host=$veeamRestServer veeamProtectedVms=$veeamProtectedVms,veeamBackedUpVms=$veeamBackedUpVms,veeamReplicatedVms=$veeamReplicatedVms,veeamRestorePoints=$veeamRestorePoints,veeamFullBackupPointsSize=$veeamFullBackupPointsSize,veeamIncrementalBackupPointsSize=$veeamIncrementalBackupPointsSize,veeamReplicaRestorePointsSize=$veeamReplicaRestorePointsSize,veeamSourceVmsSize=$veeamSourceVmsSize,veeamSuccessBackupPercents=$veeamSuccessBackupPercents"

##
# Veeam Enterprise Manager Overview. Overview of Job Statistics
##
veeamEMUrl="https://$veeamRestServer:$veeamRestPort/api/reports/summary/job_statistics"
veeamEMOJobUrl=$(curl -X GET "$veeamEMUrl" -H "Accept:application/json" -H "X-RestSvcSessionId: $veeamXRestSvcSessionId" -H "Cookie: X-RestSvcSessionId=$veeamXRestSvcSessionId" -H "Content-Length: 0" 2>&1 -k --silent | awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1')

    veeamRunningJobs=$(echo "$veeamEMOJobUrl" | jq --raw-output ".RunningJobs")
    veeamScheduledJobs=$(echo "$veeamEMOJobUrl" | jq --raw-output ".ScheduledJobs")    
    veeamScheduledBackupJobs=$(echo "$veeamEMOJobUrl" | jq --raw-output ".ScheduledBackupJobs")
    veeamScheduledReplicaJobs=$(echo "$veeamEMOJobUrl" | jq --raw-output ".ScheduledReplicaJobs")    
    veeamTotalJobRuns=$(echo "$veeamEMOJobUrl" | jq --raw-output ".TotalJobRuns")
    veeamSuccessfulJobRuns=$(echo "$veeamEMOJobUrl" | jq --raw-output ".SuccessfulJobRuns")    
    veeamWarningsJobRuns=$(echo "$veeamEMOJobUrl" | jq --raw-output ".WarningsJobRuns")
    veeamFailedJobRuns=$(echo "$veeamEMOJobUrl" | jq --raw-output ".FailedJobRuns")    
    veeamMaxJobDuration=$(echo "$veeamEMOJobUrl" | jq --raw-output ".MaxJobDuration")    
    veeamMaxBackupJobDuration=$(echo "$veeamEMOJobUrl" | jq --raw-output ".MaxBackupJobDuration")    
    veeamMaxReplicaJobDuration=$(echo "$veeamEMOJobUrl" | jq --raw-output ".MaxReplicaJobDuration")
    veeamMaxDurationBackupJobName=$(echo "$veeamEMOJobUrl" | jq --raw-output ".MaxDurationBackupJobName" | awk '{gsub(/ /,"\\ ");print}')
    [[ ! -z "$veeamMaxDurationBackupJobName" ]] || veeamMaxDurationBackupJobName="None"
    veeamMaxDurationReplicaJobName=$(echo "$veeamEMOJobUrl" | jq --raw-output ".MaxDurationReplicaJobName" | awk '{gsub(/ /,"\\ ");print}')
    [[ ! -z "$veeamMaxDurationReplicaJobName" ]] || veeamMaxDurationReplicaJobName="None"
    
    #echo "veeam_em_overview_jobs,host=$veeamRestServer,veeamMaxDurationBackupJobName=$veeamMaxDurationBackupJobName,veeamMaxDurationReplicaJobName=$veeamMaxDurationReplicaJobName veeamRunningJobs=$veeamRunningJobs,veeamScheduledJobs=$veeamScheduledJobs,veeamScheduledBackupJobs=$veeamScheduledBackupJobs,veeamScheduledReplicaJobs=$veeamScheduledReplicaJobs,veeamTotalJobRuns=$veeamTotalJobRuns,veeamSuccessfulJobRuns=$veeamSuccessfulJobRuns,veeamWarningsJobRuns=$veeamWarningsJobRuns,veeamFailedJobRuns=$veeamFailedJobRuns,veeamMaxJobDuration=$veeamMaxJobDuration,veeamMaxBackupJobDuration=$veeamMaxBackupJobDuration,veeamMaxReplicaJobDuration=$veeamMaxReplicaJobDuration"
    curl -i -XPOST "$veeamInfluxDBURL:$veeamInfluxDBPort/write?precision=s&db=$veeamInfluxDB" -u "$veeamInfluxDBUser:$veeamInfluxDBPassword" --data-binary "veeam_em_overview_jobs,host=$veeamRestServer,veeamMaxDurationBackupJobName=$veeamMaxDurationBackupJobName,veeamMaxDurationReplicaJobName=$veeamMaxDurationReplicaJobName veeamRunningJobs=$veeamRunningJobs,veeamScheduledJobs=$veeamScheduledJobs,veeamScheduledBackupJobs=$veeamScheduledBackupJobs,veeamScheduledReplicaJobs=$veeamScheduledReplicaJobs,veeamTotalJobRuns=$veeamTotalJobRuns,veeamSuccessfulJobRuns=$veeamSuccessfulJobRuns,veeamWarningsJobRuns=$veeamWarningsJobRuns,veeamFailedJobRuns=$veeamFailedJobRuns,veeamMaxJobDuration=$veeamMaxJobDuration,veeamMaxBackupJobDuration=$veeamMaxBackupJobDuration,veeamMaxReplicaJobDuration=$veeamMaxReplicaJobDuration"

##
# Veeam Enterprise Manager Repositories. Overview of Repositories
##
veeamEMUrl="https://$veeamRestServer:$veeamRestPort/api/repositories?format=Entity"
veeamEMORepoUrl=$(curl -X GET "$veeamEMUrl" -H "Accept:application/json" -H "X-RestSvcSessionId: $veeamXRestSvcSessionId" -H "Cookie: X-RestSvcSessionId=$veeamXRestSvcSessionId" -H "Content-Length: 0" 2>&1 -k --silent | awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1')

declare -i arrayrepo=0
for Kind in $(echo "$veeamEMORepoUrl" | jq -r '.Repositories[].Kind'); do
    veeamRepositoryName=$(echo "$veeamEMORepoUrl" | jq --raw-output ".Repositories[$arrayrepo].Name" | awk '{gsub(/ /,"\\ ");print}')
    veeamVBR=$(echo "$veeamEMORepoUrl" | jq --raw-output ".Repositories[$arrayrepo].Links[0].Name" | awk '{gsub(/ /,"\\ ");print}') 
    veeamRepositoryCapacity=$(echo "$veeamEMORepoUrl" | jq --raw-output ".Repositories[$arrayrepo].Capacity")
    veeamRepositoryFreeSpace=$(echo "$veeamEMORepoUrl" | jq --raw-output ".Repositories[$arrayrepo].FreeSpace")    
    veeamRepositoryKind=$(echo "$veeamEMORepoUrl" | jq --raw-output ".Repositories[$arrayrepo].Kind")
  
    #echo "veeam_em_overview_repositories,host=$veeamRestServer,veeamRepositoryName=$veeamRepositoryName veeamRepositoryCapacity=$veeamRepositoryCapacity,veeamRepositoryFreeSpace=$veeamRepositoryFreeSpace,veeamRepositoryBackupSize=$veeamRepositoryBackupSize"
    curl -i -XPOST "$veeamInfluxDBURL:$veeamInfluxDBPort/write?precision=s&db=$veeamInfluxDB" -u "$veeamInfluxDBUser:$veeamInfluxDBPassword" --data-binary "veeam_em_overview_repositories,veeamVBR=$veeamVBR,veeamRepositoryName=$veeamRepositoryName,veeamRepositoryKind=$veeamRepositoryKind veeamRepositoryCapacity=$veeamRepositoryCapacity,veeamRepositoryFreeSpace=$veeamRepositoryFreeSpace"
  arrayrepo=$arrayrepo+1
done

##
# Veeam Enterprise Manager Backup Servers. Overview of Backup Repositories
##
veeamEMUrl="https://$veeamRestServer:$veeamRestPort/api/backupServers?format=Entity"
veeamEMOBackupServersUrl=$(curl -X GET "$veeamEMUrl" -H "Accept:application/json" -H "X-RestSvcSessionId: $veeamXRestSvcSessionId" -H "Cookie: X-RestSvcSessionId=$veeamXRestSvcSessionId" -H "Content-Length: 0" 2>&1 -k --silent | awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1')

declare -i arraybackupservers=0
for Name in $(echo "$veeamEMOBackupServersUrl" | jq -r '.BackupServers[].Name'); do
    veeamVBR=$(echo "$veeamEMOBackupServersUrl" | jq --raw-output ".BackupServers[$arraybackupservers].Name" | awk '{gsub(/ /,"\\ ");print}')
    veeamBackupServersPort=$(echo "$veeamEMOBackupServersUrl" | jq --raw-output ".BackupServers[$arraybackupservers].Port")
    veeamBackupServersVersion=$(echo "$veeamEMOBackupServersUrl" | jq --raw-output ".BackupServers[$arraybackupservers].Version" | awk '{gsub(/ /,"\\ ");print}')
       case $veeamBackupServersVersion in
        "10.0.0.4461")
            veeamBackupServersVersionM="10.0\ GA"
        ;;
        "10.0.0.4442")
            veeamBackupServersVersionM="10.0\ RTM"
        ;;
        "9.5.4.2866")
            veeamBackupServersVersionM="9.5\ U4b\ GA"
        ;;
        "9.5.4.2753")
            veeamBackupServersVersionM="9.5\ U4a\ GA"
        ;;
        "9.5.4.2615")
            veeamBackupServersVersionM="9.5\ U4\ GA"
        ;;
        "9.5.4.2399")
            veeamBackupServersVersionM="9.5\ U4\ RTM"
        ;;
        "9.5.0.1922")
            veeamBackupServersVersionM="9.5\ U3a"
        ;;
        "9.5.0.1536")
            veeamBackupServersVersionM="9.5\ U3"
        ;;
        "9.5.0.1038")
            veeamBackupServersVersionM="9.5\ U2"
        ;;
        "9.5.0.823")
            veeamBackupServersVersionM="9.5\ U1"
        ;;
        "9.5.0.802")
            veeamBackupServersVersionM="9.5\ U1\ RC"
        ;;
        "9.5.0.711")
            veeamBackupServersVersionM="9.5\ GA"
        ;;
        "9.5.0.580")
            veeamBackupServersVersionM="9.5\ RTM"
        ;;
        "9.0.0.1715")
            veeamBackupServersVersionM="9.0\ U2"
        ;;
        "9.0.0.1491")
            veeamBackupServersVersionM="9.0\ U1"
        ;;
        "9.0.0.902")
            veeamBackupServersVersionM="9.0\ GA"
        ;;
        "9.0.0.773")
            veeamBackupServersVersionM="9.0\ RTM"
        ;;
        "8.0.0.2084")
            veeamBackupServersVersionM="8.0\ U3"
        ;;
        "8.0.0.2030")
            veeamBackupServersVersionM="8.0\ U2b"
        ;;
        "8.0.0.2029")
            veeamBackupServersVersionM="8.0\ U2a"
        ;;
        "8.0.0.2021")
            veeamBackupServersVersionM="8.0\ U2\ GA"
        ;;
        "8.0.0.2018")
            veeamBackupServersVersionM="8.0\ U2\RTM"
        ;;
        "8.0.0.917")
            veeamBackupServersVersionM="8.0\ P1"
        ;;
        "8.0.0.817")
            veeamBackupServersVersionM="8.0\ GA"
        ;;
        "8.0.0.807")
            veeamBackupServersVersionM="8.0\ RTM"
        ;;
        esac

        #echo "veeam_em_backup_servers,veeamVBR=$veeamVBR,veeamBackupServersVersion=$veeamBackupServersVersion,veeamBackupServersVersionM=$veeamBackupServersVersionM veeamBackupServersPort=$veeamBackupServersPort"
        curl -i -XPOST "$veeamInfluxDBURL:$veeamInfluxDBPort/write?precision=s&db=$veeamInfluxDB" -u "$veeamInfluxDBUser:$veeamInfluxDBPassword" --data-binary "veeam_em_backup_servers,veeamVBR=$veeamVBR,veeamBackupServersVersion=$veeamBackupServersVersion,veeamBackupServersVersionM=$veeamBackupServersVersionM veeamBackupServersPort=$veeamBackupServersPort"
  arraybackupservers=$arraybackupservers+1
done

##
# Veeam Enterprise Manager Backup Job Sessions. Overview of Backup Job Sessions
##
veeamEMUrl="https://$veeamRestServer:$veeamRestPort/api/backupSessions?format=Entity"
veeamEMJobSessionsUrl=$(curl -X GET "$veeamEMUrl" -H "Accept:application/json" -H "X-RestSvcSessionId: $veeamXRestSvcSessionId" -H "Cookie: X-RestSvcSessionId=$veeamXRestSvcSessionId" -H "Content-Length: 0" 2>&1 -k --silent | awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1')

declare -i arrayjobsessions=0
for JobUid in $(echo "$veeamEMJobSessionsUrl" | jq -r '.BackupJobSessions[].JobUid'); do
    veeamBackupSessionsName=$(echo "$veeamEMJobSessionsUrl" | jq --raw-output ".BackupJobSessions[$arrayjobsessions].JobName" | awk '{gsub(/ /,"\\ ");print}')
    veeamVBR=$(echo "$veeamEMJobSessionsUrl" | jq --raw-output ".BackupJobSessions[$arrayjobsessions].Links[0].Name" | awk '{gsub(/ /,"\\ ");print}') 
    veeamBackupSessionsJobType=$(echo "$veeamEMJobSessionsUrl" | jq --raw-output ".BackupJobSessions[$arrayjobsessions].JobType") 
    veeamBackupSessionsJobState=$(echo "$veeamEMJobSessionsUrl" | jq --raw-output ".BackupJobSessions[$arrayjobsessions].State")
    veeamBackupSessionsJobResult=$(echo "$veeamEMJobSessionsUrl" | jq --raw-output ".BackupJobSessions[$arrayjobsessions].Result")     
    case $veeamBackupSessionsJobResult in
        Success)
            jobStatus="1"
        ;;
        Warning)
            jobStatus="2"
        ;;
        Failed)
            jobStatus="3"
        ;;
        esac
    veeamBackupSessionsTime=$(echo "$veeamEMJobSessionsUrl" | jq --raw-output ".BackupJobSessions[$arrayjobsessions].CreationTimeUTC")
    creationTimeUnix=$(date -d "$veeamBackupSessionsTime" +"%s")
    veeamBackupSessionsTimeEnd=$(echo "$veeamEMJobSessionsUrl" | jq --raw-output ".BackupJobSessions[$arrayjobsessions].EndTimeUTC")
    endTimeUnix=$(date -d "$veeamBackupSessionsTimeEnd" +"%s")
    veeamBackupSessionsTimeDuration=$(($endTimeUnix-$creationTimeUnix))
   
    #echo "veeam_em_job_sessions,veeamBackupSessionsName=$veeamBackupSessionsName,veeamVBR=$veeamVBR,veeamBackupSessionsJobType=$veeamBackupSessionsJobType,veeamBackupSessionsJobState=$veeamBackupSessionsJobState veeamBackupSessionsJobResult=$jobStatus $creationTimeUnix"
    curl -i -XPOST "$veeamInfluxDBURL:$veeamInfluxDBPort/write?precision=s&db=$veeamInfluxDB" -u "$veeamInfluxDBUser:$veeamInfluxDBPassword" --data-binary "veeam_em_job_sessions,veeamBackupSessionsName=$veeamBackupSessionsName,veeamVBR=$veeamVBR,veeamBackupSessionsJobType=$veeamBackupSessionsJobType,veeamBackupSessionsJobState=$veeamBackupSessionsJobState veeamBackupSessionsJobResult=$jobStatus,veeamBackupSessionsTimeDuration=$veeamBackupSessionsTimeDuration $creationTimeUnix"
  arrayjobsessions=$arrayjobsessions+1
done

##
# Veeam Enterprise Manager Backup Job Sessions per VM. Overview of Backup Job Sessions per VM. Really useful to display if a VM it is protected or not
##
veeamEMUrl="https://$veeamRestServer:$veeamRestPort/api/backupTaskSessions?format=Entity"
veeamEMJobSessionsVMUrl=$(curl -X GET "$veeamEMUrl" -H "Accept:application/json" -H "X-RestSvcSessionId: $veeamXRestSvcSessionId" -H "Cookie: X-RestSvcSessionId=$veeamXRestSvcSessionId" -H "Content-Length: 0" 2>&1 -k --silent | awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1')

declare -i arrayjobsessionsvm=0
for JobSessionUid in $(echo "$veeamEMJobSessionsVMUrl" | jq -r '.BackupTaskSessions[].JobSessionUid'); do
    veeamBackupSessionsVmDisplayName=$(echo "$veeamEMJobSessionsVMUrl" | jq --raw-output ".BackupTaskSessions[$arrayjobsessionsvm].VmDisplayName" | awk '{gsub(/ /,"\\ ");print}')
    veeamVBR=$(echo "$veeamEMJobSessionsVMUrl" | jq --raw-output ".BackupTaskSessions[$arrayjobsessions].Links[0].Name" | awk '{gsub(/ /,"\\ ");print}') 
    veeamBackupSessionsTotalSize=$(echo "$veeamEMJobSessionsVMUrl" | jq --raw-output ".BackupTaskSessions[$arrayjobsessionsvm].TotalSize")    
    veeamBackupSessionsJobVMState=$(echo "$veeamEMJobSessionsVMUrl" | jq --raw-output ".BackupTaskSessions[$arrayjobsessionsvm].State")
    veeamBackupSessionsJobVMResult=$(echo "$veeamEMJobSessionsVMUrl" | jq --raw-output ".BackupTaskSessions[$arrayjobsessionsvm].Result") 
    case $veeamBackupSessionsJobVMResult in
        Success)
            jobStatus="1"
        ;;
        Warning)
            jobStatus="2"
        ;;
        Failed)
            jobStatus="3"
        ;;
        esac
    veeamBackupSessionsVMTime=$(echo "$veeamEMJobSessionsVMUrl" | jq --raw-output ".BackupTaskSessions[$arrayjobsessionsvm].CreationTimeUTC")
    creationTimeUnix=$(date -d "$veeamBackupSessionsVMTime" +"%s")
    veeamBackupSessionsVMTimeEnd=$(echo "$veeamEMJobSessionsVMUrl" | jq --raw-output ".BackupTaskSessions[$arrayjobsessionsvm].EndTimeUTC")
    endTimeUnix=$(date -d "$veeamBackupSessionsVMTimeEnd" +"%s")
    veeamBackupSessionsVMDuration=$(($endTimeUnix-$creationTimeUnix))
   
    #echo "veeam_em_job_sessionsvm,veeamBackupSessionsVmDisplayName=$veeamBackupSessionsVmDisplayName,veeamVBR=$veeamVBR,veeamBackupSessionsJobVMState=$veeamBackupSessionsJobVMState veeamBackupSessionsTotalSize=$veeamBackupSessionsTotalSize,veeamBackupSessionsJobVMResult=$jobStatus $creationTimeUnix"
    curl -i -XPOST "$veeamInfluxDBURL:$veeamInfluxDBPort/write?precision=s&db=$veeamInfluxDB" -u "$veeamInfluxDBUser:$veeamInfluxDBPassword" --data-binary "veeam_em_job_sessionsvm,veeamBackupSessionsVmDisplayName=$veeamBackupSessionsVmDisplayName,veeamVBR=$veeamVBR,veeamBackupSessionsJobVMState=$veeamBackupSessionsJobVMState veeamBackupSessionsTotalSize=$veeamBackupSessionsTotalSize,veeamBackupSessionsJobVMResult=$jobStatus,veeamBackupSessionsVMDuration=$veeamBackupSessionsVMDuration $creationTimeUnix"
  arrayjobsessionsvm=$arrayjobsessionsvm+1
done

##
# Veeam Enterprise Manager Replica Job Sessions. Overview of Replica Job Sessions
##
veeamEMUrl="https://$veeamRestServer:$veeamRestPort/api/replicaSessions?format=Entity"
veeamEMJobReplicaSessionsUrl=$(curl -X GET "$veeamEMUrl" -H "Accept:application/json" -H "X-RestSvcSessionId: $veeamXRestSvcSessionId" -H "Cookie: X-RestSvcSessionId=$veeamXRestSvcSessionId" -H "Content-Length: 0" 2>&1 -k --silent | awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1')

declare -i arrayjobrepsessions=0
for JobUid in $(echo "$veeamEMJobReplicaSessionsUrl" | jq -r '.ReplicaJobSessions[].JobUid'); do
    veeamReplicaSessionsName=$(echo "$veeamEMJobReplicaSessionsUrl" | jq --raw-output ".ReplicaJobSessions[$arrayjobrepsessions].JobName" | awk '{gsub(/ /,"\\ ");print}')
    veeamVBR=$(echo "$veeamEMJobReplicaSessionsUrl" | jq --raw-output ".ReplicaJobSessions[$arrayjobrepsessions].Links[0].Name" | awk '{gsub(/ /,"\\ ");print}') 
    veeamReplicaSessionsJobType=$(echo "$veeamEMJobReplicaSessionsUrl" | jq --raw-output ".ReplicaJobSessions[$arrayjobrepsessions].JobType") 
    veeamReplicaSessionsJobState=$(echo "$veeamEMJobReplicaSessionsUrl" | jq --raw-output ".ReplicaJobSessions[$arrayjobrepsessions].State")
    veeamReplicaSessionsJobResult=$(echo "$veeamEMJobReplicaSessionsUrl" | jq --raw-output ".ReplicaJobSessions[$arrayjobrepsessions].Result")     
    case $veeamReplicaSessionsJobResult in
        Success)
            jobStatus="1"
        ;;
        Warning)
            jobStatus="2"
        ;;
        Failed)
            jobStatus="3"
        ;;
        esac
    veeamReplicaSessionsTime=$(echo "$veeamEMJobReplicaSessionsUrl" | jq --raw-output ".ReplicaJobSessions[$arrayjobrepsessions].CreationTimeUTC")
    creationTimeUnix=$(date -d "$veeamReplicaSessionsTime" +"%s")
    veeamReplicaSessionsTimeEnd=$(echo "$veeamEMJobReplicaSessionsUrl" | jq --raw-output ".ReplicaJobSessions[$arrayjobrepsessions].EndTimeUTC")
    endTimeUnix=$(date -d "$veeamReplicaSessionsTimeEnd" +"%s")
    veeamReplicaSessionsDuration=$(($endTimeUnix-$creationTimeUnix))
    
    #echo "veeam_em_job_sessions,veeamReplicaSessionsName=$veeamReplicaSessionsName,veeamVBR=$veeamVBR,veeamReplicaSessionsJobType=$veeamReplicaSessionsJobType,veeamReplicaSessionsJobState=$veeamReplicaSessionsJobState veeamReplicaSessionsJobResult=$jobStatus $creationTimeUnix"
    curl -i -XPOST "$veeamInfluxDBURL:$veeamInfluxDBPort/write?precision=s&db=$veeamInfluxDB" -u "$veeamInfluxDBUser:$veeamInfluxDBPassword" --data-binary "veeam_em_job_sessions,veeamReplicaSessionsName=$veeamReplicaSessionsName,veeamVBR=$veeamVBR,veeamReplicaSessionsJobType=$veeamReplicaSessionsJobType,veeamReplicaSessionsJobState=$veeamReplicaSessionsJobState veeamReplicaSessionsJobResult=$jobStatus,veeamReplicaSessionsDuration=$veeamReplicaSessionsDuration $creationTimeUnix"
  arrayjobrepsessions=$arrayjobrepsessions+1
done

##
# Veeam Enterprise Manager Replica Job Sessions per VM. Overview of Replica Job Sessions per VM. Really useful to display if a VM it is protected or not
##
veeamEMUrl="https://$veeamRestServer:$veeamRestPort/api/replicaTaskSessions?format=Entity"
veeamEMJobReplicaSessionsVMUrl=$(curl -X GET "$veeamEMUrl" -H "Accept:application/json" -H "X-RestSvcSessionId: $veeamXRestSvcSessionId" -H "Cookie: X-RestSvcSessionId=$veeamXRestSvcSessionId" -H "Content-Length: 0" 2>&1 -k --silent | awk 'NR==1{sub(/^\xef\xbb\xbf/,"")}1')

declare -i arrayjobrepsessionsvm=0
for JobSessionUid in $(echo "$veeamEMJobReplicaSessionsVMUrl" | jq -r '.ReplicaTaskSessions[].JobSessionUid'); do
    veeamReplicaSessionsVmDisplayName=$(echo "$veeamEMJobReplicaSessionsVMUrl" | jq --raw-output ".ReplicaTaskSessions[$arrayjobrepsessionsvm].VmDisplayName" | awk '{gsub(/ /,"\\ ");print}')
    veeamVBR=$(echo "$veeamEMJobReplicaSessionsVMUrl" | jq --raw-output ".ReplicaTaskSessions[$arrayjobrepsessionsvm].Links[0].Name" | awk '{gsub(/ /,"\\ ");print}') 
    veeamReplicaSessionsTotalSize=$(echo "$veeamEMJobReplicaSessionsVMUrl" | jq --raw-output ".ReplicaTaskSessions[$arrayjobrepsessionsvm].TotalSize")    
    veeamReplicaSessionsJobVMState=$(echo "$veeamEMJobReplicaSessionsVMUrl" | jq --raw-output ".ReplicaTaskSessions[$arrayjobrepsessionsvm].State")
    veeamReplicaSessionsJobVMResult=$(echo "$veeamEMJobReplicaSessionsVMUrl" | jq --raw-output ".ReplicaTaskSessions[$arrayjobrepsessionsvm].Result") 
    case $veeamReplicaSessionsJobVMResult in
        Success)
            jobStatus="1"
        ;;
        Warning)
            jobStatus="2"
        ;;
        Failed)
            jobStatus="3"
        ;;
        esac
    veeamReplicaSessionsVMTime=$(echo "$veeamEMJobReplicaSessionsVMUrl" | jq --raw-output ".ReplicaTaskSessions[$arrayjobrepsessionsvm].CreationTimeUTC")
    creationTimeUnix=$(date -d "$veeamReplicaSessionsVMTime" +"%s")
    veeamReplicaSessionsVMTimeEnd=$(echo "$veeamEMJobReplicaSessionsVMUrl" | jq --raw-output ".ReplicaJobSessions[$arrayjobrepsessionsvm].EndTimeUTC")
    endTimeUnix=$(date -d "$veeamReplicaSessionsVMTimeEnd" +"%s")
    veeamReplicaSessionsVMDuration=$(($endTimeUnix-$creationTimeUnix))
   
    #echo "veeam_em_job_sessionsvm,veeamReplicaSessionsVmDisplayName=$veeamReplicaSessionsVmDisplayName,veeamVBR=$veeamVBR,veeamReplicaSessionsJobVMState=$veeamReplicaSessionsJobVMState veeamReplicaSessionsTotalSize=$veeamReplicaSessionsTotalSize,veeamReplicaSessionsJobVMResult=$jobStatus $creationTimeUnix"
    curl -i -XPOST "$veeamInfluxDBURL:$veeamInfluxDBPort/write?precision=s&db=$veeamInfluxDB" -u "$veeamInfluxDBUser:$veeamInfluxDBPassword" --data-binary "veeam_em_job_sessionsvm,veeamReplicaSessionsVmDisplayName=$veeamReplicaSessionsVmDisplayName,veeamVBR=$veeamVBR,veeamReplicaSessionsJobVMState=$veeamReplicaSessionsJobVMState veeamReplicaSessionsTotalSize=$veeamReplicaSessionsTotalSize,veeamReplicaSessionsJobVMResult=$jobStatus,veeamReplicaSessionsVMDuration=$veeamReplicaSessionsVMDuration $creationTimeUnix"
  arrayjobrepsessionsvm=$arrayjobrepsessionsvm+1
done
