Param(
    $ServiceName
)
        Stop-Service $ServiceName -Force -ErrorAction SilentlyContinue
        write-host "Updating $ServiceName to Run As local System And Restarting"
        $params = @{
        "Namespace" = "root\CIMV2"
        "Class" = "Win32_Service"
        "Filter" = "Name='$ServiceName'"
        }
        $service = Get-WmiObject @params
       $service.Change($null,
            $null,
            $null,
            $null,
            $null,
            $null,
            "LocalSystem",
            $null,
            $null,
            $null,
           $null) 
    #sc.exe config $ServiceName obj= "NT AUTHORITY\NETWORK SERVICE" password= ""
    Start-sleep 2
    start-Service $ServiceName 