# Registra el protocolo astro-artillery:// solo para este usuario (HKCU, sin administrador), para que el
# botón «▶ Jugar» del panel de balanceo abra el juego. Se ejecuta una vez a mano, desde cualquier carpeta
# del repo (la principal o un worktree):
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools/balance/launcher/registrar.ps1
# Apunta a lanzar.ps1 de la carpeta principal del repo (los worktrees se borran; si aún no está en main,
# apunta al de esta carpeta y hay que volver a registrar tras fusionar) y guarda la ruta de Godot,
# que el navegador no tiene: de GODOT en .claude/settings.local.json o, si no, de la variable de entorno.
$ErrorActionPreference = "Stop"

# Carpeta principal del repo: la que tiene el .git común a todos los worktrees.
$commonDir = (& git -C $PSScriptRoot rev-parse --path-format=absolute --git-common-dir).Trim()
if ($LASTEXITCODE -ne 0 -or -not $commonDir) {
	Write-Output "ERROR: no se encuentra el repo de git desde $PSScriptRoot"
	exit 1
}
$mainFolder = (Split-Path -Parent $commonDir).Replace('/', '\')
$launcher = Join-Path $mainFolder "tools\balance\launcher\lanzar.ps1"
$provisional = -not (Test-Path $launcher)
if ($provisional) { $launcher = Join-Path $PSScriptRoot "lanzar.ps1" }

# Ruta de Godot: settings.local.json de esta carpeta, el de la principal o la variable de entorno.
$godot = $null
$thisFolder = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
foreach ($folder in @($thisFolder, $mainFolder)) {
	$settings = Join-Path $folder ".claude\settings.local.json"
	if (-not $godot -and (Test-Path $settings)) {
		$json = Get-Content -Raw -Encoding UTF8 $settings | ConvertFrom-Json
		if ($json.env -and $json.env.GODOT) { $godot = $json.env.GODOT }
	}
}
if (-not $godot) { $godot = $env:GODOT }
if (-not $godot -or -not (Test-Path $godot)) {
	Write-Output "ERROR: no encuentro Godot. Pon GODOT en .claude/settings.local.json (ver docs/CLAUDE-CODE.md)"
	exit 1
}
$godot = (Resolve-Path $godot).Path

$key = "HKCU:\Software\Classes\astro-artillery"
New-Item -Path $key -Force | Out-Null
Set-ItemProperty -Path $key -Name "(default)" -Value "URL:Astro Artillery (panel de balanceo)"
Set-ItemProperty -Path $key -Name "URL Protocol" -Value ""
Set-ItemProperty -Path $key -Name "GodotPath" -Value $godot
New-Item -Path "$key\shell\open\command" -Force | Out-Null
$command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$launcher`" -Url `"%1`""
Set-ItemProperty -Path "$key\shell\open\command" -Name "(default)" -Value $command

Write-Output "Registrado astro-artillery:// -> $launcher"
Write-Output "Godot: $godot"
if ($provisional) {
	Write-Output "AVISO: lanzar.ps1 aún no está en la carpeta principal: apunta al de esta carpeta. Vuelve a ejecutar registrar.ps1 cuando esté en main."
}
