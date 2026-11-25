# Abre Godot para probar: cierra el Godot de esta carpeta, abre solo el juego (sin editor) con los
# argumentos de prueba (y la escena -Scene, si se pasa) y lo trae al frente.
# Uso: powershell -NoProfile -ExecutionPolicy Bypass -File open-godot.ps1 -Path <carpeta> [-GameArgs "--level=3 --wave=5"] [-Scene res://scenes/x.tscn]
# Imprime "JUEGO OK" o "JUEGO NO SALE: motivo".
param(
	[Parameter(Mandatory = $true)][string]$Path,
	[string]$GameArgs = "",
	[string]$Scene = ""
)

$ErrorActionPreference = "Stop"
$godot = $env:GODOT
if (-not $godot -or -not (Test-Path $godot)) {
	Write-Output "FALTA GODOT: pon la ruta en .claude/settings.local.json (ver docs/CLAUDE-CODE.md)"
	exit 1
}
$Path = (Resolve-Path $Path).Path.TrimEnd('\')

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class GodotWin {
	[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
	[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
	[DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
	[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
	[DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
	[DllImport("user32.dll")] public static extern void SwitchToThisWindow(IntPtr h, bool altTab);
}
"@

# Normaliza para comparar líneas de órdenes: minúsculas y barras hacia delante.
function Get-NormalizedText([string]$text) { return $text.ToLower().Replace('\', '/') }

# Procesos de Godot abiertos en esta carpeta (el juego y cualquier Godot que quedara abierto).
function Get-FolderGodot {
	$folder = Get-NormalizedText $Path
	Get-CimInstance Win32_Process -Filter "Name LIKE 'Godot%'" | Where-Object {
		$_.CommandLine -and (Get-NormalizedText $_.CommandLine).Contains("--path `"$folder`"") -or
		($_.CommandLine -and (Get-NormalizedText $_.CommandLine).Contains("--path $folder"))
	}
}

# Lanza por WMI: el proceso no cuelga del de la herramienta y no muere al acabar la llamada.
function Start-Detached([string]$arguments) {
	$commandLine = "`"$godot`" --path `"$Path`" $arguments"
	$result = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $commandLine; CurrentDirectory = $Path }
	if ($result.ReturnValue -ne 0) { return 0 }
	return [int]$result.ProcessId
}

# Espera a que el proceso tenga ventana principal; 0 si muere o no sale a tiempo.
function Wait-Window([int]$processId, [int]$seconds) {
	$deadline = (Get-Date).AddSeconds($seconds)
	while ((Get-Date) -lt $deadline) {
		$process = Get-Process -Id $processId -ErrorAction SilentlyContinue
		if (-not $process) { return [IntPtr]::Zero }
		if ($process.MainWindowHandle -ne [IntPtr]::Zero) { return $process.MainWindowHandle }
		Start-Sleep -Milliseconds 500
	}
	return [IntPtr]::Zero
}

# Windows no deja que un proceso en segundo plano se ponga delante: pulsar y soltar Alt lo desbloquea.
function Set-Front([IntPtr]$handle) {
	for ($i = 0; $i -lt 3; $i++) {
		[GodotWin]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero)
		[GodotWin]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
		if ([GodotWin]::IsIconic($handle)) { [GodotWin]::ShowWindow($handle, 9) | Out-Null } else { [GodotWin]::ShowWindow($handle, 5) | Out-Null }
		[GodotWin]::SetForegroundWindow($handle) | Out-Null
		Start-Sleep -Milliseconds 300
		if ([GodotWin]::GetForegroundWindow() -eq $handle) { return $true }
		[GodotWin]::SwitchToThisWindow($handle, $true)
		Start-Sleep -Milliseconds 300
		if ([GodotWin]::GetForegroundWindow() -eq $handle) { return $true }
	}
	return $false
}

# Abre una ventana (con un reintento si no sale) y devuelve su handle, o un texto con el fallo.
function Open-Window([string]$label, [string]$arguments, [int]$seconds) {
	for ($try = 1; $try -le 2; $try++) {
		$processId = Start-Detached $arguments
		if ($processId -eq 0) { $reason = "no se pudo lanzar"; continue }
		$handle = Wait-Window $processId $seconds
		if ($handle -ne [IntPtr]::Zero) { return @{ Handle = $handle; Pid = $processId } }
		if (Get-Process -Id $processId -ErrorAction SilentlyContinue) {
			$reason = "el proceso sigue vivo pero sin ventana tras $seconds s"
			Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
		} else {
			$reason = "el proceso se cerró solo"
		}
	}
	return @{ Error = "$label NO SALE: $reason" }
}

# 1. Cerrar solo el Godot de esta carpeta.
$old = @(Get-FolderGodot)
foreach ($process in $old) { Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue }
if ($old.Count -gt 0) { Start-Sleep -Seconds 1; Write-Output "Cerrados $($old.Count) Godot de esta carpeta" }

# 2. Carpeta sin importar (worktree nuevo): importar antes, para que editor y juego no importen a la vez.
if (-not (Test-Path (Join-Path $Path ".godot"))) {
	Start-Process -FilePath $godot -ArgumentList "--headless","--path","`"$Path`"","--import" -Wait -WindowStyle Hidden
}

# 3. Solo el juego (sin editor), con la escena indicada si hay.
$sceneArg = if ($Scene.Trim()) { "$Scene " } else { "" }
$extra = if ($GameArgs.Trim()) { "-- $GameArgs" } else { "" }
$game = Open-Window "JUEGO" "$sceneArg$extra" 60

# 4. Al frente.
if ($game.Error) { Write-Output $game.Error; exit 0 }
if (Set-Front $game.Handle) {
	Write-Output "JUEGO OK (pid $($game.Pid))"
} else {
	Write-Output "JUEGO ABIERTO PERO NO DELANTE (pid $($game.Pid)): Windows no dejó traerlo al frente"
}
