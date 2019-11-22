# escape=`

#For Window 2019 use FROM mcr.microsoft.com/windows/servercore:1809 
FROM mcr.microsoft.com/windows/servercore:ltsc2016

LABEL maintainer "Joe Burrows"

SHELL ["powershell", "-Command"]

# Download SMP Setup Zip, Install Pre-reqs, and cleanup
RUN md C:\Setup; `
    Write-host "Downloading SMP ZIP...."; `
    invoke-WebRequest -outfile C:\Setup\SMP.Zip https://ciresonreleases.blob.core.windows.net/servicemgrportal/PreviousVersions/9.4.0.2016.zip ; `
    unblock-file -path C:\Setup\SMP.Zip; `
    Expand-Archive C:\Setup\SMP.Zip C:\Setup; `
    .\Setup\InstallPreReq.ps1; `
    Remove-Website -Name 'Default Web Site'

RUN CMD.EXE /c "rd /s /q C:\Setup" 
