# Define the resource groups and the target node
$failoverroles = "segotn18491-001"
$targetNode = 'segotn18491-N2'
$onlineNode = 'segotn18491-N2'  # Replace with the remote server's name or IP
$roles = @()

#$resourceGroups = @($failoverroles, ($failoverroles -replace '-\d+$', '-DTC'))
$returnMessage = "success"
$outcome = $null
$result = $null
$description = $null

if($failoverroles -match ','){
  $roles += $failoverroles -split(',')
}
else{
  $roles += $failoverroles
}

$credential = New-Object System.Management.Automation.PSCredential "vcn\cs-ws-s-SCO-SQL", (ConvertTo-SecureString -String "L878bJ98JLcJ%f7" -AsPlainText -Force)
$session = New-PSSession -ComputerName $onlineNode -Credential $credential

# Loop through each resource group and move it to the target node on the remote server
foreach ($role in $roles) {

     $scriptBlock = {
       $roleName = $args[0]
       $targetNode = $args[1]
                    
       #Write-Host "Moving $roleName to $targetNode..."
      # $moveCmd = cluster.exe group $roleName /move:$targetNode

       $groupinfo = cluster.exe group $roleName /stat
       $groupdetails = $groupinfo | Where-Object {$_ -match $roleName}
      
       $currentNode = ($groupdetails -split "\s{2,}" | Select-Object -Index 2).Trim()

       Write-Host "$role = $currentNode"
       
       if ($currentNode -eq $targetNode) {
          return "success"
       } else {
           return "fail"
       }
    }
    try{
       $outcome = Invoke-Command -Session $session -ScriptBlock $scriptBlock -ArgumentList $role, $targetNode
    }
    catch{
       $description = $_
    }
   
    if ($outcome -ne "success" -or $outcome -eq $null) {
       $returnMessage = "Fail"
       break  # Exit the loop on failure
    }
    else{
      $returnMessage = "success"
    }

}  #forloop

if($returnMessage -eq "success"){

$dtcrole = $roles[0] -replace '-\d+$', '-DTC'
$targetNode = "segotn18491-N2"

$scriptBlock = {
    $role = $args[0]
    $targetNode = $args[1]
    Write-host $role

    $dtcGroup = cluster.exe group $role /stat
    $dtc = $dtcGroup | Where-Object {$_ -match $role}
    $dtcActiveNode = ($dtc -split "\s{2,}" | Select-Object -Index 2).Trim()
    Write-Host "dtc group = $dtcGroup"
    Write-host $dtcActiveNode

    if($dtcActiveNode -ne $targetNode){
      # Move DTC to the common node
      #cluster.exe group $role /move:$targetNode

      $dtcinfo = cluster.exe group $role /stat
      $dtcdetails = $dtcinfo | Where-Object {$_ -match $role}
      
      $dtccurrentNode = ($groupdetails -split "\s{2,}" | Select-Object -Index 2).Trim()

      Write-Host $dtcinfo
       
       if ($dtccurrentNode -eq $targetNode) {
          return $dtcActiveNode
       } else {
           return "fail"
       }
    }  #switch node if
    else{
      return $dtcActiveNode
    }

  }  #scripblock
  
   try{
       $result = Invoke-Command -Session $session -ScriptBlock $scriptBlock -ArgumentList $dtcrole, $targetNode
    }
    catch{
       $description = $_
    }

    if($result -eq "fail" -or $description -ne $null){
      $returnMessage = "fail"
    }
    else{
      $dtcactiveNode = $result
    }


} #returnmsg if



    


