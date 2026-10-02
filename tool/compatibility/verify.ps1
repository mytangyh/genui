param(
    [ValidateSet('Core', 'Windows', 'Android')]
    [string]$Scope = 'Core',
    [switch]$SystemSdk,
    [switch]$DevelopmentSources
)
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$taskOriginalPubHost = $env:PUB_HOSTED_URL

function Invoke-Sdk {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$SdkArguments)
    if ($SystemSdk) {
        $sdkCommand = $SdkArguments[0]
        & $sdkCommand @($SdkArguments | Select-Object -Skip 1)
    } else {
        & fvm @SdkArguments
    }
    if ($LASTEXITCODE -ne 0) { throw "SDK command failed with exit $LASTEXITCODE" }
}

Push-Location -LiteralPath $repoRoot
try {
    $env:PUB_HOSTED_URL = 'https://pub.dev'
    $version = (Invoke-Sdk flutter --no-version-check --version) -join "`n"
    Write-Output $version
    if ($version -notmatch 'Flutter 3\.27\.4 ' -or $version -notmatch 'Dart 3\.6\.2 ') {
        throw 'Compatibility verification requires Flutter 3.27.4 / Dart 3.6.2.'
    }
    if ($DevelopmentSources) {
        Write-Output 'Development sources: this run does not prove delivery resolution.'
        Invoke-Sdk flutter --no-version-check pub get
    } else {
        Invoke-Sdk flutter --no-version-check pub get --enforce-lockfile
        Invoke-Sdk dart run tool/compatibility/check_sources.dart
    }
    $resources = @{
        'submodules/a2ui' = '39a26c1af38951840d1542103b99b00dc3a95bf1'
        'submodules/JSON-Schema-Test-Suite' = '15e4505bf689de5d30c29d50782bb48fa465c93f'
    }
    foreach ($path in $resources.Keys) {
        $head = & git -C $path rev-parse HEAD
        if ($LASTEXITCODE -ne 0 -or $head -ne $resources[$path]) {
            throw "Schema resource $path does not match the fixed baseline."
        }
        $dirty = & git -C $path status --porcelain
        if ($LASTEXITCODE -ne 0 -or $dirty) { throw "Schema resource $path is modified." }
    }
    switch ($Scope) {
        'Core' {
            $members = @('packages/genui', 'packages/genai_primitives',
                'packages/json_schema_builder', 'packages/archive/a2ui_core',
                'examples/simple_chat', 'tool/compatibility')
            $formatPaths = @('tool/compatibility', 'examples/simple_chat/integration_test')
            foreach ($member in ($members | Select-Object -First 5)) {
                foreach ($folder in @('lib', 'test', 'tool')) {
                    $sourcePath = "$member/$folder"
                    if (Test-Path -LiteralPath $sourcePath) { $formatPaths += $sourcePath }
                }
            }
            Invoke-Sdk dart format --output=none --set-exit-if-changed @formatPaths
            Invoke-Sdk dart analyze --fatal-infos @members
            Push-Location -LiteralPath 'packages/genui'
            try {
                Invoke-Sdk dart run build_runner build --delete-conflicting-outputs
                Invoke-Sdk dart format lib/src/primitives/embedded_schemas.g.dart
            }
            finally { Pop-Location }
            & git diff --exit-code -- packages/genui/lib/src/primitives/embedded_schemas.g.dart
            if ($LASTEXITCODE -ne 0) { throw 'Generated schema differs from checked-in output.' }
            foreach ($path in ($members | Select-Object -First 5)) {
                Push-Location -LiteralPath $path
                try { Invoke-Sdk flutter --no-version-check test --no-pub --reporter expanded }
                finally { Pop-Location }
            }
            Push-Location -LiteralPath 'examples/simple_chat'
            try {
                # The short -d flag binds to PowerShell's common -Debug parameter.
                Invoke-Sdk flutter --no-version-check test integration_test/app_test.dart --no-pub --device-id=flutter-tester
            } finally { Pop-Location }
        }
        'Windows' {
            Push-Location -LiteralPath 'examples/simple_chat'
            try {
                Invoke-Sdk flutter --no-version-check test integration_test/app_test.dart --no-pub --device-id=windows
                Invoke-Sdk flutter --no-version-check test integration_test/media_plugin_test.dart --no-pub --device-id=windows
            } finally { Pop-Location }
        }
        'Android' {
            Push-Location -LiteralPath 'examples/simple_chat'
            try { Invoke-Sdk flutter --no-version-check build apk --debug --no-pub }
            finally { Pop-Location }
        }
    }
} finally {
    $env:PUB_HOSTED_URL = $taskOriginalPubHost
    Pop-Location
}
