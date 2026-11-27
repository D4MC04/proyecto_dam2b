# Lo llama Windows al abrir astro-artillery://play?level=N&folder=<nombre> (botón «▶ Jugar» del panel de
# balanceo). Lo registra registrar.ps1. Solo acepta level (1-9 o emergency) y folder (nombre de una carpeta
# del repo: la principal o el worktree de un ticket); con cualquier otra cosa avisa y no abre nada.
# Abre el juego (sin editor) en ese nivel con .claude/skills/test/open-godot.ps1.
param([string]$Url = "")

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms

function Show-Message([string]$text) {
	[System.Windows.Forms.MessageBox]::Show($text, "Astro Artillery · Jugar", "OK", "Warning") | Out-Null
}

function Stop-Launch([string]$text) {
	Show-Message $text
	exit 1
}

# 1. Leer y validar la dirección (el navegador puede añadir "/" tras "play").
if ($Url -notmatch '^astro-artillery://play/?\?([^#]*)$') {
	Stop-Launch "Dirección no válida: $Url"
}
$params = @{}
foreach ($pair in $Matches[1].Split('&')) {
	$parts = $pair.Split('=', 2)
	if ($parts.Count -ne 2) { Stop-Launch "Parámetro no válido: $pair" }
	$name = [Uri]::UnescapeDataString($parts[0])
	$value = [Uri]::UnescapeDataString($parts[1].Replace('+', ' '))
	if ($name -notin @("level", "folder") -or $params.ContainsKey($name)) { Stop-Launch "Parámetro no aceptado: $name" }
	$params[$name] = $value
}
$level = $params["level"]
$folder = $params["folder"]
if ($level -cnotmatch '^([1-9]|emergency)$') {
	Stop-Launch "Nivel no válido: $level (solo 1-9 o emergency)"
}
if (-not $folder -or $folder -in @(".", "..") -or $folder -match '[\/:*?"<>|\x00-\x1f]') {
	Stop-Launch "Carpeta no válida: $folder"
}

# 2. Buscar la carpeta del repo con ese nombre entre la principal y los worktrees.
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$lines = & git -C $repo worktree list --porcelain
if ($LASTEXITCODE -ne 0) { Stop-Launch "No se pudo leer git worktree list en $repo" }
$found = @($lines | Where-Object { $_ -like "worktree *" } | ForEach-Object { $_.Substring(9).Replace('/', '\') } |
	Where-Object { (Split-Path -Leaf $_) -ieq $folder -and (Test-Path (Join-Path $_ "project.godot")) })
if ($found.Count -eq 0) {
	Stop-Launch "No hay ninguna carpeta del juego llamada «$folder» (ni la principal ni un worktree). ¿Se fusionó el ticket y se borró su worktree?"
}
if ($found.Count -gt 1) {
	Stop-Launch "Hay varias carpetas del juego llamadas «$folder»: $($found -join ', ')"
}
$target = $found[0]

# 3. Abrir con el script de /test (cierra el Godot de esa carpeta y trae el juego al frente).
$godot = (Get-ItemProperty -Path "HKCU:\Software\Classes\astro-artillery" -Name "GodotPath" -ErrorAction SilentlyContinue).GodotPath
if ($godot) { $env:GODOT = $godot }
$openGodot = Join-Path $repo ".claude\skills\test\open-godot.ps1"
$output = & powershell -NoProfile -ExecutionPolicy Bypass -File $openGodot -Path $target -GameArgs "--level=$level" | Out-String
if ($output -notmatch 'JUEGO OK') {
	Show-Message "El juego no se abrió bien:`n$($output.Trim())"
}
