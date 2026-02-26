FROM mcr.microsoft.com/dotnet/sdk:10.0

# Pin pre-release PSResourceGet for fixes:
# - PowerShell/PSResourceGet#1868: Repository store init
# - PowerShell/PSResourceGet#1925: -WhatIf:$false passthrough
ARG PSRESOURCEGET_VERSION=1.2.0-rc3
RUN pwsh -c "Install-PSResource -Name Microsoft.PowerShell.PSResourceGet \
            -Version $PSRESOURCEGET_VERSION -Prerelease -Scope AllUsers -TrustRepository" &&\
    pwsh -c "Import-Module Microsoft.PowerShell.PSResourceGet \
            -MinimumVersion ('$PSRESOURCEGET_VERSION' -replace '-.*') -ErrorAction Stop"

COPY 'entrypoint.ps1' '/'

ENTRYPOINT [ "/entrypoint.ps1" ]
