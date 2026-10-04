param(
    [string]$Workdir = (Split-Path -Parent $PSScriptRoot)
)

$rootEnvFile = Join-Path $Workdir '.env.local'
$tempEnvFile = Join-Path $env:TEMP 'attendamce-functions.env'
$shortWorkdir = 'C:\tmp\attendamce-local'
$sourceSupabaseDir = Join-Path $Workdir 'supabase'
$sourceCli = Join-Path $Workdir 'node_modules\.bin\supabase.cmd'
$shortSupabaseDir = Join-Path $shortWorkdir 'supabase'
$shortConfigFile = Join-Path $shortSupabaseDir 'config.toml'
$functionsToServe = @(
    @{
        Name = 'send-otp'
        VerifyJwt = $false
    },
    @{
        Name = 'verify-otp'
        VerifyJwt = $false
    },
    @{
        Name = 'upload-to-r2'
        VerifyJwt = $true
    },
    @{
        Name = 'delete-r2-object'
        VerifyJwt = $true
    }
)

if (-not (Test-Path $rootEnvFile)) {
    throw "Root .env.local not found at $rootEnvFile"
}

if (-not (Test-Path $sourceSupabaseDir)) {
    throw "Supabase directory not found at $sourceSupabaseDir"
}

if (-not (Test-Path $sourceCli)) {
    throw "Supabase CLI shim not found at $sourceCli"
}

if (Test-Path $shortWorkdir) {
    $existing = Get-Item -LiteralPath $shortWorkdir
    if ($existing.FullName -ne $shortWorkdir) {
        throw "Resolved short workspace path mismatch: $($existing.FullName)"
    }
    Remove-Item -LiteralPath $shortWorkdir -Recurse -Force
}

New-Item -ItemType Directory -Path $shortWorkdir -Force | Out-Null
# Copy only the functions needed for auth and profile/R2 flows. Copying every
# function makes the CLI runtime spawn command exceed Windows limits
# (ENAMETOOLONG).
New-Item -ItemType Directory -Path (Join-Path $shortSupabaseDir 'functions') -Force | Out-Null
foreach ($function in $functionsToServe) {
    $sourceFunctionDir = Join-Path $sourceSupabaseDir "functions\$($function.Name)"
    if (-not (Test-Path $sourceFunctionDir)) {
        throw "Supabase function directory not found at $sourceFunctionDir"
    }

    Copy-Item -LiteralPath $sourceFunctionDir `
        -Destination (Join-Path $shortSupabaseDir "functions\$($function.Name)") `
        -Recurse -Force
}
Copy-Item -LiteralPath (Join-Path $sourceSupabaseDir 'functions\_shared') `
    -Destination (Join-Path $shortSupabaseDir 'functions\_shared') -Recurse -Force
if (Test-Path (Join-Path $sourceSupabaseDir 'templates')) {
    Copy-Item -LiteralPath (Join-Path $sourceSupabaseDir 'templates') `
        -Destination (Join-Path $shortSupabaseDir 'templates') -Recurse -Force
}
$configLines = @(
    'project_id = "attendamce"',
    '',
    '[edge_runtime]',
    'enabled = true',
    'policy = "oneshot"',
    'deno_version = 2',
    ''
)

$configLines += @(
    '[auth.email.template.magic_link]',
    'subject = "Your sign-in link"',
    'content_path = "./supabase/templates/magic_link.html"',
    ''
)

foreach ($function in $functionsToServe) {
    $verifyJwt = if ($function.VerifyJwt) { 'true' } else { 'false' }
    $configLines += "[functions.$($function.Name)]"
    $configLines += "verify_jwt = $verifyJwt"
    $configLines += ''
}

Set-Content -Path $shortConfigFile -Value $configLines

$allowedKeys = @(
    'DASHBOARD_BASE_URL',
    'PROJECT_URL',
    'SERVICE_ROLE_KEY',
    'RESEND_API_KEY',
    'RESEND_FROM_EMAIL',
    'OTP_REDIRECT_TO',
    'R2_ACCOUNT_ID',
    'R2_ACCESS_KEY_ID',
    'R2_SECRET_ACCESS_KEY',
    'R2_BUCKET_NAME',
    'R2_PUBLIC_URL',
    'PUBLIC_BASE_URL',
    'STORAGE_S3_URL',
    'S3_PROTOCOL_ACCESS_KEY_ID',
    'S3_PROTOCOL_ACCESS_KEY_SECRET',
    'S3_PROTOCOL_REGION'
)

$rootValues = @{}
Get-Content $rootEnvFile | ForEach-Object {
    $line = $_.Trim()
    if (-not $line -or $line.StartsWith('#') -or -not ($line -match '^[A-Za-z_][A-Za-z0-9_]*=')) {
        return
    }

    $parts = $line.Split('=', 2)
    if ($parts.Count -ne 2) {
        return
    }

    $name = $parts[0].Trim()
    $value = $parts[1].Trim()
    $rootValues[$name] = $value
}

$mappedValues = [ordered]@{}
if ($rootValues.ContainsKey('SUPABASE_URL')) {
    $mappedValues['PROJECT_URL'] = $rootValues['SUPABASE_URL']
} elseif ($rootValues.ContainsKey('PROJECT_URL')) {
    $mappedValues['PROJECT_URL'] = $rootValues['PROJECT_URL']
}
if ($rootValues.ContainsKey('SUPABASE_SERVICE_ROLE_KEY')) {
    $mappedValues['SERVICE_ROLE_KEY'] = $rootValues['SUPABASE_SERVICE_ROLE_KEY']
}
if ($rootValues.ContainsKey('SUPABASE_PUBLISHABLE_KEY')) {
    $mappedValues['PUBLISHABLE_KEY'] = $rootValues['SUPABASE_PUBLISHABLE_KEY']
}

foreach ($key in $allowedKeys) {
    if ($rootValues.ContainsKey($key)) {
        $mappedValues[$key] = $rootValues[$key]
    }
}

$content = $mappedValues.GetEnumerator() | ForEach-Object {
    "$($_.Key)=$($_.Value)"
}

Set-Content -Path $tempEnvFile -Value $content

Set-Location $shortWorkdir
& $sourceCli start
& $sourceCli functions serve --env-file $tempEnvFile
