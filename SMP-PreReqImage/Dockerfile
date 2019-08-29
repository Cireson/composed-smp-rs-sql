# escape=`

#For Window 2019 use FROM mcr.microsoft.com/windows/servercore:1809 
FROM mcr.microsoft.com/windows/servercore:ltsc2016

LABEL maintainer "Joe Burrows"

SHELL ["powershell", "-Command"]

RUN write-host "Downloading netfx3 package....." ; `
invoke-WebRequest -outfile C:\microsoft-windows-netfx3-ondemand-package.cab https://ciresonresources.blob.core.windows.net/docker/microsoft-windows-netfx3-ondemand-package.cab ; `
Install-WindowsFeature -Name NET-Framework-Core -Source C:\ -Verbose ; `
Remove-Item microsoft-windows-netfx3-ondemand-package.cab -force

# Download SMP Setup Zip, Install Pre-reqs, and cleanup
RUN md C:\Setup; `
    Write-host "Downloading SMP ZIP...."; `
    invoke-WebRequest -outfile C:\Setup\SMP.Zip https://ciresonreleases.blob.core.windows.net/servicemgrportal/PreviousVersions/9.0.0.2016.zip ; `
    unblock-file -path C:\Setup\SMP.Zip; `
    Expand-Archive C:\Setup\SMP.Zip C:\Setup; `
    #Download and install 2017 DAC framework(This can be removed when SQL 2017 is fully supported and dac gets packaged in download)
    write-host "Download 2017 DAC framework...."; `
    invoke-WebRequest -outfile C:\Setup\InstallationFiles\MSI\2017Dacframeworkx86.msi https://download.microsoft.com/download/F/9/3/F938FCDD-3FAF-40DF-A530-778898E2E5EE/EN/x86/DacFramework.msi; `
    invoke-WebRequest -outfile C:\Setup\InstallationFiles\MSI\2017Dacframeworkx64.msi https://download.microsoft.com/download/F/9/3/F938FCDD-3FAF-40DF-A530-778898E2E5EE/EN/x64/DacFramework.msi; `
    .\Setup\InstallPreReq.ps1; `
    Remove-Website -Name 'Default Web Site'

RUN CMD.EXE /c "rd /s /q C:\Setup" 
