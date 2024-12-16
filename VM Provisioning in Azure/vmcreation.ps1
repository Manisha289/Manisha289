# Variables
$servicePrincipalName = "MyAutomationSP"
$role = "Contributor"
$scope = "/subscriptions/<SubscriptionId>"

# Create Service Principal

$sp = New-AzADServicePrincipal -DisplayName $servicePrincipalName
Write-Host "Service Principal created successfully."

# Assign Role to Service Principal

New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName $role -Scope $scope
Write-Host "Role assigned successfully."

# Generate Secret

$secret = New-AzADAppCredential -ApplicationId $sp.ApplicationId
Write-Host "Secret generated successfully."


# Define Service Principal credentials
$appId = "Your-AppId"           # Replace with your Service Principal App ID
$tenantId = "Your-TenantId"     # Replace with your Tenant ID
$secret = "Your-Secret"         # Replace with your Service Principal secret

# Convert secret to SecureString
$secureSecret = ConvertTo-SecureString -String $secret -AsPlainText -Force

# Authenticate to Azure using Service Principal
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $appId, $secureSecret

# Login to Azure account
Connect-AzAccount -ServicePrincipal -Credential $credential -TenantId $tenantId

Write-Host "Successfully connected to Azure!"


# Define variables
$resourceGroupName = "MyResourceGroup"
$location = "EastUS"
$vmName = "MyVM"
$vmSize = "Standard_DS1_v2"
$adminUsername = "azureuser"
$adminPassword = ConvertTo-SecureString "YourPassword123!" -AsPlainText -Force
$vnetName = "MyVNet"
$subnetName = "MySubnet"
$addressPrefix = "10.0.0.0/16"
$subnetPrefix = "10.0.0.0/24"
$ipName = "MyPublicIP"
$nicName = "MyNIC"
$imageOffer = "WindowsServer"
$imagePublisher = "MicrosoftWindowsServer"
$imageSku = "2022-datacenter-smalldisk"
$imageVersion = "latest"

# Create Resource Group
Write-Host "Creating Resource Group..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create Virtual Network and Subnet
Write-Host "Creating Virtual Network..."
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location -Name $vnetName -AddressPrefix $addressPrefix
$subnet = Add-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetPrefix -VirtualNetwork $vnet
$vnet | Set-AzVirtualNetwork

# Create Public IP Address
Write-Host "Creating Public IP Address..."
$publicIP = New-AzPublicIpAddress -Name $ipName -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Dynamic

# Create Network Interface
Write-Host "Creating Network Interface..."
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIP.Id

# Specify VM Configuration
Write-Host "Configuring VM..."
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize |
    Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential (New-Object PSCredential ($adminUsername, $adminPassword)) |
    Set-AzVMSourceImage -PublisherName $imagePublisher -Offer $imageOffer -Skus $imageSku -Version $imageVersion |
    Add-AzVMNetworkInterface -Id $nic.Id

# Create Virtual Machine
Write-Host "Creating Virtual Machine..."
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig

Write-Host "Virtual Machine $vmName has been provisioned successfully."
