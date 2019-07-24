Param(
$DBName = "RemoteSupport",
$ServiceName = "RemoteSupportService",
$ApplicationName = "Cireson.ControlCenter.Core",
$Installpath = "C:\CiresonPlatform\platform",
$productKey = "",
$ServiceUser = '.\ContainerAdmin',
$ServicePassword = '',
$SqlServer = "",
$applicationVersion = "",
$platformVersion = "",
$HTTPPort = "80",
$SSLPort = "443",
$LdapPath = "",
$LdapUserName = "",
$LdapPassword = '',
$LdapDomain = "",
$ConfigMgrSiteServer = "",
$ConfigMgrUserName = "",
$ConfigMgrPassword = "",
$RMDomain = "",
$RMUserName = "",
$RMPassword = "",
$AdministratorGroupName = "",
$Hostname,
$SAPassword,
$LogLevel = 300
)

Import-Module -Name Cpexlets

Function Run-PlatformAsAprocess {

    $applicationId = $ApplicationName
    $sqlServerName = $sqlserver
    $url = 'http://*:80/'

    function RunPlatform($path, $u, $cs, $pk){
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = "$path\Cireson.Platform.Host.exe"
        $pinfo.UseShellExecute = $true
        $pinfo.Arguments = @("-u", """$u""", "-c", """$cs""", "-pk", """$pk""", "-worker", "1")
        $pinfo.CreateNoWindow = $true
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $p.Start() | Out-Null
    }
    
    (Get-Process -Name *Cireson.Platform.Host | Stop-Process -ErrorAction SilentlyContinue)
    
    
    $stagingPath = "$($env:TEMP)\$([Guid]::NewGuid())"
    
    $appPackage = Get-CPEXPackage -outputPath $stagingPath -id $applicationId -version $applicationVersion
    
    
    $localPath = "$($env:ProgramData)\Cireson.Platform.Host\CpexLocal"
    New-Item -Path $localPath -ItemType Directory -ErrorAction SilentlyContinue
    
    Copy-Item -Path $appPackage.PackagePath -Destination $localPath -ErrorAction SilentlyContinue
    
    $PlatformVersion = Get-CPEXPlatformVersionForApplication -package $appPackage -id $applicationId 
    
    if([string]::IsNullOrWhiteSpace($PlatformVersion)){
        Write-Output "Unable to determine platform version. Check CPEX information and try again."
        exit
    }
    
    $platformPath = "$($env:TEMP)\CiresonTestRuntime\$PlatformVersion"
    
    if(!(test-path -Path "$PlatformPath\Cireson.Platform.Host.exe") -or $force){
        #install platform binaries if the version does not exist
        $platformPackage = Get-CPEXPlatform -platformVersion $platformVersion
         
         #The Cireson Platform Nuget package has a Cireson.Platform.Host.zip entry, we need to get that, and extract it to the output folder
        [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")
        $platformZip  = $platformPackage.Package.GetEntry("content/PlatformRuntime/Cireson.Platform.Host.zip")
        $platformZipStream = $platformZip.Open()
        Remove-Item -Path $platformPath -Recurse -Force -ErrorAction SilentlyContinue    
        [System.IO.Compression.ZipFileExtensions]::ExtractToDirectory($platformZipStream, $platformPath)
    }
    
    $SACreds = New-CPEXCredential -username 'sa' -password $SAPassword
    #$sqlServerName = "tcp:$SqlServername"
    $connectionString = Get-CPEXPlatformConnectionString -sqlServerName $sqlServerName -databaseName $dbName -useSqlServerLogin $true -sqlServerCredentials $SACreds
    #$connectionString = $connectionString + ";Network Library=DBMSSOCN;"
    $connectionString
    
    #launch platform
    RunPlatform -path $platformPath -u $url -cs $connectionString -pk $ProductKey
    
    $localUrl = $url.Replace("*","localhost")
    
    Write-Output "Waiting for Platform start"
    
    $response = Wait-CpexPlatformRunning -platformRootUri "$localUrl/api"
    
    Set-CPEXSystemSettingRaw -key LogLevel -value $LogLevl -platformRootUri "$localUrl/api"
    
    Write-Output "Installing $applicationId"
    
    Install-CPEXApplication -applicationId $applicationId -version $applicationVersion -platformUrl "$localUrl/api" 
    
    $response = Wait-CpexExtensionInstalled -applicationId $applicationId -applicationVersion $applicationVersion -platformRootUri "$LocalUrl/api"

}

Function Configure-ControlCenter{

$LocalUrl = "http://localhost:$HTTPPort"
$creds = New-CPEXCredential -username $ServiceUser -password $ServicePassword

Write-output "Waiting for install"
$response = Wait-CpexExtensionInstalled -applicationId $ApplicationName -applicationVersion $applicationVersion -platformRootUri "$LocalUrl/api" -credential $creds -timeoutSeconds 850

Write-Output "Configuring Application"
Add-CPEXProviderRoleMap -providerRole $AdministratorGroupName -applicationRole Administrators -platformRootUri "$localUrl/api" -credential $creds

#run cc configuration.
#todo: setup to configure for hosted endpoints.
#############################################################################################################################
$body = @{SystemSettings = 
    @{
        '@odata.type'='#Cireson.ControlCenter.Core.ActiveDirectoryAdapter.Models.AdAdapterConfiguration'
        LdapPath= $LdapPath
        UserName= $LdapUserName
        Password= $LdapPassword
        Domain= $LdapDomain
    }
}
Invoke-CPEXPlatformApiCommand -method post -command "Set_SystemSetting" -body $body -platformRootUri "$localUrl/api" -credential $creds
#############################################################################################################################

#############################################################################################################################
$body = @{SystemSettings = 
    @{
        '@odata.type'='#Cireson.ControlCenter.Core.ConfigMgrAdapter.Models.AdapterConfiguration'
        ConfigMgrSiteServer=$ConfigMgrSiteServer
        ConfigMgrUserName=$ConfigMgrUserName
        ConfigMgrPassword=$ConfigMgrPassword
        MaxParallelism=2
    }
}
Invoke-CPEXPlatformApiCommand -method post -command "Set_SystemSetting" -body $body -platformRootUri "$localUrl/api" -credential $creds
#############################################################################################################################

#############################################################################################################################
$body = @{SystemSettings = 
    @{
        '@odata.type'='#Cireson.RemoteManage.PlatformServices.Adapter.Models.CimAdapterConfiguration'
        Domain= $RMDomain
        UserName= $RMUserName
        Password= $RMPassword
    }
}
Invoke-CPEXPlatformApiCommand -method post -command "Set_SystemSetting" -body $body -platformRootUri "$localUrl/api" -credential $creds
############################################################################################################################
}

#________________________________________
#
#      Run the script
#________________________________________

Write-output "Starting Remote Support as worker process...."
Run-PlatformAsAprocess
Configure-ControlCenter

Get-Content -path "C:\ProgramData\Cireson.Platform.Host\PlatformLog*" -Tail 1 -Wait  -ErrorAction SilentlyContinue
