FROM mcr.microsoft.com/azuremonitor/containerinsights/cidev:winakslog-1809

# # Do not split this into multiple RUN!
# # Docker creates a layer for every RUN-Statement
# RUN powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"

# # Fluentd depends on cool.io whose fat gem is only available for Ruby < 2.5, so need to specify --platform ruby when install Ruby > 2.5 and install msys2 to get dev tools
# RUN choco install -y ruby --version 2.6.5.1 --params "'/InstallDir:C:\ruby26'" \
# && choco install -y msys2 --params "'/NoPath /NoUpdate /InstallDir:C:\ruby26\msys64'"
# RUN refreshenv \
# && ridk install 2 3 \
# && echo gem: --no-document >> C:\ProgramData\gemrc \
# && gem install cool.io -v 1.5.4 --platform ruby \
# && gem install oj -v 3.3.10 \
# && gem install json -v 2.2.0 \
# && gem install fluentd -v 1.9.3 \
# && gem install win32-service -v 1.0.1 \
# && gem install win32-ipc -v 0.7.0 \
# && gem install win32-event -v 0.6.3 \
# && gem install windows-pr -v 1.2.6 \
# && gem sources --clear-all

# RUN choco install vim -y
# RUN gem install tomlrb

# # Remove gem cache and chocolatey
# RUN powershell -Command "Remove-Item -Force C:\ruby26\lib\ruby\gems\2.6.0\cache\*.gem; Remove-Item -Recurse -Force 'C:\ProgramData\chocolatey'"

# COPY fluent.conf /fluent/conf/fluent.conf

SHELL ["powershell"]
RUN mkdir /omsagent
RUN mkdir -p /etc/opt/microsoft/docker-cimprov/
RUN mkdir -p /etc/config/settings/

COPY *.rb /omsagent/
COPY ./log-data-collection-settings /etc/config/settings

EXPOSE 24224 5140

# copy powershell scripts to temp folder
RUN mkdir /tmp
ENV tmpdir /tmp
WORKDIR ${tmpdir}
COPY ./setup.ps1 ${tmpdir}
RUN ./setup.ps1

COPY ./main.ps1 ${tmpdir}
COPY ./filesystemwatcher.ps1 ${tmpdir}

COPY ./livenessprobe.ps1 /opt

# copy ruby scripts to /opt folder
COPY ./tomlparser.rb /opt
COPY ./ConfigParseErrorLogger.rb /opt

COPY ./fluent.conf /etc/fluent/
COPY ./fluent-bit.conf /omsagentwindows/
ENTRYPOINT ["powershell", "C:\\tmp\\main.ps1"]
