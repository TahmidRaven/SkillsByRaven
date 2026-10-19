[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$AgentHome = [Environment]::GetFolderPath('UserProfile'),
    [ValidateSet('Codex', 'ClaudeCode')]
    [string[]]$Agents = @('Codex', 'ClaudeCode')
)

$ErrorActionPreference = 'Stop'
$skillSource = (Resolve-Path -LiteralPath $PSScriptRoot).ProviderPath
foreach ($requiredFile in @('SKILL.md', 'references/github.md', 'references/plane.md')) {
    if (-not (Test-Path -LiteralPath (Join-Path $skillSource $requiredFile) -PathType Leaf)) {
        throw "Missing $requiredFile in $skillSource. Copy the entire skill folder before installing."
    }
}

$registrations = foreach ($agentName in ($Agents | Select-Object -Unique)) {
    $relativeRoot = if ($agentName -eq 'Codex') { '.codex/skills' } else { '.claude/skills' }
    $skillRoot = Join-Path $AgentHome $relativeRoot
    $skillLink = Join-Path $skillRoot 'raven-signout'
    $existing = Get-Item -LiteralPath $skillLink -Force -ErrorAction SilentlyContinue
    if ($existing) {
        $sameTarget = $false
        if ($existing.LinkType -in @('Junction', 'SymbolicLink')) {
            foreach ($targetPath in @($existing.Target)) {
                if (-not [IO.Path]::IsPathRooted($targetPath)) {
                    $targetPath = Join-Path $skillRoot $targetPath
                }
                if ([IO.Path]::GetFullPath($targetPath).TrimEnd('\') -ieq $skillSource.TrimEnd('\')) {
                    $sameTarget = $true
                }
            }
        }
        if (-not $sameTarget) {
            throw "Refusing to replace existing path: $skillLink"
        }
    }
    [pscustomobject]@{ Agent = $agentName; Root = $skillRoot; Link = $skillLink; Exists = [bool]$existing }
}

foreach ($registration in $registrations) {
    if (-not $registration.Exists -and $PSCmdlet.ShouldProcess($registration.Link, "Link skill to $skillSource")) {
        if (-not (Test-Path -LiteralPath $registration.Root)) {
            New-Item -ItemType Directory -Path $registration.Root -Force | Out-Null
        }
        New-Item -ItemType Junction -Path $registration.Link -Target $skillSource | Out-Null
    }
    if (Test-Path -LiteralPath (Join-Path $registration.Link 'SKILL.md') -PathType Leaf) {
        Write-Output "Registered for $($registration.Agent): $($registration.Link) -> $skillSource"
    }
}
