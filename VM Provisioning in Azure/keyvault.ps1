# Set variables for your Key Vault name
$keyVaultName = "<YourKeyVaultName>"

# Retrieve the username secret from Key Vault
$usernameSecret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "Username"
$username = $usernameSecret.SecretValueText

# Retrieve the password secret from Key Vault
$passwordSecret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "Password"
$password = $passwordSecret.SecretValueText

# Output the username and password (for debugging purposes, but avoid doing this in production code)
Write-Host "Username: $username"
Write-Host "Password: $password"
