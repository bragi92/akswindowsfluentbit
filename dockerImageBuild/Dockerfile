# escape=`

#ARG WINDOWS_VERSION=1809

#
# Builder Image - Windows Server Core
# Assemble the components required to run Fluent Bit
#
FROM mcr.microsoft.com/windows/servercore:1809 as builder

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'SilentlyContinue'; $ProgressPreference = 'SilentlyContinue';"]
#SHELL ["powershell"]

RUN New-Item -Type Directory -Path /tmp 
ENV tmpdir /tmp

WORKDIR ${tmpdir}

COPY setup.ps1 $tmpdir
COPY backgroundrunner.ps1 \omsagentwindows
RUN .\setup.ps1

FROM mcr.microsoft.com/powershell:nanoserver-1809 as runtime

COPY --from=builder /ruby /ruby
COPY --from=builder /fluent-bit /fluent-bit
COPY --from=builder /omsagentwindows /omsagentwindows

ENV CI_WSID="5e0e87ea-67ac-4779-b6f7-30173b69112a"
ENV CI_SHARED_KEY="nqWJ0bSZo7g5p4hr4QLFqMB438csAzPb74HMUHb8086Ne6lrkF/vVUyg/jHDGWHACaUJVX6W/6hxX2Gh+2Uhcg=="
ENV CI_DOMAIN="opinsights.azure.com"

ENTRYPOINT ["pwsh"]

#ENTRYPOINT ["pwsh", "c:\\omsagentwindows\\backgroundrunner.ps1"]