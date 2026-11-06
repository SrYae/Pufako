# Recoge en diagnostico.txt todo lo necesario para ver por que el movil/Kobo no conecta
$ErrorActionPreference = 'Continue'
$out = Join-Path $PSScriptRoot 'diagnostico.txt'
function Sec($t) { "`r`n===== $t =====" }
& {
    Sec 'Fecha'; Get-Date
    Sec 'IPs'; Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' } | Format-Table InterfaceAlias, IPAddress -AutoSize | Out-String
    Sec 'Perfil de red'; Get-NetConnectionProfile | Format-Table InterfaceAlias, NetworkCategory -AutoSize | Out-String
    Sec 'Firewall de Windows activo'; Get-NetFirewallProfile | Format-Table Name, Enabled, DefaultInboundAction -AutoSize | Out-String
    Sec 'Reglas send2ereader / node'; Get-NetFirewallRule | Where-Object { $_.DisplayName -match 'send2ereader|node' } | Format-Table DisplayName, Enabled, Action, Profile -AutoSize | Out-String
    Sec 'Reglas de BLOQUEO de entrada activas (node/docker)'; Get-NetFirewallRule -Enabled True -Action Block -Direction Inbound | Where-Object { $_.DisplayName -match 'node|docker|backend' } | Format-Table DisplayName, Profile -AutoSize | Out-String
    Sec 'Antivirus'; Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct | Select-Object -ExpandProperty displayName
    Sec 'Puerto 3001'; Get-NetTCPConnection -LocalPort 3001 -ErrorAction SilentlyContinue | Format-Table LocalAddress, State, OwningProcess -AutoSize | Out-String
    Get-NetTCPConnection -LocalPort 3001 -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Get-Process -Id $_.OwningProcess | Select-Object ProcessName, Path | Out-String }
    Sec 'Prueba HTTP desde el propio PC'
    foreach ($ip in (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like '192.168.*' }).IPAddress) {
        try { $r = Invoke-WebRequest "http://$($ip):3001/" -UseBasicParsing -TimeoutSec 5; "http://$($ip):3001 -> $($r.StatusCode)" } catch { "http://$($ip):3001 -> ERROR $($_.Exception.Message)" }
    }
    Sec 'Ultimas lineas de servidor.log (aqui deben salir las visitas del movil)'
    $log = Join-Path $PSScriptRoot 'servidor.log'
    if (Test-Path $log) {
        # Se lee compartido porque INICIAR.bat lo tiene abierto mientras escribe
        $fs = [IO.File]::Open($log, 'Open', 'Read', 'ReadWrite')
        $sr = New-Object IO.StreamReader($fs, $true)
        $lines = $sr.ReadToEnd() -split "`r?`n"
        $sr.Close()
        $lines | Select-Object -Last 40
    } else { 'No hay servidor.log: arranca antes INICIAR.bat' }
} *>&1 | Out-File -FilePath $out -Encoding utf8
Write-Host "Listo. Abre y copia el contenido de: $out" -ForegroundColor Green
notepad $out
