# <img src="favicon.svg" alt="publish-powershell" width="64" height="64" style="vertical-align: middle"> publish-powershell

A GitHub Action that publishes PowerShell module(s) to the [PowerShell Gallery](https://powershellgallery.com).

## Setup

1. Add a GitHub Actions workflow to your project (e.g. `.github/workflows/main.yml`)
2. Configure a secret containing your PowerShell Gallery API key
3. Add the publish step to your job

## Usage

If you named your secret `PSGALLERY_API_KEY`:

```yaml
      - name: Publish Module(s) to PowerShell Gallery
        uses: chris-peterson/publish-powershell@v1
        with:
          ApiKey: ${{ secrets.PSGALLERY_API_KEY }}
```

## Full Example

```yaml
name: CI

on:
  push:
    branches: [ 'main']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5

      - name: Publish PowerShell Module
        uses: chris-peterson/publish-powershell@v1
        with:
          ApiKey: ${{ secrets.PSGALLERY_API_KEY }}
    environment:
      name: PowerShell Gallery
      url: https://www.powershellgallery.com/packages/<YOUR_PACKAGE_HERE>
```
