# escape=`

#ARG WINDOWS_VERSION=1809

#
# Builder Image - Windows Server Core
# Assemble the components required to run Fluent Bit
#
FROM mcr.microsoft.com/windows/servercore:1903

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'SilentlyContinue'; $ProgressPreference = 'SilentlyContinue';"]
#SHELL ["powershell"]

RUN New-Item -Type Directory -Path /tmp 
ENV tmpdir /tmp

WORKDIR ${tmpdir}

COPY setup.ps1 $tmpdir
COPY backgroundrunner.ps1 \omsagentwindows
RUN .\setup.ps1
ENV CI_WSID="5e0e87ea-67ac-4779-b6f7-30173b69112a"
ENV CI_SHARED_KEY="nqWJ0bSZo7g5p4hr4QLFqMB438csAzPb74HMUHb8086Ne6lrkF/vVUyg/jHDGWHACaUJVX6W/6hxX2Gh+2Uhcg=="
ENV CI_DOMAIN="opinsights.azure.com"

#ENTRYPOINT ["powershell"]

ENTRYPOINT ["powershell", "c:\\omsagentwindows\\backgroundrunner.ps1"]
