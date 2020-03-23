FROM mcr.microsoft.com/windows/servercore:1909 as builder

ENV RUBY_VERSION 2.7.0-1
# ENV DEVKIT_VERSION 2.7.0-1

RUN mkdir C:\\tmp
ADD https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-${RUBY_VERSION}/rubyinstaller-${RUBY_VERSION}-x64.exe C:\\tmp
RUN C:\\tmp\\rubyinstaller-%RUBY_VERSION%-x64.exe /silent /dir="C:\Ruby_%RUBY_VERSION%_x64" /tasks="assocfiles,modpath"

# ADD https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-${DEVKIT_VERSION}/rubyinstaller-devkit-${DEVKIT_VERSION}-x64.exe C:\\tmp
# RUN C:\\tmp\\rubyinstaller-devkit-%DEVKIT_VERSION%-x64.exe -o "C:\DevKit" -y

FROM mcr.microsoft.com/windows/nanoserver:1909 as runtime

ENV RUBY_VERSION 2.7.0-1
ENV RUBYGEMS_VERSION 2.7.0

COPY --from=builder C:\\Ruby_${RUBY_VERSION}_x64 C:\\Ruby_${RUBY_VERSION}_x64
# COPY --from=builder C:\\DevKit C:\\DevKit

#RUN C:\Ruby_%RUBY_VERSION%_x64\bin\ruby C:\\DevKit\\dk.rb init
RUN echo - C:\\Ruby_%RUBY_VERSION%_x64 > C:\\config.yml
#RUN C:\Ruby_%RUBY_VERSION%_x64\bin\ruby C:\\DevKit\\dk.rb install

RUN mkdir C:\\tmp
ADD https://rubygems.org/gems/rubygems-update-${RUBYGEMS_VERSION}.gem C:\\tmp
RUN C:\Ruby_%RUBY_VERSION%_x64\bin\gem install --local C:\tmp\rubygems-update-%RUBYGEMS_VERSION%.gem --no-ri --no-rdoc
RUN rmdir C:\\tmp /s /q

RUN update_rubygems --no-ri --no-rdoc
RUN C:\Ruby_%RUBY_VERSION%_x64\bin\gem install bundler --version %BUNDLER_VERSION% --no-ri --no-rdoc

CMD ["C:\\Ruby_%RUBY_VERSION%_x64\\bin\\irb"]