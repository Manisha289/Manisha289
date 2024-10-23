$script:ErrorActionPreference = "SilentlyContinue"
Set-StrictMode -Version Latest
$session = $null
$returnmessage = $null
$description = $null
$result = $null
$message = $null
$instanceSQL = "SQL1,SQL2"
$output=@()
$servertype = "standalone"
$count = 1
$SQLserverNames = "SEGOTN18487"
[int]$instance_count = 2

if($instanceSQL -match ','){
$instanceSQL = $instanceSQL -split(',')
}

if($SQLserverNames -match ','){
$SQLserverNames = $SQLserverNames -split(',')
}


$credential = New-Object System.Management.Automation.PSCredential "vcn\cs-ws-s-SCO-SQL", (ConvertTo-SecureString -String "L878bJ98JLcJ%f7" -AsPlainText -Force)

foreach($SQLserverName in $SQLserverNames){

try{
   $session = New-PSSession -ComputerName $SQLserverName -credential $credential 
}
catch{   
   $description = $error[0].Exception.Message
   $returnmessage = "fail"  
}


if($session -ne $null){
   $scriptblock={
       $instanceSQL=$args[0]
       $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
       $SqlConnection.ConnectionString = "Server='$instanceSQL';Integrated Security=True"
       $SqlConnection.Open()
       $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
       $SqlCmd.CommandText ="DECLARE @cmd varchar(MAX), 
	@ProceedStatus VARCHAR(50),
	@ProductVersion	varchar(20), 
	@SQLVersion varchar(20), 
	@OnlineDBCount int,
	@BackupDBCount int,
	@DBName sysname

DECLARE @BackupTbl  TABLE (ServerInstance sysname, DBName sysname, Backup_Start_Date datetime,backup_finish_date datetime,BackupType varchar(50),
Logical_device_name varchar (1000), Physical_device_name varchar (1000), backupset_name varchar (100), Recovery_Model varchar (20),Proceed varchar(4),ChainOK varchar(500))


 INSERT INTO @BackupTbl (ServerInstance, DBName, Backup_Start_Date,backup_finish_date,BackupType,Logical_device_name, 
 Physical_device_name, backupset_name, Recovery_Model,Proceed,ChainOK) 
 SELECT @@SERVERNAME,
  msdb.dbo.backupset.database_name,
  msdb.dbo.backupset.backup_start_date,
  msdb.dbo.backupset.backup_finish_date,
  CASE msdb..backupset.type
     WHEN 'D' THEN 'Full'
     WHEN 'L' THEN 'Log'
     WHEN 'I' THEN 'Differential'
     END AS backup_type,
  msdb.dbo.backupmediafamily.logical_device_name,
  msdb.dbo.backupmediafamily.physical_device_name,
  msdb.dbo.backupset.name AS backupset_name,
  master.sys.databases.recovery_model_desc,
  '',''
FROM
  msdb.dbo.backupmediafamily
  INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id
  INNER JOIN master.sys.databases ON master.sys.databases.name=msdb.dbo.backupset.database_name
WHERE
  (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102)>= GETDATE() - 8)
  AND msdb.dbo.backupset.type='D' AND master.sys.databases.name NOT IN ('master','model','msdb')
  ----- SYSDATABASE
  INSERT INTO @BackupTbl (ServerInstance, DBName, Backup_Start_Date,backup_finish_date,BackupType,Logical_device_name, 
 Physical_device_name, backupset_name, Recovery_Model,Proceed,ChainOK) 
 SELECT @@SERVERNAME,
  msdb.dbo.backupset.database_name,
  msdb.dbo.backupset.backup_start_date,
  msdb.dbo.backupset.backup_finish_date,
  CASE msdb..backupset.type
     WHEN 'D' THEN 'Full'
     WHEN 'L' THEN 'Log'
     WHEN 'I' THEN 'Differential'
     END AS backup_type,
  msdb.dbo.backupmediafamily.logical_device_name,
  msdb.dbo.backupmediafamily.physical_device_name,
  msdb.dbo.backupset.name AS backupset_name,
  master.sys.databases.recovery_model_desc,
  '',''
FROM
  msdb.dbo.backupmediafamily
  INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id
  INNER JOIN master.sys.databases ON master.sys.databases.name=msdb.dbo.backupset.database_name
WHERE
  (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102)>= GETDATE() - 1.5)
  AND msdb.dbo.backupset.type='D'AND master.sys.databases.name IN ('master','msdb','model')

 INSERT INTO @BackupTbl (ServerInstance, DBName, Backup_Start_Date,backup_finish_date,BackupType,Logical_device_name, 
 Physical_device_name, backupset_name, Recovery_Model,Proceed,ChainOK) 
 SELECT @@SERVERNAME,
  msdb.dbo.backupset.database_name,
  msdb.dbo.backupset.backup_start_date,
  msdb.dbo.backupset.backup_finish_date,
  CASE msdb..backupset.type
     WHEN 'D' THEN 'Full'
     WHEN 'L' THEN 'Log'
     WHEN 'I' THEN 'Differential'
     END AS backup_type,
  msdb.dbo.backupmediafamily.logical_device_name,
  msdb.dbo.backupmediafamily.physical_device_name,
  msdb.dbo.backupset.name AS backupset_name,
  master.sys.databases.recovery_model_desc,
  '',''
FROM
  msdb.dbo.backupmediafamily
  INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id
  INNER JOIN master.sys.databases ON master.sys.databases.name=msdb.dbo.backupset.database_name
WHERE
  (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102)>= GETDATE() - 1)
  AND msdb.dbo.backupset.type='I'


