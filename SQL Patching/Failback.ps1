#Written by Denis Dispagne

$script:ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$nodeFQDN = "segotn18491-001.vcn.ds.volvo.net"

$credential = New-Object System.Management.Automation.PSCredential "vcn\cs-ws-s-SCO-SQL", (ConvertTo-SecureString -String "L878bJ98JLcJ%f7" -AsPlainText -Force)
[int]$flag = 1
$returnmessage = $null
$passiveNode = $null
$activeNode = $null
$FROutput = $null
$session = $null

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
				if($col -eq "Status"){$col="State"}
				$temp[$col]= $line.substring($startIndex, $length).trim()
			}
			$out += new-object PSObject -property $temp;
		} 
		return $out;
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
	 
	function Resume-ClusterNode
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
				$result= cluster /cluster:$Cluster Node $n /resume
				$r+=convert-TxtOuputToObject $result -newHeaders $convertHeaders;
			}
		  }
		  
		 end {
			return $r;
		  }   
	}

	function start-ClusterGroup
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
				"Status"="State";
				"Node" = "OwnerNode";
				"Group" = "Name" 
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
				$result= cluster /cluster:$Cluster group $n /online
				$r+=convert-TxtOuputToObject $result -newHeaders $convertHeaders;
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

} #endof screenblock

$specificLibrary =
{
	function Failback-ToPatchedNode
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
		[bool]$return = $true
		
		foreach($group in $groups)
		{
			if($group.ownerNode -ne $node )
			{
				write-verbose "failing over $group.name"
				$failedGroup = $null
				try
				{
					$failedGroup = Move-clusterGroup -Name $group.Name -node $nodeName -Wait 450 -ErrorAction stop | Where-Object { ($_.State -ne $group.State -and $_.State -ne $null) }
				}
				Catch
				{
					$failedGroup = "Timeout"
				}
				if($failedGroup -ne $null)
				{
					write-verbose "failed"
					$return = $false
					break
				}	
			}
		}
		return $return
	}
}

function Failback-Resources 
{
	[CmdletBinding()]
	param(
		#Computer name to connect to
		[Parameter(Mandatory=$True,Position=1)]
		$nodeFQDN,
		#credential for winRM connection
		[Parameter(Mandatory=$True,Position=2)]
		$credential
	);
	$session = $null
	[hashtable]$output = @{"error" = $null; "success" = "false"}
	
	Write-Verbose "All groups will be failed back to node $nodeFQDN"
	
	try
	{
		$session  = New-PSSession -ComputerName $nodeFQDN -credential $credential -EA silentlycontinue
		Write-Verbose "Session opened"
		if($session -eq $null)
		{
			$IPAddress = (Test-Connection $nodeFQDN -count 1).ipv4address.IPAddressToString
			$session  = New-PSSession -ComputerName $IPAddress -credential $credential;
		}
	} 
	catch 
	{
		Write-Verbose "Error : Exception while connecting to computer";
		$output.success = "false"
		$output.error = "CSP001 : Cannot connect to $nodeFQDN using WinRM" + $error[0].exception ;
	}
	if($session -ne $null)
	{
		#Testing if failover module is present
		if( (invoke-command -session $session -scriptblock{(Get-Module -ListAvailable -all | where-object {$_.Name -eq "Failoverclusters"} | Measure-Object).count}) -eq 1)
		{
			#Importing the real ps module failoverClusters
			write-verbose "Importing the real ps module failoverClusters"
			invoke-command -session $session -scriptblock{
				Import-module FailoverClusters
			}
		}
		else
		{
			#no failover cluster cmdlets so use the functions library instead
			write-verbose "Loading functions library into session"
			invoke-command -session $session -scriptblock $library;
		}	

		#Import the mandatory library
		write-verbose "Loading specific functions library into session"
		invoke-command -session $session -scriptblock $specificLibrary;
		
		#Trying to resume the node and move back the ressources
		write-verbose "Trying to resume node and to move back all ressources to node $nodeFQDN"			
		$resumeAndFailback = invoke-command -session $session -ScriptBlock {
			#Hashtable to record output
			[hashtable]$output = @{"error" = $null; "success" = "error"}
			$resumeOutput = $null
			$nodeName = (get-childitem env:computername).value;
			$groups = Get-ClusterGroup | where-object {$_.Name -notlike  "Available Storage" -and $_.state -ne "failed"  -and $_.Name -notlike "*decom*" -and $_.State -ieq "online"}
			if((Get-ClusterNode -name $nodeName | Where-Object {$_.State -ine "up"}) -ne $null)
			{
				$resumeOutput = Resume-ClusterNode $nodeName | Where-Object {$_.State -ine "up"}
			}
			#If resuming completed successfully
			if($resumeOutput -eq $null -OR $groups -ne $null)
			{
				if((Failback-ToPatchedNode -groups $groups -nodeName $nodeName) -eq $true)
				{
						#Success
						write-verbose "Failback succeeded for all groups on node $nodeName"
						$output.success = "success"
				}
				else
				{
					#There was an error during the ressource failover 
					write-verbose "There was an error while failingback resources"
					$output.success = "error"
					$output.error = "CSP018 : There was an error while failing back resources"
				}
			}
			else
			{
				$output.success = "error"
				$output.error = "CSP017 : The node wasn't in UP state after resuming it or no groups retrieved"
			}
			return $output
		}
		
		#Setting output values from the invoke command
		$output.success = $resumeAndFailback.success
		$output.error = $resumeAndFailback.error
		
		#Close session
		Write-Verbose "Closing session"
		#Remove-PSSession $session;
	}
	else
	{
		Write-Verbose "Error : $nodeFQDN is pingable but cannot open winRM session";
		$output.success = "false"
		$output.error = "CSP001 : Cannot connect to $nodeFQDN using WinRM" + $error[0].exception ;
	}

	#Return hashtable containing Sucess status and error if any 
	return $output;
} 

$FROutput = Failback-Resources -nodeFQDN $nodeFQDN -credential $credential
$succeed = $FROutput.success
$errorMessage = $FROutput.error


if($succeed -eq "success"){
$returnmessage = "success"
}
else{
$returnmessage = "fail"
}
