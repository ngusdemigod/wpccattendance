param(
    [string]$Workdir = (Split-Path -Parent $PSScriptRoot)
)

$serveScript = Join-Path $PSScriptRoot 'serve-otp-function.ps1'

if (-not (Test-Path $serveScript)) {
    throw "Local Supabase serve script not found at $serveScript"
}

# Start Supabase together with the auth/profile edge functions so local
# email-dependent flows receive the env values from .env.local.
& $serveScript -Workdir $Workdir