INSERT INTO @BackupTbl (ServerInstance, DBName, Backup_Start_Date,backup_finish_date,BackupType,Logical_device_name, 
Physical_device_name, backupset_name, Recovery_Model,Proceed,ChainOK) 
SELECT @@SERVERNAME,
  msdb.dbo.backupset.database_name,
  msdb.dbo.backupset.backup_start_date,
  msdb.dbo.backupset.backup_finish_date,
  CASE msdb..backupset.type
     WHEN 'D' THEN 'Full'
     WHEN 'L' THEN 'Log'
     WHEN 'I' THEN 'Differential'
     END AS backup_type,
  msdb.dbo.backupmediafamily.logical_device_name,
  msdb.dbo.backupmediafamily.physical_device_name,
  msdb.dbo.backupset.name AS backupset_name,
  master.sys.databases.recovery_model_desc,
  '',''
FROM
  msdb.dbo.backupmediafamily
  INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id
  INNER JOIN master.sys.databases ON master.sys.databases.name=msdb.dbo.backupset.database_name
WHERE
  (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102)>= GETDATE() - 0.06)
  AND msdb.dbo.backupset.type='L';


  INSERT INTO @BackupTbl (ServerInstance, DBName, Backup_Start_Date,backup_finish_date,BackupType,Logical_device_name, 
  Physical_device_name, backupset_name, Recovery_Model,Proceed, ChainOK) 
SELECT @@SERVERNAME,
  master.sys.databases.name,
  '',
  '',
  'No Backup',
  'No Backup',
  'No Backup',
  'No Backup',
  master.sys.databases.recovery_model_desc,
  '',''
  FROM
  master.sys.databases
WHERE master.sys.databases.name NOT IN (SELECT DISTINCT database_name FROM msdb.dbo.backupset) 
AND master.sys.databases.database_id>4 

--- CONDITION CHECKS START
--Database with no backup
IF EXISTS(SELECT DBName FROM @BackupTbl WHERE Recovery_Model in ('FULL', 'SIMPLE','BULK_LOGGED') AND BackupType='No Backup' AND Physical_device_name NOT LIKE 'TDPSQL%')
BEGIN
UPDATE @BackupTbl SET Proceed='NO' WHERE Recovery_Model in ('FULL', 'SIMPLE','BULK_LOGGED') AND BackupType='No Backup' AND Physical_device_name NOT LIKE 'TDPSQL%'
END

