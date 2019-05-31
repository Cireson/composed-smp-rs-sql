# escape=`

FROM devops0101/smppreq

LABEL maintainer "Joe Burrows"

# Container Build Args - Defaults can be overridden at docker build / compose
ARG smp_zip_uri
ARG PortalUser='.\ContainerAdmin'
ARG PortalPassword='P@ssw0rd'
ARG Hostname

ENV InstallAnalytic=False 
ENV CreateManagementDB=True 
ENV InstallManagementPacks=True 
ENV ExecuteDac=True 
ENV RunCacheBuilderAsService=True 

ENV ManagementDBName="_" 
ENV AnalyticDBName="_"
ENV ManagementServer="_" 
ENV SQLServer="_"
ENV PortalUser ${PortalUser} 
ENV PortalPassword ${PortalPassword} 
ENV ApplicationTitle="_" 
ENV ManagementServerBinaryPath="_" 
ENV AnalystsADGroup="_" 
ENV AssetManagementADGroup="_" 
ENV KnowledgeManagerADGroup="_" 
ENV SMSQLServer="_" 
ENV SMTPServerName="_" 
ENV SMTPServerPort="_" 
ENV SMTPEmailReturnAddress="_" 
ENV smp_zip_uri ${smp_zip_uri}

SHELL ["powershell", "-Command"]

# Container Image Environment Configuration
##Create Local Admin User

RUN NET USER ContainerAdmin $ENV:PortalPassword /add /y /expires:never; `
    NET LOCALGROUP Administrators ContainerAdmin /add

# Download SMP Setup Zip, Container Scripts and Install Pre-reqs
EXPOSE 80 443
RUN md C:\Setup; `
    md C:\Scripts; `
    Write-host "Downloading SMP From $ENV:smp_zip_uri ....."; `
    invoke-WebRequest -outfile C:\Setup\SMP.Zip $env:smp_zip_uri; `
    unblock-file -path C:\Setup\SMP.Zip; `
    Expand-Archive C:\Setup\SMP.Zip C:\Setup

COPY .\Update-Service.ps1 .\Scripts
COPY .\ConnectionStringWorkaround_PR83541.ps1 .\Scripts

## Replace AppPool Account Settings in Installer script to Use LocalSystem 
RUN ((Get-Content "C:\Setup\InstallPortal.ps1") -creplace 'appPool.processModel.identityType = 3', 'appPool.processModel.identityType = 2') | Set-Content "C:\Setup\InstallPortal.ps1"

#Skip Counter that waits for platform Sync
RUN ((Get-Content "C:\Setup\InstallPortal.ps1") -creplace 'counter = 0', 'counter = 31') | Set-Content "C:\Setup\InstallPortal.ps1"

#Execute Workaround for PR83541 - This can be removed if testing versions that are fix > v9.1.0
RUN & \Scripts\ConnectionStringWorkaround_PR83541.ps1 

RUN write-host "Installing the website files ONLY and removing customspace ..... Database DAC and Services will be installed latter after container run"; & {C:\Setup\InstallPortal.ps1 `
-ManagementServer $env:ManagementServer `
-SiteName 'CiresonPortal' `
-SQLServer $env:SQLServer `
-PortalUser $env:PortalUser `
-PortalPassword $env:PortalPassword `
-CreateManagementDB $false `
-ManagementDBName $env:ManagementDBName `
-ExecuteDac $false `
-InstallManagementPacks $false `
-ApplicationTitle $env:ApplicationTitle `
-InstallWebsite $true `
-ManagementServerBinaryPath $env:ManagementServerBinaryPath `
-RunCacheBuilderAsService $false `
-CacheServiceUserName $env:PortalUser `
-CacheServicePassword $env:PortalPassword `
-AnalystsADGroup $env:AnalystsADGroup `
-AssetManagementADGroup $env:AssetManagementADGroup `
-KnowledgeManagerADGroup $env:KnowledgeManagerADGroup `
-SMSQLServer $env:SMSQLServer `
-SMTPServerName $env:SMTPServerName `
-SMTPServerPort $env:SMTPServerPort `
-SMTPEmailReturnAddress $env:SMTPEmailReturnAddress `
-AnalyticServiceUserName $env:PortalUser `
-AnalyticServicePassword $env:PortalPassword `
-InstallAnalytic $false `
-SiteRootPath 'C:\InetPub\' `
-AnalyticFrequencyStartDate '2017-12-09T16:17:43.747224+00:01' `
}; `
CMD.EXE /c "rd /s /q C:\inetpub\ciresonportal\customspace"; `
mkdir C:\inetpub\ciresonportal\logs 

#Check if cachebuilder first before runninng install to prevent unneeded portal reinstall if a container is stopped or started
CMD start-sleep 15; `
$cachebuilderInstalled = get-service cachebuilder -ErrorAction SilentlyContinue ; `
IF(!$CachebuilderInstalled){ & {C:\Setup\InstallPortal.ps1 `
-ManagementServer $env:ManagementServer `
-SQLServer $env:SQLServer `
-PortalUser $env:PortalUser `
-PortalPassword $env:PortalPassword `
-CreateManagementDB $env:CreateManagementDB `
-ManagementDBName $env:ManagementDBName `
-ExecuteDac $env:ExecuteDac `
-InstallManagementPacks $env:InstallManagementPacks `
-ApplicationTitle $env:ApplicationTitle `
-InstallWebsite $false `
-ManagementServerBinaryPath $env:ManagementServerBinaryPath `
-RunCacheBuilderAsService $env:RunCacheBuilderAsService `
-CacheServiceUserName $env:PortalUser `
-CacheServicePassword $env:PortalPassword `
-AnalystsADGroup $env:AnalystsADGroup `
-AssetManagementADGroup $env:AssetManagementADGroup `
-KnowledgeManagerADGroup $env:KnowledgeManagerADGroup `
-SMSQLServer $env:SMSQLServer `
-SMTPServerName $env:SMTPServerName `
-SMTPServerPort $env:SMTPServerPort `
-SMTPEmailReturnAddress $env:SMTPEmailReturnAddress `
-AnalyticServiceUserName $env:PortalUser `
-AnalyticServicePassword $env:PortalPassword `
-InstallAnalytic $env:InstallAnalytic `
-AnalyticDBName $env:AnalyticDBName `
-SiteRootPath 'C:\InetPub\' `
-AnalyticFrequencyStartDate '2017-12-09T16:17:43.747224+00:01' `
}; `
& \Scripts\Update-Service.ps1 "Platform_Cache"; ` 
& \Scripts\Update-Service.ps1 "CacheBuilder"}; ` 
Get-Content -path "C:\inetpub\CiresonPortal\bin\Logs\CacheBuilder.log" -Tail 1 -Wait 