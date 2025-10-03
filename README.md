# commands

### One Liner

```
Set-ExecutionPolicy Bypass -Scope Process -Force; iex "& { $(irm https://raw.githubusercontent.com/tristanbeatty/tpufftechtools/main/techtools.ps1) }"
```

### Enable Script

```
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### Run Script

```
$url="https://raw.githubusercontent.com/tristanbeatty/tpufftechtools/main/techtools.ps1";$p=Join-Path $env:TEMP "techtools.ps1";Invoke-WebRequest $url -UseBasicParsing -OutFile $p; powershell -ExecutionPolicy Bypass -File $p
```