-- Database with SIMPLE recovery and FULL Backup
IF EXISTS(SELECT DBName FROM @BackupTbl WHERE Recovery_Model in ('SIMPLE') AND BackupType='Full'AND Physical_device_name LIKE 'TDPSQL%' AND (CONVERT(datetime, Backup_Start_date, 102)>= GETDATE() - 8) AND DBName NOT IN('master','model','msdb') 
)
BEGIN
UPDATE @BackupTbl SET Proceed='YES' WHERE Recovery_Model in ('SIMPLE') AND BackupType='Full'AND Physical_device_name LIKE 'TDPSQL%' AND (CONVERT(datetime, Backup_Start_date, 102)>= GETDATE() - 8) AND DBName NOT IN('master','model','msdb')
END
-- Database with FULL Recovery and FULL Backup
IF EXISTS(SELECT DBName FROM @BackupTbl WHERE Recovery_Model in ('FULL') AND BackupType='Full'AND Physical_device_name LIKE 'TDPSQL%' AND (CONVERT(datetime, Backup_Start_date, 102)>= GETDATE() - 8) AND DBName NOT IN('master','model','msdb') 
)
BEGIN
UPDATE @BackupTbl SET Proceed='YES' WHERE Recovery_Model in ('FULL') AND BackupType='Full'AND Physical_device_name LIKE 'TDPSQL%' AND (CONVERT(datetime, Backup_Start_date, 102)>= GETDATE() - 8) AND DBName NOT IN('master','model','msdb')
END
-- Database with BULKED_LOGGED Recovery and FULL Backup
IF EXISTS(SELECT DBName FROM @BackupTbl WHERE Recovery_Model in ('BULK_LOGGED') AND BackupType='Full'AND Physical_device_name LIKE 'TDPSQL%' AND (CONVERT(datetime, Backup_Start_date, 102)>= GETDATE() - 8) AND DBName NOT IN('master','model','msdb') 
)
BEGIN
UPDATE @BackupTbl SET Proceed='YES' WHERE Recovery_Model in ('BULK_LOGGED') AND BackupType='Full'AND Physical_device_name LIKE 'TDPSQL%' AND (CONVERT(datetime, Backup_Start_date, 102)>= GETDATE() - 8) AND DBName NOT IN('master','model','msdb')
END
-- System Database with FULL Backup
IF EXISTS(SELECT DBName FROM @BackupTbl WHERE Recovery_Model in ('FULL', 'SIMPLE') AND BackupType='Full'AND Physical_device_name LIKE 'TDPSQL%' AND (CONVERT(datetime, Backup_Start_date, 102)>= GETDATE() - 2) AND DBName IN('master','model','msdb') 
)
BEGIN
UPDATE @BackupTbl SET Proceed='YES' WHERE Recovery_Model in ('FULL', 'SIMPLE') AND BackupType='Full'AND Physical_device_name LIKE 'TDPSQL%' AND (CONVERT(datetime, Backup_Start_date, 102)>= GETDATE() - 2) AND DBName IN('master','model','msdb')
END

-- Database with FULL Recovery and Differential backup
IF EXISTS(SELECT DBName FROM @BackupTbl WHERE Recovery_Model in ('FULL') AND BackupType='Differential'AND Physical_device_name LIKE 'TDPSQL%')
BEGIN
UPDATE @BackupTbl SET Proceed='YES' WHERE Recovery_Model in ('FULL') AND BackupType='Differential'AND Physical_device_name LIKE 'TDPSQL%'
END

-- Database with SIMPLE Recovery and Differential backup
IF EXISTS(SELECT DBName FROM @BackupTbl WHERE Recovery_Model in ('SIMPLE') AND BackupType='Differential'AND Physical_device_name LIKE 'TDPSQL%')
BEGIN
UPDATE @BackupTbl SET Proceed='YES' WHERE Recovery_Model in ('SIMPLE') AND BackupType='Differential'AND Physical_device_name LIKE 'TDPSQL%'
END

-- Database with BULK_LOGGED Recovery and Differential backup
IF EXISTS(SELECT DBName FROM @BackupTbl WHERE Recovery_Model in ('BULK_LOGGED') AND BackupType='Differential'AND Physical_device_name LIKE 'TDPSQL%')
BEGIN
UPDATE @BackupTbl SET Proceed='YES' WHERE Recovery_Model in ('BULK_LOGGED') AND BackupType='Differential'AND Physical_device_name LIKE 'TDPSQL%'
END

-- Database with FULL Recovery and Log backup
IF EXISTS(SELECT DBName FROM @BackupTbl WHERE Recovery_Model in ('FULL') AND BackupType='Log'AND Physical_device_name LIKE 'TDPSQL%')
BEGIN
UPDATE @BackupTbl SET Proceed='YES' WHERE Recovery_Model in ('FULL') AND BackupType='Log'AND Physical_device_name LIKE 'TDPSQL%'
END

-- Database with BULK_LOGGED Recovery and Log Backup
IF EXISTS(SELECT DBName FROM @BackupTbl WHERE Recovery_Model in ('BULK_LOGGED') AND BackupType='Log'AND Physical_device_name LIKE 'TDPSQL%')
BEGIN
UPDATE @BackupTbl SET Proceed='YES' WHERE Recovery_Model in ('BULK_LOGGED') AND BackupType='Log'AND Physical_device_name LIKE 'TDPSQL%'
END

/*
  SELECT ServerInstance, DBName, Backup_Start_Date,backup_finish_date,BackupType,Logical_device_name, 
  Physical_device_name, backupset_name, Recovery_Model,Proceed FROM @BackupTbl WHERE Recovery_Model='BULK_LOGGED'
  group by ServerInstance, DBName, Backup_Start_Date,backup_finish_date,BackupType,Logical_device_name, 
  Physical_device_name, backupset_name, Recovery_Model,Proceed ORDER BY DBName
*/

