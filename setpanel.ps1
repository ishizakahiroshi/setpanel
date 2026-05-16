#Requires -Version 5.1
$ArgList = $args

$ErrorActionPreference = 'Stop'

$PSEXE    = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh.exe' } else { 'powershell.exe' }
$BASH     = 'C:\Program Files\Git\bin\bash.exe'
$WSL      = 'wsl.exe'
$HAS_BASH = Test-Path $BASH
$HAS_WSL  = [bool](Get-Command wsl -ErrorAction SilentlyContinue)
$DIR      = (Get-Location).Path

if (-not (Get-Command wt -ErrorAction SilentlyContinue)) {
    Write-Error 'Windows Terminal (wt) not found.'
    exit 1
}

# ── Build flat pane list ──────────────────────────────────────────────────────
$panes = [System.Collections.Generic.List[string]]::new()

$layoutArgs = [System.Collections.Generic.List[string]]::new()
$i = 0
while ($i -lt $ArgList.Count) {
    $tok = $ArgList[$i]
    switch ($tok.ToLower()) {
        { $_ -in '-d', '-dir', '-cwd' } {
            $i++
            if ($i -ge $ArgList.Count -or [string]::IsNullOrWhiteSpace($ArgList[$i])) {
                Write-Error "Missing path after $tok`nUsage: setpanel [-d DIR] [-ps N] [-bash N] [-wsl N] ..."
                exit 1
            }
            $DIR = $ArgList[$i]
            break
        }
        default {
            $layoutArgs.Add($tok)
        }
    }
    $i++
}

$resolvedDir = Resolve-Path -LiteralPath $DIR -ErrorAction SilentlyContinue
if ($null -eq $resolvedDir) {
    Write-Error "Working directory not found: $DIR"
    exit 1
}
$DIR = $resolvedDir.Path

if ($layoutArgs.Count -eq 0) {
    1..4 | ForEach-Object { $panes.Add('ps') }
} else {
    $i = 0
    while ($i -lt $layoutArgs.Count) {
        $tok = $layoutArgs[$i].ToLower()
        if ($tok -notin '-ps', '-bash', '-wsl') {
            Write-Error "Unknown argument: $($layoutArgs[$i])`nUsage: setpanel [-d DIR] [-ps N] [-bash N] [-wsl N] ..."
            exit 1
        }
        $shell = $tok.TrimStart('-')
        $i++
        $count = 1
        if ($i -lt $layoutArgs.Count -and $layoutArgs[$i] -match '^\d+$') {
            $count = [int]$layoutArgs[$i]; $i++
        }
        if ($count -lt 1 -or $count -gt 12) {
            Write-Error "Count must be 1-12, got: $count"; exit 1
        }
        if ($shell -eq 'bash' -and -not $HAS_BASH) {
            Write-Warning "bash not found at $BASH — falling back to ps"
            $shell = 'ps'
        } elseif ($shell -eq 'wsl' -and -not $HAS_WSL) {
            Write-Warning "wsl.exe not found — falling back to ps"
            $shell = 'ps'
        }
        1..$count | ForEach-Object { $panes.Add($shell) }
    }
}

$N = $panes.Count
if ($N -gt 12) { Write-Error "Total panes ($N) exceeds maximum (12)"; exit 1 }

# ── Helpers ───────────────────────────────────────────────────────────────────
function Get-ShellTokens([string]$shell) {
    if ($shell -eq 'bash') { return @($BASH, '--login', '-i') }
    if ($shell -eq 'wsl') { return @($WSL, '--cd', $DIR) }
    return @($PSEXE, '-NoLogo', '-NoExit')
}

function frac([int]$num, [int]$den) {
    ("{0:F4}" -f ([double]$num / [double]$den)).TrimEnd('0').TrimEnd('.')
}

$wtArgs   = [System.Collections.Generic.List[string]]::new()
$firstCmd = $true
$wtArgs.AddRange([string[]]@('-w', '0'))

function Add-WtCmd([string[]]$tokens) {
    if (-not $script:firstCmd) { $script:wtArgs.Add(';') }
    $script:firstCmd = $false
    foreach ($t in $tokens) { $script:wtArgs.Add($t) }
}

# Start a controlled tab first so pane 0 uses the requested shell too.
Add-WtCmd (@('new-tab', '-d', $DIR) + (Get-ShellTokens $panes[0]))

# ── Build layout: 2-row grid (top row, then bottom row) ──────────────────────
$rows = if ($N -le 2) { 1 } else { 2 }
$cols = [Math]::Ceiling($N / $rows)
$bottomCount = $N - $cols

# Phase 1: Create top row columns via vertical splits (right to left).
# After this loop, focus sits at column index 1 (second from left),
# which equals the rightmost column when cols=2.
for ($i = $cols - 1; $i -ge 1; $i--) {
    $width = frac 1 ($i + 1)
    $cmd = @('split-pane', '-V', '-s', $width, '-d', $DIR) + (Get-ShellTokens $panes[$i])
    Add-WtCmd $cmd
    if ($i -gt 1) { Add-WtCmd @('move-focus', 'left') }
}

# Phase 2: Split each column horizontally to add bottom-row panes (right to left).
# Splitting per-column produces a balanced tree H(V(top,bot), V(top,bot), ...)
# so every pane ends up the same size — a true grid.
if ($rows -gt 1) {
    # Navigate from col1 to the rightmost column
    $stepsRight = [Math]::Max(0, $cols - 2)
    for ($j = 0; $j -lt $stepsRight; $j++) {
        Add-WtCmd @('move-focus', 'right')
    }

    $bottomPaneIdx = $cols
    for ($col = $cols - 1; $col -ge 0; $col--) {
        if ($col -lt $bottomCount) {
            $cmd = @('split-pane', '-H', '-s', (frac 1 2), '-d', $DIR) + (Get-ShellTokens $panes[$bottomPaneIdx])
            Add-WtCmd $cmd
            $bottomPaneIdx++
        }
        if ($col -gt 0) { Add-WtCmd @('move-focus', 'left') }
    }
}

# ── Launch ────────────────────────────────────────────────────────────────────
Write-Host "Layout: $($panes -join ' | ')  (total $N panes)"
& wt @wtArgs
if ($LASTEXITCODE -ne 0) { Write-Error "wt exited with code $LASTEXITCODE"; exit $LASTEXITCODE }
