# escape=`

#For Window 2019 use FROM mcr.microsoft.com/windows/servercore:1809 
FROM mcr.microsoft.com/windows/servercore:ltsc2016

LABEL maintainer "Joe Burrows"

# Container Build Args - Defaults can be overridden at docker build / compose
ARG ServicePassword='P@ssw0rd'

ENV SA_Password="_"
ENV DBName="_"
ENV ApplicationName="Cireson.ControlCenter.Core"
ENV productKey="_"
ENV ServiceUser='.\ContainerAdmin'
ENV ServicePassword ${ServicePassword}
ENV SqlServer="_"
ENV applicationVersion="_"
ENV LdapPath="_"
ENV LdapUserName="_"
ENV LdapPassword='_'
ENV LdapDomain="_"
ENV ConfigMgrSiteServer="_"
ENV ConfigMgrUserName="_"
ENV ConfigMgrPassword="_"
ENV RMDomain="_"
ENV RMUserName="_" 
ENV RMPassword="_"
ENV AdministratorGroupName="_" 
ENV PlatformLogLevel=300

SHELL ["powershell", "-Command"]

# Container Image Environment Configuration
##Create Local Admin User.

RUN NET USER ContainerAdmin $ENV:ServicePassword /add /y /expires:never; `
    NET LOCALGROUP Administrators ContainerAdmin /add

COPY . .

RUN Write-Output "Registering Feeds and installing CpexLets Module"; `
Register-PackageSource "https://cireson.myget.org/F/public/api/v2/" -Name CiresonDevelopmentFeed -Trusted -ProviderName PowerShellGet -Force; `
Install-Module -Name CpexLets; `
Import-Module -Name Cpexlets; `
Connect-CPEXFeed -feedName public

#Run Platform as a Process
CMD start-sleep 10; `
& C:\Run-RemoteSupport-AsWorker.ps1 `
-DBName $env:DBName `
-ApplicationName $env:ApplicationName `
-productKey $env:productKey `
-ServiceUser $env:ServiceUser `
-ServicePassword $env:ServicePassword `
-applicationVersion $env:applicationVersion `
-LdapPath $env:LdapPath `
-LdapUserName $env:LdapUserName `
-LdapPassword $env:LdapPassword `
-LdapDomain $env:LdapDomain `
-ConfigMgrSiteServer $env:ConfigMgrSiteServer `
-ConfigMgrUserName $env:ConfigMgrUserName `
-ConfigMgrPassword $env:ConfigMgrPassword `
-RMDomain $env:RMDomain `
-RMUserName $env:RMUserName `
-RMPassword $env:RMPassword `
-AdministratorGroupName $env:AdministratorGroupName `
-SqlServer $env:SqlServer `
-LogLevel $env:PlatformLogLevel `
-SAPassword $env:SA_Password 
