Param(
    [parameter(Mandatory = $true)]
    [string]$server,
    [parameter(Mandatory = $true)]
    [string]$folder_path,
    [parameter(Mandatory = $true)]
    [string]$read_users,
    [parameter(Mandatory = $true)]
    [string]$write_users,
    [parameter(Mandatory = $true)]
    [string]$modify_users,
    [parameter(Mandatory = $true)]
    [string]$deploy_user_id,
    [parameter(Mandatory = $true)]
    [SecureString]$deploy_user_secret
)

Write-Output 'Create Folder Action Started'
$credential = [PSCredential]::new($deploy_user_id, $deploy_user_secret)
$so = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

$script = {
  $item = $Using:folder_path
  $readPermissionsTo = $Using:read_users
  $writePermissionsTo = $Using:write_users
  $modifyPermissionsTo = $Using:modify_users

  Write-Host "Creating folder $item with permissions."

  if((Test-Path $item))
  {
    Write-Host "Folder $item already exists"
  }
  else
  {
    New-Item -ItemType directory -Path $item -force
  }

  # Check item exists
  if(!(Test-Path $item))
  {
    throw "$item does not exist"
  }

  # Assign read permissions

  if($readPermissionsTo)
  {
    $users = $readPermissionsTo.Split(",")
    foreach($user in $users)
    {
      Write-Host "Adding read permissions for $user"
      $acl = Get-Acl $item
      $acl.SetAccessRuleProtection($False, $False)
      $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
      $user, "Read", "ContainerInherit, ObjectInherit", "None", "Allow")
      $acl.AddAccessRule($rule)
      Set-Acl $item $acl
    }
  }

  # Assign write permissions

  if($writePermissionsTo)
  {
    $users = $writePermissionsTo.Split(",")
    foreach($user in $users)
    {
      Write-Host "Adding write permissions for $user"
      $acl = Get-Acl $item
      $acl.SetAccessRuleProtection($False, $False)
      $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
      $user, "Write", "ContainerInherit, ObjectInherit", "None", "Allow")
      $acl.AddAccessRule($rule)
      Set-Acl $item $acl
    }
  }

  # Assign modify permissions

  if($modifyPermissionsTo)
  {
    $users = $modifyPermissionsTo.Split(",")
    foreach($user in $users)
    {
      Write-Host "Adding modify permissions for $user"
      $acl = Get-Acl $item
      $acl.SetAccessRuleProtection($False, $False)
      $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
      $user, "Modify", "ContainerInherit, ObjectInherit", "None", "Allow")
      $acl.AddAccessRule($rule)
      Set-Acl $item $acl
    }
  }

  Write-Host "Create Folder Action Completed"
}

Invoke-Command -ComputerName $server `
    -Credential $credential `
    -UseSSL `
    -SessionOption $so `
    -ScriptBlock $script
