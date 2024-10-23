$returnmessage = $null
$description = $null
$session = $null
$output = $null
$serverType = $null
Set-StrictMode -Version Latest
$count = 1
$CIName = "segotn18488,segotn18491-001"
$node = $null
$CINameArray = @()
$NextStep = $null
$passivenodes = @{}
$activenodes = @{}
$failoverroles = @()
$uniquePassiveNode = $null
$uniqueActivenode = $null
$instance = $null


 
# Split the CIName into an array if it contains multiple instances
if ($CIName -match ',') {
    $CINameArray += $CIName -split ','
}
else {
    $CINameArray += $CIName # Wrap single instance in an array
}

if ($CIName -match "-") {
 $serverType = "cluster"
} 
else{
 $serverType = "standalone"
}
 
if($serverType -eq "cluster"){

$credential = New-Object System.Management.Automation.PSCredential "vcn\cs-ws-s-SCO-SQL", (ConvertTo-SecureString -String "L878bJ98JLcJ%f7" -AsPlainText -Force)

foreach ($CurrentCIName in $CINameArray) {
   $activenode = $null
   $passivenode = $null
   $SqlServerInst = "$CurrentCIName\SQL1"
   $count += 1
 
   $session = New-PSSession -ComputerName $CurrentCIName -Credential $credential
   $session

   if($session -ne $null) {
      $scriptblock = {
        $sqlserverinstance=$args[0]
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection.ConnectionString = "Server='$sqlserverinstance';Integrated Security=True"
        $SqlConnection.Open()
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd.CommandText = "SELECT SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS ActiveNode;"
        $SqlCmd.Connection = $SqlConnection
        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $SqlAdapter.SelectCommand = $SqlCmd
        $DataSet = New-Object System.Data.DataSet
        $SqlAdapter.Fill($DataSet)
        $SqlConnection.Close()
        return $DataSet.Tables[0]
       }
 
       try{
         $output = Invoke-Command -Session $session -ScriptBlock $scriptblock -ArgumentList "$SqlServerInst"
         $output
         $activenode = $output[1].ActiveNode
       }
       catch{
         $description = $_
       }
    Remove-PSSession -Session $session
    
    

    if($activenode -ne $null){
      $returnmessage = "success"
      [string]$splitserver = $CurrentCIName.Split('-')[0]

      if($activenode -match 'N2'){
        $passivenode = "$splitserver-N1"
      }
      elseif($activenode -match 'N1'){
        $passiveNode = "$splitserver-N2"
      }

      # Store the passive node in the hashtable
      $passivenodes[$CurrentCIName] = $passivenode
      $activenodes[$CurrentCIName] = $activenode    
            
     } #activenode if
   } #session if
  } #forloop 

  if($CINameArray.Count -eq $passivenodes.Count){
    $uniqueActivenode = @($activenodes.Values | Select -Unique)
    $uniquePassiveNode = @($passivenodes.Values | Select -Unique)
    $returnmessage = "success"
    
    if($uniqueactivenode.Count -gt 1){
    $NextStep = "failover"
    $targetNode = $uniqueactivenode[0]       #node on which all instances to be moved(active)
    $onlineNode = $uniquePassiveNode[0]      #node on which we need to make session and run the failover script to make all instances available on on Node
    
    foreach($instance in $activenodes.Keys){
       if($activenodes[$instance] -ne $targetNode){
          $failoverroles += $instance 
       }
    } #failover check forloop
    
    }   
    else{
    $NextStep = "reboot"
    [string]$node = $uniquePassiveNode
    }

  }    #Nodes validation if

  else{
  $returnmessage = "fail"
  $message = "Unable to fetch the required Node details"
  }
} #cluster if

elseif($serverType -eq "standalone"){
  [string]$node = $CINameArray
  $NextStep = "reboot"
  $returnmessage = "success"
}
 
