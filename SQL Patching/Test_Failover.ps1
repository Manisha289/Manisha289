#Written by Denis Dispagne

$script:ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

#Initialize variables here

$nodeFQDN = ("\`d.T.~Ed/{C53BF0F7-B825-4C39-8C74-40A83877A858}.NodeShortNames\`d.T.~Ed/")[0]

$credentialFromSQL = @"
\`d.T.~Ed/{C53BF0F7-B825-4C39-8C74-40A83877A858}.SRVAdminCredentials\`d.T.~Ed/
"@ -split("
")
$credential = New-Object System.Management.Automation.PSCredential $credentialFromSQL[0], (ConvertTo-SecureString -String $credentialFromSQL[1] -AsPlainText -Force)

$library = 
{
	function convert-TxtOuputToObject 
	{
		<#
		.Synopsis Convert output of cluster.exe into powershell exploitable output
		#>
		[CmdletBinding()]
		param (
			[Parameter(Mandatory=$true, ValueFromPipeline=$false)] $in,
			[Parameter(Mandatory=$false, ValueFromPipeline=$false)] $newHeaders = @{}
	    );
		#in order to be run from pipeline, we have to know
		#if we are the first lines or not.
		#may be not impossible but no time to search it more. 

		#remove empty lines
		$n = $in | ? { $_.trim() -ne '' }
		if ($n.length -lt 3 -OR !($n[2] -match '--'))
		{
			write-error "Failed"
			return;
		}

		#headers : n[1] = columns header, n[2] = --- --- columns separators

		#in order to detect columns length
		$lengths=@();
		$header=@{};
		$index = 0;
		
		$dash = ($n[2] -split ' ')
		$l = $n[1]

		foreach ($d in $dash)
		{
			$label = ($l.substring($index, [system.math]::min($d.length,$l.length-$index))).trim()
			if ($newHeaders[$label])
			{   
				$label = $newHeaders[$label]
			}
			$header[$label] = @($index, $d.length);
			$index += 1+$d.length;
		}

		#extract data
		$out = @(); #output is an array of objects
		foreach ($line in $n[3..$n.length])
		{
			$temp = @{}
			foreach($col in $header.keys)
			{
				$startIndex, $length = $header[$col];
				#useful for the last col
				$length = [system.math]::min($length, $line.length-$startIndex)
				#write-host $col ---- $line.substring($startIndex, $length).trim()
				if($col -eq "Status"){$col="State"}
				$temp[$col]= $line.substring($startIndex, $length).trim()
			}
			$out += new-object PSObject -property $temp;
		} 
		return $out;
	}
	
	function Move-ClusterGroup
	{
		[CmdletBinding()]
		param(
			[Parameter(Mandatory=$false, ValueFromPipeline=$true)][PSObject]$InputObject,
			[Parameter(Position=1)][string[]]$Name = $null ,
			[parameter(Mandatory=$false)][string]$Cluster=".",
			[parameter(Mandatory=$false)][string]$Node="",
			[parameter(Mandatory=$false)][int32]$wait=0
		);
		
		begin {
			$r = @();
		}
		
		process {
			if ($InputObject.Name)
			{
				$Name = $InputObject.Name; 
			} 
			if ($Node.length -gt 1)
			{
				$Node = ":$Node";
			}
			if (!$Name)
			{
				return;
			}
			foreach ($n in $Name)
			{
				if($wait -eq 0)
				{
					$result= cluster /cluster:$Cluster group $n /move $node
					$r+=convert-TxtOuputToObject $result;				
				}
				else
				{
					$result= cluster /cluster:$Cluster group $n /move $node /wait:$wait
					$r+=convert-TxtOuputToObject $result;				
				}
				

			}
		}
		end {
			return $r;
		}
	 }
	 
	function Get-ClusterNode
	{
		[CmdletBinding()]
		param(
			 [Parameter(Mandatory=$false, ValueFromPipeline=$true)][PSObject]$InputObject,
			 [Parameter(Position=1)][string[]]$Name ,
			 [parameter(Mandatory=$false)][string]$Cluster="."
		);
	    
		begin {
			$r = @();
			$convertHeaders= @{
				"Group"="Name";
				"Status"="State";
				"Node" = "Name"; 
			}
		}
	  
		process {
			if ($InputObject.Name)
			{
				$Name = $InputObject.Name; 
			} 
			if ($InputObject.Cluster)
			{
				$Cluster = $InputObject.Cluster;
			}
			
			foreach ($n in $Name)
			{  
				$result= cluster /cluster:$Cluster Node $n
				$r+=convert-TxtOuputToObject $result -newHeaders $convertHeaders;
			}
		}
	 
		end {
			return $r;
		}   
	}
	
	function Get-ClusterGroup 
	{
		[CmdletBinding()]
		param(
			[Parameter(Mandatory=$false, ValueFromPipeline=$true)][PSObject]$InputObject,
			[Parameter(Position=1)][string[]]$Name ,
			[parameter(Mandatory=$false)][string]$Cluster="."
		);
		
		begin {
			$r = @();  
			$convertHeaders= @{
				"Group"="Name";
				"Status"="State";
				"Node" = "OwnerNode";
			}
		}
		
		process {
			if ($InputObject.Cluster)
			{
				$Cluster = $InputObject.Cluster;
			}
	    
			if ($InputObject.Name)
			{
				$OwnerNode = $InputObject.Name; 
				foreach ($n in $OwnerNode)
				{  
					$result = cluster /cluster:$Cluster GROUP /Node:$n
					$r+=convert-TxtOuputToObject $result -newHeaders $convertHeaders;
				}
			} else {
				foreach ($n in $Name)
				{  
					$result = cluster /cluster:$Cluster GROUP $n
					$r+=convert-TxtOuputToObject $result -newHeaders $convertHeaders;
				}
			}
		}
		
		end {
			return $r;
		}
	}

}

$specificLibrary =
{
	function Test-Failover
	{
		[CmdletBinding()]
		param(
			#Groups to failover
			[Parameter(Mandatory=$True,Position=1)]
			[Array]$groups,
			#Node to failover ressources to
			[Parameter(Mandatory=$True,Position=2)]
			[string]$nodeName
		);
		[bool]$return = $false
		
		foreach($group in $groups)
		{
			[int]$retry = 0
			if($group.ownerNode -ne $node )
			{
				do
				{
					write-verbose "failing over $group.name"
					$failedGroup = $null
					try
					{
						$retry ++
						$failedGroup = Move-clusterGroup -Name $group.Name -node $nodeName -Wait 450 -ErrorAction stop | Where-Object { ($_.State -ne $group.State -and $_.State -ne $null) }
					}
					catch
					{
						write-verbose "error"
						$failedGroup = "timeout"
					}
					if($failedGroup -eq $null)
					{
						write-verbose "success"
						$return = $true
					}

				}while($return -ne $true -and $retry -lt 3)
			}
			else
			{
				$return = $true
			}
			if($return -eq $false)
			{
				#Stop failing over more groups
				break
			}
		}
		return $return
	}

}

function Test-ClusterFailover
{
	[CmdletBinding()]
	param(
		#Cluster FQDN
		[Parameter(Mandatory=$True,Position=1)]
		$nodeFQDN,
		#Credentials for winrm to connect 
		[Parameter(Mandatory=$True,Position=2)]
		$credential
	);
	$session = $null
	[hashtable]$output = @{"success" = "error"; "error" = $null}
	
	try
	{
	    	$session  = New-PSSession -ComputerName $nodeFQDN -credential $credential -EA silentlycontinue
		Write-Verbose "Session opened"
		if($session -eq $null)
		{
			$IPAddress = (Test-Connection $nodeFQDN -count 1 -Quiet).ipv4address.IPAddressToString
			$session  = New-PSSession -ComputerName $IPAddress -credential $credential;
		}
	} 
	catch 
	{
		Write-Verbose "Error : Can't connect to $nodeFQDN";
		$output.success = "error"
	    $output.error = "CSP001 : Can't connect to $nodeFQDN using WinRM" + $error[0].exception ;
	}
	#If the session was created
	if($session -ne $null)
	{
		#Testing if failover module is present
		if( (invoke-command -session $session -scriptblock{(Get-Module -ListAvailable -all | where-object {$_.Name -eq "Failoverclusters"} | Measure-Object).count}) -eq 1)
		{
			#Importing the real ps module failoverClusters
			write-verbose "Importing the real ps module failoverClusters"
			invoke-command -session $session -scriptblock{Import-module FailoverClusters}
		}
		else
		{
			#no failover cluster cmdlets so use the functions library instead
			write-verbose "Loading functions library into session"
			invoke-command -session $session -scriptblock $library;
		}
		
		#Loading specific testing functions library into session
		write-verbose "Loading specific testing functions library into session"
		invoke-command -session $session -scriptblock $specificLibrary;
		
		#Do the failover
		$output = Invoke-Command -Session $session -ScriptBlock {
			#Initialize variables
			[hashtable]$output = @{"success" = "success"; "error" = $null}
			
			#Verrify that all nodes are up
			$unhealthyNodes = Get-ClusterNode | Where-Object {$_.State -ine "Up"}
			
			#Retrieve nodes names ordered
			$nodes = Get-ClusterNode | Select-Object -ExpandProperty Name | sort-object 

			#Logging function
			$groups = Get-ClusterGroup | Sort-Object State
			foreach($group in $groups)
			{
				$nodeLog +=, ("" + $group.Name + " is in " + $group.State + " state on node " + $group.OwnerNode + " ")
			}
			$nodeLog = $nodeLog -join(",")

			#retrieve only groups that are online or offline
			$groups = Get-ClusterGroup | Where-Object {$_.State -ieq "online" -and $_.Name -notlike  "Available Storage" -and $_.Name -notlike "*decom*"} | Sort-Object State
			
			if($groups -ne $null -and $unhealthyNodes -eq $null)
			{
				#Test Cluster load
				foreach($node in $nodes)
				{
					write-verbose "failing over to node $node"
					if(((Test-Failover -node $node -groups $groups) -eq $true) -and ($output.success -eq "success"))
					{
						$output.success = "success"	
					}
					else
					{
						$output.success = "error"
						$output.error = "CSP005 : There was a problem when load testing node $node";
						break
					}
					$groups = $null
					$groups = Get-ClusterGroup | Where-Object {$_.State -ieq "online" -and $_.Name -notlike  "Available Storage" -and $_.Name -notlike "*decom*"} | Sort-Object State
				}
			}
			else 
			{
				$output.success = "error"
				$output.error = "CSP004 : No groups to failover or unhealthy nodes state";
			}
			$output.error += (" "+$nodeLog)
			#Return the output outside of the session
			Return $output
		}
		#Delete the session
		Remove-PSSession $session;
	}
	else
	{	
		#If session is null then it couldn't be created
		Write-Verbose "Error : Can't open session to $nodeFQDN";
		$output.success = "error"
	    $output.error = "CSP001 : Can't connect to $nodeFQDN using WinRM" + $error[0].exception ;
	}
	#Return the output outside of the function
	Return $output
}

$TCFOutput =  Test-ClusterFailover -nodeFQDN $nodeFQDN -credential $credential
$succeed = $TCFOutput.success
$errorMessage = $TCFOutput.error
