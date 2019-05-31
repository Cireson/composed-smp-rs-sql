#Workaround for PR83541 - Install Script defaults to the wrong SQL Server Param for the service manager database
$Before = '$ServiceManagerConnectionString =[String]::Format("Server={0};Database={1};Trusted_Connection=True;", $SQLServer, $SMDBName)'
$After = '$ServiceManagerConnectionString =[String]::Format("Server={0};Database={1};Trusted_Connection=True;", $SMSQLServer, $SMDBName)'

((Get-Content "C:\Setup\InstallPortal.ps1").replace($Before, $After)) | Set-Content "C:\Setup\InstallPortal.ps1"
