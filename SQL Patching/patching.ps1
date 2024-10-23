$script:ErrorActionPreference = "SilentlyContinue"
Set-StrictMode -Version Latest
$SQLserverName ="segotn18491-n1"
$session = $null
$returnmessage = $null
$description = $null
$result = $null
$message = $null
[int]$flag = 2
[int]$instance_count = 2
$patchfile_dir = $null
$patch_dir = "C:\SOE\SQLPatches"
$version = $null
$versions = @{}
$uniqueVersions = @()
$lowerinstance = @()
$sqlInstances = $null

if($SQLserverName -match "-"){
$serverName = $SQLserverName.Split('-')[0]
}

$filename = "$serverName_pre-patch.csv"
$filepath = "D:\SQL\$filename"


$credential = New-Object System.Management.Automation.PSCredential "vcn\cs-ws-s-SCO-SQL", (ConvertTo-SecureString -String "L878bJ98JLcJ%f7" -AsPlainText -Force)


try{
   $session = New-PSSession -ComputerName $SQLserverName -credential $credential 
}
catch
{   
   $description = $error[0].Exception.Message
   $returnmessage = "fail"  
}

# Function to find the instance with the lowest version

function Get-LowestVersionInstance {
    param (
        [hashtable]$versions,
        [int]$flag
    )
    [int]$flag = $flag - 1
    $minVersion = $versions.Values | Sort-Object | Select-Object -Index $flag
    $instanceToPatch = $versions.Keys | Where-Object { $versions[$_] -eq $minVersion }
    return $instanceToPatch
}
 
$sqlInstances = Import-Csv $filepath

foreach ($instance in $sqlInstances) {
     
    $instanceName = $instance.SQLServerInstance
    $version = $instance.SQLVersion

    $versions[$instanceName] = $version
}

$uniqueVersions = @($versions.Values | Select-Object -Unique)

# Step 3: Set Return Variable Based on Comparison
if ($uniqueVersions.Count -eq 1 -and $flag -eq 1) {
    $instanceSQL = "ALL"
    $flag = $instance_count
    $version = $uniqueVersions
} 
else {
    $lowerinstance += Get-LowestVersionInstance -versions $versions -flag $flag
    #$instanceSQL = $lowerinstance.split('\')[1] 
    if($lowerinstance.count -gt 1){
       $flag = $flag + ($lowerinstance.Count - 1)
       $instanceSQL = $lowerinstance | ForEach-Object { ($_ -split '\\')[1] }
       $instanceSQL = $instanceSQL -join ","
    }else{
       $instanceSQL = $lowerinstance.split('\')[1] 
    }
    $version = $versions[$lowerinstance[0]]
    }


if($version -match "2022"){
$patchfile_dir = "$patch_dir\SQL2022"
}
elseif($version -match "2019"){
$patchfile_dir = "$patch_dir\SQL2019"
}
elseif($version -match "2016"){
$patchfile_dir = "$patch_dir\SQL2016"
}
elseif($version -match "2017"){
$patchfile_dir = "$patch_dir\SQL2017"
}


$scriptblock = {
$patchfile_dir = $args[0]
$patch_file = (Get-ChildItem -Path $patchfile_dir).Name
$patch_path = "$patchfile_dir\$patch_file"

#cmd.exe /C $patch_path /quiet /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances

}

if($session -ne $null){
   try{
       $result = Invoke-Command -Session $session -ScriptBlock $scriptblock -ArgumentList $patchfile_dir
       $returnmessage = "success"
   }
   catch
   {
       $Description=$_
   }
   Remove-pssession -session $session
}
else{
   $message = "Unable to establish the session with the server"
   $returnmessage = "fail"
}
