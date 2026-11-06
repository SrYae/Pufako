# Arranca send2ereader en Windows sin Docker (doble clic en INICIAR.bat)
$ErrorActionPreference = 'Stop'
$app = Join-Path $PSScriptRoot 'app'
Set-Location $app

# 1. Parar la versión de Docker si está en marcha (libera el puerto 3001)
if (Get-Command docker -ErrorAction SilentlyContinue) {
    try { docker rm -f send2ereader *> $null } catch {}
}

# 2. Instalar Node.js si no está
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host 'Instalando Node.js...' -ForegroundColor Cyan
    winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

# 3. Descargar kepubify (convierte EPUB a KEPUB para Kobo)
if (-not (Test-Path 'kepubify.exe')) {
    Write-Host 'Descargando kepubify...' -ForegroundColor Cyan
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest 'https://github.com/pgaskin/kepubify/releases/download/v4.0.4/kepubify-windows-64bit.exe' -OutFile 'kepubify.exe' -UseBasicParsing
}

# 4. Instalar dependencias (solo la primera vez)
if (-not (Test-Path 'node_modules')) {
    Write-Host 'Instalando dependencias...' -ForegroundColor Cyan
    npm.cmd ci --omit=dev
    if ($LASTEXITCODE -ne 0) { throw 'npm ci ha fallado' }
}

New-Item -ItemType Directory -Force 'uploads' | Out-Null
$env:Path = "$app;$env:Path"

$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like '192.168.*' } | Select-Object -First 1).IPAddress
Write-Host ''
Write-Host "Abre en el Kobo y en el movil:  http://$($ip):3001" -ForegroundColor Green
Write-Host 'Deja esta ventana abierta. Para pararlo, cierrala.' -ForegroundColor Yellow
Write-Host ''
node index.js
