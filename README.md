![DOCKER](https://github.com/jjburr/composed-ciresonportal-sql/blob/master/Volumes/CustomSpace/login.png)

# Containerized Cireson Portal, Remove Manager & SQL for Dev Environments


Compose container Dev environments for the Cireson Portal for Service Manager, Remote Support and container SQL. Easily define and build the for different versions in an environment file.

1. Create Docker Host by Installing Docker & Compose on a Domain Joined Windows 2016\2019 VM
- Run Install_Docker_and_Docker-Compose.ps1
- Recommend also installing VS code to make it easier to work with.
2. Create KDS Root Key for Group Managed Service Accounts in your see below blog for more info:
https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/manage-serviceaccounts
- If lab environment use the workaround in the above article to speed up key creation: (For single-DC test/lab environments ONLY)	
```
add-KdsRootKey -EffectiveTime (Get-Date).AddHours(-10)
```
3. Create x3 Group Policy Service Accounts, 1 for SQL, 1 for Dev, 1 for UAT. Targeting an AD group that contains your docker host computers, and replacing .EVALLAB.LOCAL with your domain name:
```
New-ADServiceAccount-name GMSA_DOCKER -DNSHostName GMSA_DOCKER.EVALLAB.LOCAL -PrincipalsAllowedToRetrieveManagedPassword 'EVALLAB DockerHosts'
New-ADServiceAccount-name GMSA_DOCKERSQL -DNSHostName GMSA_DOCKERSQL.EVALLAB.LOCAL -PrincipalsAllowedToRetrieveManagedPassword 'EVALLAB DockerHosts'
New-ADServiceAccount-name GMSA_DOCKERUAT -DNSHostName GMSA_DOCKERUAT.EVALLAB.LOCAL -PrincipalsAllowedToRetrieveManagedPassword 'EVALLAB DockerHosts'
   ````
4. Add each of the 3 GMSA Accounts to Docker Host
```
   Add-WindowsFeature RSAT-AD-PowerShell 
   Import-Module ActiveDirectory 
   Install-AdServiceAccount GMSA_DOCKER 
   Test-AdServiceAccount GMSA_DOCKER
   Install-AdServiceAccount GMSA_DOCKERSQL
   Test-AdServiceAccount GMSA_DOCKERSQL
   Install-AdServiceAccount GMSA_DOCKERUAT
   Test-AdServiceAccount GMSA_DOCKERUAT
```
5. Create the docker credential spec files for each GMSA Account
- Download and Install the CredentialSpec module from https://www.powershellgallery.com/packages/CredentialSpec/1.0.0
- Run below
```
install-module credentialspec
Import-Module CredentialSpec
New-CredentialSpec -Name GMSA_DOCKER -AccountName GMSA_DOCKER
New-CredentialSpec -Name GMSA_DOCKERSQL -AccountName GMSA_DOCKERSQL
New-CredentialSpec -Name GMSA_DOCKERUAT -AccountName GMSA_DOCKERUAT
```     
6. Create an AD Group for the Cred Spec Service Accounts and grant permissions for the group to be in SCSM Admins and SQL Permissions to the Service manager SQL instance
7. Build the docker preq image for SMP or PULL from deveops0101 container repo (Or let docker-compose automatically pull image when compose up is run on step 11)
- docker pull devops0101/smppreq
OR
- Run Build-Preq-DockerImage.ps1 or run the docker CLI for build (Make sure to change into the directory that contains the dockerfile)
8. Build OR Pull (Or let docker-compose automatically pull image when compose up is run on step 11) from deveops0101 repo the customized MS container SQL Image (This has full text search enabled and adds GMSA Accounts on container Startup)
- docker pull devops0101/mssql-server-with-custom-gmsa-sysadmin:2017 
OR   
- docker build -t mssql-server-with-custom-gmsa-sysadmin:2017 .
9. Create a tranistive docker network (OPTIONAL -by default you have a nat network - if using nat you need to declare ports you want want to expose in the compose file (As you are natting ports to the host IP address), remove the ipv4 static address and change external network to nat at the end of compose file)
- See https://www.ntweekly.com/2017/03/30/how-to-create-a-transparent-network-with-windows-containers/ (I used the non-DHCP option)
10. Review and update .env file with your environment information, setting the desired version you want on each evironment. As this is using SQL 2017, versions v9.0.4+ must be used. Authentication in Server 2016 windows containers the hostname of the container must match the GMSA account name (This is not a requirement for Server 2019 containers)
11. Review and update docker-compose.yml with image names and where you wish to map container volumes for customspace and sql.
12. Copy .\Volumes\Custom space to the desired location on your host machine to match the docker-compose.yml (By default the YAML file expects customspace to exist in C:\Container-Volumes\SMP-Composed\CustomSpace
13. Start\Build Containers
- For interactive logging: docker-compose up 
- For detached\no logging: docker-compose up --d
14. Stop\remove Containers
- docker-compose down

## Windows Container Version Compatibility
If pulling from deveops0101 dockerhub repo, note images were build for Server 2016 - if prompted with comability error it will require the image be rebuilt locally. For 2019 update the prereq and SQL dockerfiles FROM image to be mcr.microsoft.com/windows/servercore:1809 

See below for more information:
https://docs.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/version-compatibility


## For more information see below URLS:
https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/manage-serviceaccounts
https://www.ntweekly.com/2017/03/30/how-to-create-a-transparent-network-with-windows-containers/
https://docs.docker.com/compose/compose-file/
