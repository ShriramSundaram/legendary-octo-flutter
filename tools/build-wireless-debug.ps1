param(
  [string]$FlutterSdk = (Join-Path $env:USERPROFILE 'Documents\flutter'),
  [switch]$Isolated
)
$ErrorActionPreference = 'Stop'
$wirelessRoot = Split-Path $PSScriptRoot -Parent
$wirelessSecretPath = Join-Path $wirelessRoot '.local-tools\wireless-app-check-token.txt'
$wirelessDefinesPath = Join-Path $wirelessRoot '.local-tools\wireless-debug-defines.json'
if (-not (Test-Path -LiteralPath $wirelessSecretPath)) {
  throw 'Registered wireless App Check test credential is missing. Follow docs/wireless-testing.md.'
}
$wirelessSaved = [IO.File]::ReadAllText($wirelessSecretPath)
$wirelessMatch = [regex]::Match($wirelessSaved, '(?i)[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}')
if (-not $wirelessMatch.Success) { throw 'Wireless test credential has an unexpected format.' }
$wirelessDefines=@{FIREBASE_APP_CHECK_DEBUG_TOKEN=$wirelessMatch.Value}
if ($Isolated) {
  $wirelessDefines['REMINDER_WIRELESS_TEST']='true'
  # Same registered Firebase app and test credential, separate Android storage.
  # Never edit the real Firebase configuration or create a production client.
  $wirelessConfig=Get-Content (Join-Path $wirelessRoot 'android/app/google-services.json') -Raw | ConvertFrom-Json
  $wirelessClient=@($wirelessConfig.client | Where-Object {
    $_.client_info.android_client_info.package_name -eq 'com.sundaram.germanreminder.app'
  })
  if($wirelessClient.Count -ne 1){throw 'Expected exactly one original Firebase Android client.'}
  $wirelessClient[0].client_info.android_client_info.package_name='com.sundaram.germanreminder.wirelesstest'
  $wirelessConfig.client=@($wirelessClient[0])
  $wirelessConfig | ConvertTo-Json -Depth 30 | Set-Content (Join-Path $wirelessRoot '.local-tools/wireless-google-services.json') -Encoding utf8
}
$wirelessDefines | ConvertTo-Json -Compress |
  Set-Content -LiteralPath $wirelessDefinesPath -Encoding utf8
$wirelessDart = Join-Path $FlutterSdk 'bin\cache\dart-sdk\bin\dart.exe'
$wirelessTools = Join-Path $FlutterSdk 'bin\cache\flutter_tools.snapshot'
Push-Location $wirelessRoot
try {
  Write-Output 'Building a private debug APK with the registered wireless App Check credential.'
  & $wirelessDart $wirelessTools build apk --debug --no-pub --target=lib/main.dart "--dart-define-from-file=$wirelessDefinesPath"
  if ($LASTEXITCODE -ne 0) { throw 'Wireless debug build failed.' }
} finally { Pop-Location }
