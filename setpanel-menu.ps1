#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Setpanel  = Join-Path $ScriptDir 'setpanel.ps1'

if (-not (Test-Path $Setpanel)) {
    Write-Error "setpanel.ps1 not found in $ScriptDir"
    exit 1
}

function Show-Welcome {
    $logoColor = 'Magenta'
    Write-Host ''
    Write-Host '  ____  _____ _____ ____   _    _   _ _____ _     ' -ForegroundColor $logoColor
    Write-Host ' / ___|| ____|_   _|  _ \ / \  | \ | | ____| |    ' -ForegroundColor $logoColor
    Write-Host ' \___ \|  _|   | | | |_) / _ \ |  \| |  _| | |    ' -ForegroundColor $logoColor
    Write-Host '  ___) | |___  | | |  __/ ___ \| |\  | |___| |___ ' -ForegroundColor $logoColor
    Write-Host ' |____/|_____| |_| |_| /_/   \_\_| \_|_____|_____|' -ForegroundColor $logoColor
    Write-Host ''
    Write-Host 'Windows terminal pane launcher' -ForegroundColor Gray
    Write-Host 'Version: v0.1.0' -ForegroundColor Gray
    Write-Host ('Runtime: {0}' -f $PSVersionTable.PSEdition) -ForegroundColor Gray
    Write-Host ('Script:  {0}' -f $Setpanel) -ForegroundColor Gray
}

$presets = @(
    @{ Label = 'ps 2 (side by side)';       Args = @('-ps', '2') }
    @{ Label = 'ps 3';                      Args = @('-ps', '3') }
    @{ Label = 'ps 4 (2x2 grid)';           Args = @('-ps', '4') }
    @{ Label = 'ps 6 (2x3 grid)';           Args = @('-ps', '6') }
    @{ Label = 'ps 2 + bash 2';             Args = @('-ps', '2', '-bash', '2') }
    @{ Label = 'ps 3 + bash 3';             Args = @('-ps', '3', '-bash', '3') }
    @{ Label = 'Custom args';               Args = $null }
)

$workingDirectory = (Get-Location).Path

function ConvertTo-SetpanelArgs([string]$inputText) {
    $tokens = $inputText.Trim() -split '\s+'
    $normalized = foreach ($token in $tokens) {
        switch ($token.ToLower()) {
            'ps'   { '-ps'; break }
            'bash' { '-bash'; break }
            default { $token }
        }
    }
    return [string[]]$normalized
}

function Resolve-MenuDirectory([string]$path) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        return $null
    }

    $expanded = [Environment]::ExpandEnvironmentVariables($path.Trim())
    $resolved = Resolve-Path -LiteralPath $expanded -ErrorAction SilentlyContinue
    if ($null -eq $resolved) {
        Write-Host "Directory not found: $path" -ForegroundColor Red
        [void](Read-Host 'Press Enter to continue')
        return $null
    }

    return $resolved.Path
}

function Invoke-PresetMenu([object[]]$items, [string]$directory) {
    $selected = 0
    $cancelIndex = $items.Count
    $menuTop = [Console]::CursorTop
    [Console]::CursorVisible = $false

    try {
        while ($true) {
            [Console]::SetCursorPosition(0, $menuTop)
            Write-Host '=== setpanel preset menu ===' -ForegroundColor Cyan
            Write-Host ('Working dir: {0}' -f $directory) -ForegroundColor DarkGray
            Write-Host ''

            for ($i = 0; $i -lt $items.Count; $i++) {
                $line = if ($i -eq $selected) {
                    ('> {0}) {1}' -f ($i + 1), $items[$i].Label)
                } else {
                    ('  {0}) {1}' -f ($i + 1), $items[$i].Label)
                }

                if ($i -eq $selected) {
                    Write-Host $line -ForegroundColor Black -BackgroundColor Cyan
                } else {
                    Write-Host $line
                }
            }

            $cancelLine = if ($selected -eq $cancelIndex) { '> 0) cancel' } else { '  0) cancel' }
            if ($selected -eq $cancelIndex) {
                Write-Host $cancelLine -ForegroundColor Black -BackgroundColor Cyan
            } else {
                Write-Host $cancelLine
            }

            Write-Host ''
            Write-Host 'Use Up/Down, Enter to choose, Esc to cancel.' -ForegroundColor DarkGray

            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'UpArrow' {
                    $selected--
                    if ($selected -lt 0) {
                        $selected = $cancelIndex
                    }
                    break
                }
                'DownArrow' {
                    $selected++
                    if ($selected -gt $cancelIndex) {
                        $selected = 0
                    }
                    break
                }
                'Enter' {
                    if ($selected -eq $cancelIndex) {
                        return -1
                    }
                    return $selected
                }
                'Escape' {
                    return -1
                }
                'D0' {
                    return -1
                }
                'NumPad0' {
                    return -1
                }
                default {
                    if ($key.KeyChar -match '^[1-8]$') {
                        $index = [int]::Parse([string]$key.KeyChar) - 1
                        if ($index -ge 0 -and $index -lt $items.Count) {
                            return $index
                        }
                    }
                }
            }
        }
    } finally {
        [Console]::CursorVisible = $true
        Write-Host ''
    }
}

$menuItems = [System.Collections.Generic.List[object]]::new()
foreach ($preset in $presets) {
    $menuItems.Add($preset)
}
$menuItems.Add(@{ Label = 'Change working directory'; Args = '__DIR__' })

while ($true) {
    Clear-Host
    Show-Welcome
    $selectedIndex = Invoke-PresetMenu $menuItems.ToArray() $workingDirectory
    if ($selectedIndex -lt 0) {
        Write-Host 'Cancelled.'
        exit 0
    }

    $preset = $menuItems[$selectedIndex]
    if ($preset.Args -ne '__DIR__') {
        break
    }

    $customDir = Read-Host 'Enter working directory'
    $newDirectory = Resolve-MenuDirectory $customDir
    if ($null -ne $newDirectory) {
        $workingDirectory = $newDirectory
    }
}

if ($null -eq $preset.Args) {
    $custom = Read-Host 'Enter args (e.g. ps 3 bash 2)'
    if ([string]::IsNullOrWhiteSpace($custom)) {
        Write-Host 'Cancelled.'
        exit 0
    }
    $argList = ConvertTo-SetpanelArgs $custom
} else {
    $argList = $preset.Args
}

$launchArgs = @('-d', $workingDirectory) + $argList
& $Setpanel @launchArgs
exit $LASTEXITCODE
