#Requires -Version 5.1
<#
よく使う setpanel パターンのショートカット(.lnk)をデスクトップに作成する。
別の場所に作りたい場合は -Destination で指定する。

  例:
    .\install-shortcuts.ps1
    .\install-shortcuts.ps1 -Destination "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\setpanel"
#>
[CmdletBinding()]
param(
    [string]$Destination = [Environment]::GetFolderPath('Desktop'),
    [string]$WorkingDirectory = $env:USERPROFILE
)

$ErrorActionPreference = 'Stop'

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$Setpanel    = Join-Path $ScriptDir 'setpanel.bat'
$SetpanelMenu = Join-Path $ScriptDir 'setpanel-menu.bat'

foreach ($p in @($Setpanel, $SetpanelMenu)) {
    if (-not (Test-Path $p)) {
        Write-Error "Required file not found: $p"
        exit 1
    }
}

if (-not (Test-Path $Destination)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

$shortcuts = @(
    @{ Name = 'setpanel-ps2.lnk';    Target = $Setpanel;     Args = '-ps 2' }
    @{ Name = 'setpanel-ps4.lnk';    Target = $Setpanel;     Args = '-ps 4' }
    @{ Name = 'setpanel-ps6.lnk';    Target = $Setpanel;     Args = '-ps 6' }
    @{ Name = 'setpanel-mixed.lnk';  Target = $Setpanel;     Args = '-ps 2 -bash 2' }
    @{ Name = 'setpanel-wsl.lnk';    Target = $Setpanel;     Args = '-wsl 2' }
    @{ Name = 'setpanel-menu.lnk';   Target = $SetpanelMenu; Args = '' }
)

$shell = New-Object -ComObject WScript.Shell

foreach ($s in $shortcuts) {
    $path = Join-Path $Destination $s.Name
    $lnk  = $shell.CreateShortcut($path)
    $lnk.TargetPath       = $s.Target
    $lnk.Arguments        = $s.Args
    $lnk.WorkingDirectory = $WorkingDirectory
    $lnk.IconLocation     = 'wt.exe,0'
    $lnk.Description      = "setpanel $($s.Args)".Trim()
    $lnk.Save()
    Write-Host "Created: $path"
}

Write-Host ''
Write-Host ("Done. {0} shortcuts created in {1}" -f $shortcuts.Count, $Destination) -ForegroundColor Green
Write-Host "Working directory for each shortcut: $WorkingDirectory"
Write-Host '変更したい場合はショートカット右クリック → プロパティ → 作業フォルダー で編集できる。'