-- Update Proceed Column with Empty status
IF EXISTS(SELECT DBName FROM @BackupTbl WHERE Proceed='')
BEGIN
UPDATE @BackupTbl SET Proceed='NO' WHERE Proceed=''
END
-- CONDITION CHECKS END
/*
SELECT ServerInstance, DBName, Backup_Start_Date,backup_finish_date,BackupType,Logical_device_name, 
  Physical_device_name, backupset_name, Recovery_Model,Proceed FROM @BackupTbl 
  group by ServerInstance, DBName, Backup_Start_Date,backup_finish_date,BackupType,Logical_device_name, 
  Physical_device_name, backupset_name, Recovery_Model,Proceed ORDER BY DBName
*/


SET @ProductVersion=convert(varchar(20), serverproperty('ProductVersion'))

--SET @ProductVersion='12.0.2323.1'
set @SQLVersion =
case
	when left(@ProductVersion, 2) = '16' then 'SQL 2022'
	when left(@ProductVersion, 2) = '15' then 'SQL 2019'
	when left(@ProductVersion, 2) = '14' then 'SQL 2017'
	when left(@ProductVersion, 2) = '13' then 'SQL 2016'
	ELSE 'EOL Version'

end

DELETE FROM @BackupTbl WHERE  BackupType='Full' AND Backup_start_Date NOT IN (SELECT MAX(Backup_start_Date)FROM @BackupTbl WHERE BackupType='FULL' GROUP BY DBName)
DELETE FROM @BackupTbl WHERE  BackupType='Differential' AND Backup_start_Date NOT IN (SELECT MAX(Backup_start_Date)FROM @BackupTbl WHERE BackupType='Differential' GROUP BY DBName)
DELETE FROM @BackupTbl WHERE  BackupType='Log' AND Backup_start_Date NOT IN (SELECT MAX(Backup_start_Date)FROM @BackupTbl WHERE BackupType='Log' GROUP BY DBName)

--SELECT DISTINCT (DBName),* FROM @BackupTbl WHERE BackupType='Full'
--SELECT DISTINCT (DBName),* FROM @BackupTbl WHERE BackupType='Differential'
--SELECT DISTINCT (DBName),* FROM @BackupTbl WHERE BackupType='Log'
--CHECK 
DECLARE @BackupTimeLog datetime, @BackupTimeFull datetime
DECLARE ChainOK CURSOR for
SELECT name from master.sys.databases WHERE state_desc ='ONLINE' and name NOT in ('master','tempdb')

OPEN ChainOK
fetch next from ChainOK into @DBName

while @@FETCH_STATUS = 0
begin
		IF EXISTS
		(
			-- Backups taken by something else than TDPSQL
			select backup_finish_date from msdb..backupset
			where
				[type] in ('D', 'L')
				and is_copy_only = 0
				--and database_name = 'Test2'
				and ISNULL(description,'unknown') not like 'TDPSQL-%'
				and database_name = @DBName
				and backup_finish_date >=
				(
					-- Latest full backup for database
					select max(backup_finish_date) from msdb..backupset
					where
						type = 'D'
						and description like 'TDPSQL-%'
						and database_name = @DBName
				)
		)
		BEGIN
	--	SELECT  '1-ChainBroken-'+@DBName
		UPDATE @BackupTbl SET ChainOK='1-ChainBroken' WHERE DBName=@DBName
		END

		else
		BEGIN
	--	SELECT '0-NoChainBroken-'+@DBName
		UPDATE @BackupTbl SET ChainOK='0-NoChainBroken' WHERE DBName=@DBName
		end

		IF EXISTS (SELECT MAX(Backup_start_Date)FROM @BackupTbl WHERE BackupType='Log' AND Physical_device_name NOT LIKE 'TDPSQL%' and DBName=@DBName)
		BEGIN
		SET @BackupTimeLog=(SELECT MAX(Backup_start_Date)FROM @BackupTbl WHERE BackupType='Log' AND Physical_device_name NOT LIKE 'TDPSQL%' and DBName=@DBName)
		SET @BackupTimeFull= (SELECT MAX(Backup_start_Date)FROM @BackupTbl WHERE BackupType='Full' AND Physical_device_name  LIKE 'TDPSQL%' and DBName=@DBName)
		
		IF @BackupTimeFull> @BackupTimeLog
		BEGIN
		UPDATE @BackupTbl SET Proceed='YES' WHERE ChainOK='0-NoChainBroken' AND DBName=@DBName AND	BackupType='Log' AND Physical_device_name NOT LIKE 'TDPSQL%'	
		END
		ELSE
		BEGIN
		UPDATE @BackupTbl SET Proceed='NO', ChainOK='0-ChainBroken' WHERE DBName=@DBName AND BackupType='Log' AND Physical_device_name NOT LIKE 'TDPSQL%'
		END
		END
		
	fetch next from ChainOK into @DBName
