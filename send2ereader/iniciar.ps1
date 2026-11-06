# Arranca send2ereader en Windows sin Docker (doble clic en INICIAR.bat)
$ErrorActionPreference = 'Stop'
$app = Join-Path $PSScriptRoot 'app'
Set-Location $app

# 1. Parar la version de Docker si esta en marcha (libera el puerto 3001)
if (Get-Command docker -ErrorAction SilentlyContinue) {
    try { docker rm -f send2ereader *> $null } catch {}
}

# 2. Instalar Node.js si no esta
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host 'Instalando Node.js...' -ForegroundColor Cyan
    winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}
$nodeExe = (Get-Command node).Source

# 3. Reglas del firewall de Windows (se piden permisos de administrador solo la primera vez)
$rules = @(Get-NetFirewallRule -DisplayName 'send2ereader*' -ErrorAction SilentlyContinue | Where-Object { $_.Enabled -eq 'True' -and $_.Action -eq 'Allow' } | Select-Object -ExpandProperty DisplayName)
if (-not ($rules -contains 'send2ereader-puerto' -and $rules -contains 'send2ereader-node')) {
    Write-Host 'Creando reglas del firewall (acepta el aviso de Windows)...' -ForegroundColor Cyan
    $cmd = "New-NetFirewallRule -DisplayName 'send2ereader-puerto' -Direction Inbound -Protocol TCP -LocalPort 3001 -Action Allow -Profile Any | Out-Null; " +
           "New-NetFirewallRule -DisplayName 'send2ereader-node' -Direction Inbound -Program '$nodeExe' -Action Allow -Profile Any | Out-Null"
    try {
        $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
        Start-Process powershell -Verb RunAs -Wait -ArgumentList '-NoProfile', '-EncodedCommand', $enc
    } catch {
        Write-Host 'No se crearon las reglas del firewall (permiso rechazado).' -ForegroundColor Red
    }
}

# 4. Descargar kepubify (convierte EPUB a KEPUB para Kobo)
if (-not (Test-Path 'kepubify.exe')) {
    Write-Host 'Descargando kepubify...' -ForegroundColor Cyan
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest 'https://github.com/pgaskin/kepubify/releases/download/v4.0.4/kepubify-windows-64bit.exe' -OutFile 'kepubify.exe' -UseBasicParsing
}

# 5. Instalar dependencias (la primera vez y cada vez que cambien)
$lockHash = (Get-FileHash 'package-lock.json').Hash
$stamp = Join-Path $app 'node_modules\.pufako-lock'
if (-not (Test-Path $stamp) -or (Get-Content $stamp) -ne $lockHash) {
    Write-Host 'Instalando dependencias...' -ForegroundColor Cyan
    npm.cmd ci --omit=dev
    if ($LASTEXITCODE -ne 0) { throw 'npm ci ha fallado' }
    Set-Content -Path $stamp -Value $lockHash
}

New-Item -ItemType Directory -Force 'uploads' | Out-Null
$env:Path = "$app;$env:Path"

Write-Host ''
Write-Host 'Abre en el Kobo y en el movil la direccion que sale abajo (http://...:3001)' -ForegroundColor Green
Write-Host 'Deja esta ventana abierta. Para pararlo, cierrala.' -ForegroundColor Yellow
Write-Host ''
$ErrorActionPreference = 'Continue'
cmd /c "node index.js 2>&1" | Tee-Object -FilePath (Join-Path $PSScriptRoot 'servidor.log')
