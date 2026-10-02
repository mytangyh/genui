param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('dartantic_ai', 'ai_clients_dart', 'google-cloud-dart', 'sse_channel')]
    [string]$Repository,
    [Parameter(Mandatory = $true)][string]$Checkout,
    [switch]$SystemSdk,
    [switch]$DevelopmentSources
)
$ErrorActionPreference = 'Stop'
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

Push-Location -LiteralPath (Resolve-Path -LiteralPath $Checkout).Path
try {
    $env:PUB_HOSTED_URL = 'https://pub.dev'
    $version = (Invoke-Sdk flutter --no-version-check --version) -join "`n"
    Write-Output $version
    if ($version -notmatch 'Flutter 3\.27\.4 ' -or $version -notmatch 'Dart 3\.6\.2 ') {
        throw 'Compatibility verification requires Flutter 3.27.4 / Dart 3.6.2.'
    }
    if ($DevelopmentSources) {
        Write-Output 'Development sources: this run does not prove delivery resolution.'
        Invoke-Sdk dart pub get
    } else {
        if (Test-Path -LiteralPath 'pubspec_overrides.yaml') {
            throw 'Remove the development override before validating delivery.'
        }
        Invoke-Sdk dart pub get --enforce-lockfile
        if (Select-String -LiteralPath 'pubspec.lock' -Pattern '^    source: path$' -Quiet) {
            throw 'Dependency lockfile still contains a development path.'
        }
    }
    $formatPaths = @()
    $analysisPaths = @()
    $testPaths = @()
    switch ($Repository) {
        'ai_clients_dart' {
            foreach ($name in @('anthropic_sdk_dart', 'mistralai_dart', 'ollama_dart', 'openai_dart')) {
                $formatPaths += "packages/$name/lib", "packages/$name/test"
                $testPaths += "packages/$name/test/unit"
            }
            $analysisPaths = $formatPaths
        }
        'google-cloud-dart' {
            $formatPaths = @('generated/google_cloud_protobuf', 'generated/google_cloud_rpc',
                'generated/google_cloud_type', 'generated/google_cloud_longrunning',
                'generated/google_cloud_ai_generativelanguage_v1beta', 'test_utils')
            $analysisPaths = $formatPaths
            foreach ($path in $formatPaths) {
                if (Test-Path -LiteralPath "$path/test") { $testPaths += "$path/test" }
            }
        }
        'sse_channel' {
            $formatPaths = @('lib', 'test')
            $analysisPaths = $formatPaths
            $testPaths = @('test')
        }
        'dartantic_ai' {
            $formatPaths = @('packages/dartantic_interface/lib', 'packages/dartantic_ai/lib',
                'packages/dartantic_ai/test')
            $analysisPaths = $formatPaths
            # These upstream files use metadata, parsers, local event mappers or MockClient.
            # The separate live-provider suite is not a secret-free CI target.
            $offlineTests = @('provider_initialization_test.dart', 'embeddings_config_test.dart',
                'model_string_parser_test.dart', 'message_api_test.dart',
                'message_part_helpers_test.dart',
                'openai_responses/openai_responses_event_mapper_test.dart',
                'openai_responses/openai_responses_message_mapper_test.dart')
            $testPaths = $offlineTests | ForEach-Object { "packages/dartantic_ai/test/$_" }
        }
    }
    Invoke-Sdk dart format --output=none --set-exit-if-changed @formatPaths
    # Preserve upstream lint rules and report infos; errors and warnings remain fatal.
    Invoke-Sdk dart analyze @analysisPaths
    Invoke-Sdk dart test --reporter expanded @testPaths
} finally {
    $env:PUB_HOSTED_URL = $taskOriginalPubHost
    Pop-Location
}