end

close ChainOK
deallocate ChainOK	

--END CHECK

SELECT @BackupDBCount=COUNT(DISTINCT(DBName)) FROM @BackupTbl WHERE Proceed='YES' AND DBNAME NOT IN (SELECT DBName FROM @BackupTbl WHERE Proceed='NO')
SELECT @OnlineDBCount=COUNT(name) FROM master.sys.databases WHERE state_desc='ONLINE' AND name NOT IN ('tempdb')


--- Proceed Patching Status Check START
IF EXISTS (SELECT DBName FROM @BackupTbl WHERE DBName='master' AND Proceed='YES' and BackupType='Full')
BEGIN
UPDATE @BackupTbl SET  ChainOK='0-NoChainBroken' WHERE BackupType='Full' AND Physical_device_name LIKE 'TDPSQL%' AND DBName='master' AND Proceed='YES'
		
END
ELSE
BEGIN
UPDATE @BackupTbl SET  ChainOK='1-ChainBroken' WHERE BackupType='Full' AND Physical_device_name NOT LIKE 'TDPSQL%' AND DBName='master' AND Proceed='NO'

END
IF EXISTS (SELECT DBName FROM @BackupTbl WHERE Proceed='NO' OR ChainOK='1-ChainBroken' OR @OnlineDBCount!= @BackupDBCount)
BEGIN
SELECT @ProceedStatus='FAILED BACKUP CHECK- DO NOT PROCEED PATCHING'--AS Proceed_Patch_Status
END

IF NOT EXISTS (SELECT DBName FROM @BackupTbl WHERE Proceed ='NO' OR ChainOK='1-ChainBroken' OR @OnlineDBCount!= @BackupDBCount)
BEGIN
SELECT @ProceedStatus='SUCCESS BACKUP CHECK - PROCEED PATCHING' --AS Proceed_Patch_Status
END
--- Proceed Patching Status Check ENDS
--SELECT * FROM @BackupTbl
-- FINAL RESULT OF PRE-CHECKS
--SELECT @BackupDBCount=COUNT(DISTINCT(DBName)) FROM @BackupTbl WHERE Proceed='YES' AND DBNAME NOT IN (SELECT DBName FROM @BackupTbl WHERE Proceed='NO')
SELECT @OnlineDBCount=COUNT(name) FROM master.sys.databases WHERE state_desc='ONLINE' AND name NOT IN ('tempdb')
SELECT @@SERVERNAME AS SQLServerInstance,@SQLVersion AS SQLVersion, @ProductVersion AS SQLProductVersion, @OnlineDBCount AS OnlineDB, @BackupDBCount AS BackupDBCount, @ProceedStatus AS Proceed_Patch_Status"

       $SqlCmd.Connection = $SqlConnection
       $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
       $SqlAdapter.SelectCommand = $SqlCmd
       $DataSet = New-Object System.Data.DataSet
       $SqlAdapter.Fill($DataSet)
       return $DataSet.Tables[0]
       $SqlConnection.Close()
   }

   if($servertype -eq "standalone"){

   foreach($instance in $instanceSQL){
    $SQLInstance = "$SQLserverName\$instance"

    try{
       $result = Invoke-Command -Session $session -ScriptBlock $scriptblock -ArgumentList "$SQLinstance"
    }
    catch
    {
       $Description=$_
    }
    $output += $result | Where-Object {$_ -ne 1}
   }
   }
   elseif($servertype -eq "cluster"){
      
      $instance = "SQL$count"
      $SQLInstance = "$SQLserverName\$instance"
    try{
       $result = Invoke-Command -Session $session -ScriptBlock $scriptblock -ArgumentList "$SQLinstance"
    }
    catch
    {
       $Description=$_
    }
    $output += $result | Where-Object {$_ -ne 1}
     
    $count+=1
   }
   Remove-pssession -session $session
 }#session if

 $SQLserverName = $SQLserverName.Split('-')[0]

}#for loop
 
$Filename = $SQLserverName+"_pre-patch_details.csv" 
$filepath = "D:\SQL\$Filename"

$output | Export-csv -Path $filepath -NoTypeInformation
 
$filedatacount = (Import-CSV $filepath | Measure-Object).Count

if($filedatacount -eq $instance_count){
$returnmessage = "success"
}
else{
$returnmessage = "fail"
$message = "Instances details are not fetched properly."
}
