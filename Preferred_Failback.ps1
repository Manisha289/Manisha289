#Written by Denis Dispagne

$script:ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$FPOOutput =  $null
$succeed = $null
$errorMessage = $null

#Initialize variables here
$nodeFQDN = "segotn18491-N2.vcn.ds.volvo.net"


$credential = New-Object System.Management.Automation.PSCredential "vcn\cs-ws-s-SCO-SQL", (ConvertTo-SecureString -String "L878bJ98JLcJ%f7" -AsPlainText -Force)

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
	 
	function Get-ClusterOwnerNode
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
		"Preferred Owner Nodes"="OwnerNodes";
		"ClusterObject" = "ClusterObject"
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

			$j = 0
			foreach ($n in $Name)
			{
				$result = cluster /cluster:$Cluster GROUP $n /listOwners

				$size = $result[8+$j].length
				$space = $size+1-$result[10].length
				if($size -le 0)
				{
					$size = $result[8].length
				}

				if($j -eq 0)
				{
					$result[6] += " ClusterObject"
					$result[8] += " --------------------"
				}
				
				for($k=0; $k -lt $result.count - 10; $k++)
				{
					if($result[$k+10].length -ne 0)
					{
						for ($i=0; $i -lt $space ; $i++)
						{
							$result[$k+10] += " "
						}
						$result[$k+10] += "$n"
					}
				}
				$r+=convert-TxtOuputToObject $result -newHeaders $convertHeaders;
				$j++
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

}

$specificLibrary =
{
	function Move-ClusterGroupsToPreferredOwner
	{
		$return = "success"
		$clustergroups = Get-ClusterGroup | Where-Object {$_.Name -notlike  "Available Storage" -and $_.state -ne "failed"}
		foreach ($group in $clustergroups)
		{
			$CGName = $group.Name
			if($group.OwnerNode.Name -eq $null)
			{
				$CurrentOwner = $group.OwnerNode
			}
			else
			{
				$CurrentOwner = $group.OwnerNode.Name
			}
			if( !((($group | Get-ClusterOwnerNode).OwnerNodes |measure-object).Count -eq 0 -or ($group | Get-ClusterOwnerNode).OwnerNodes -eq ""))
			{
				if(($group | Get-ClusterOwnerNode).Ownernodes[0].Name -eq $null)
				{
					$PreferredOwner = ($group | Get-ClusterOwnerNode).Ownernodes
				}
				else
				{
					$PreferredOwner = ($group | Get-ClusterOwnerNode).Ownernodes[0].Name
				}
				if ($CurrentOwner -ne $PreferredOwner)
				{
					try
					{
						$failedGroup = Move-ClusterGroup -Name $CGName -Node $PreferredOwner -Wait 450 -ErrorAction stop | Where-Object { ($_.State -ne $group.State -and $_.State -ne $null) }
					}
					catch
					{
						$failedGroup = "timeout"
					}
					if($failedGroup -ne $null)
					{
						$return = "failed"
					}
				}
			}
		}
		return $return
	}
}

function Failback-ToPreferredOwner
{
	[CmdletBinding()]
	param(
		#node name to connect to
		[Parameter(Mandatory=$True,Position=1)]
		$nodeFQDN,
		#credentials for winrm connexion
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
			$IPAddress = (Test-Connection $nodeFQDN -count 1).ipv4address.IPAddressToString
			$session  = New-PSSession -ComputerName $IPAddress -credential $credential;
		}
	} 
	catch 
	{
		Write-Verbose "Error : Can't connect to $nodeFQDN";
		$output.success = "error"
		$output.error = "CSP001 : Cannot connect to $nodeFQDN using WinRM" + $error[0].exception ;
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
			
			$pausedNodes = Get-ClusterNode | Where-Object{$_.State -eq "paused"}
			if($pausedNodes -ne $null)
			{
				foreach($pausedNode in $pausedNodes)
				{
					$resumeOutput = Resume-ClusterNode -Name $pausedNode.name | where-object {$_.State -ne "Up"}
					if($resumeOutput -ne $null)
					{
						break
					}
				}
			}
			if($resumeOutput -eq $null)
			{
				$FailbackOutput = Move-ClusterGroupsToPreferredOwner
				if($FailbackOutput -eq "failed")
				{
					$output.success = "error"
					$output.error = "CSP020 : One or many groups were not failedback correctly to their preferred owner"
				}
				else
				{
					$output.success = "success"
				}
			}
			else
			{
				$output.success = "error"
				$output.error = "CSP019 : the node wasn't in up state after resuming it"
			}
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
		$output.error = "CSP001 : Cannot connect to $nodeFQDN using WinRM" + $error[0].exception ;
	}
	#Return the output outside of the function
	Return $output
}

$FPOOutput =  Failback-ToPreferredOwner -nodeFQDN $nodeFQDN -credential $credential
$succeed = $FPOOutput.success
$errorMessage = $FPOOutput.error
