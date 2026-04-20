FROM mcr.microsoft.com/dotnet/sdk:10.0

COPY 'entrypoint.ps1' '/'

ENTRYPOINT [ "/entrypoint.ps1" ]
