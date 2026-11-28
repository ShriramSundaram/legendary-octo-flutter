param(
  [string]$Device,
  [string]$FlutterSdk=(Join-Path $env:USERPROFILE 'Documents\flutter'),
  [switch]$BuildOnly,
  [switch]$RunOnly
)
$ErrorActionPreference='Stop'
$checkRoot=Split-Path $PSScriptRoot -Parent
$checkDart=Join-Path $FlutterSdk 'bin\cache\dart-sdk\bin\dart.exe'
$checkFlutter=Join-Path $FlutterSdk 'bin\cache\flutter_tools.snapshot'
$checkAdb=Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
$checkPackage='com.sundaram.germanreminder.releasecheck'
$checkProduction='com.sundaram.germanreminder.app'
Push-Location $checkRoot
try {
  if (-not $RunOnly) {
  & $checkDart $checkFlutter build apk --release --no-pub --target=test/release_smoke_main.dart --dart-define=REMINDER_RELEASE_SMOKE=true
  if($LASTEXITCODE -ne 0){throw 'Isolated release check did not build.'}
  [xml]$checkManifest=Get-Content build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml -Raw
  $checkNs='http://schemas.android.com/apk/res/android'
  if($checkManifest.manifest.package -ne $checkPackage -or $checkManifest.manifest.application.GetAttribute('debuggable',$checkNs) -eq 'true'){throw 'Release check isolation failed.'}
  $checkPermissions=@($checkManifest.manifest.'uses-permission'|ForEach-Object{$_.GetAttribute('name',$checkNs)})
  if('android.permission.INTERNET' -in $checkPermissions){throw 'Release check unexpectedly has network access.'}
  if(@($checkManifest.manifest.application.provider|Where-Object{$_.GetAttribute('name',$checkNs) -eq 'com.google.firebase.provider.FirebaseInitProvider'}).Count -gt 0){throw 'Firebase auto-initialization is not isolated.'}
  if(-not(Test-Path build/app/outputs/mapping/release/mapping.txt)){throw 'Optimized-release mapping is missing.'}
  New-Item -ItemType Directory -Path build/release-check -Force|Out-Null
  Copy-Item build/app/outputs/flutter-apk/app-release.apk build/release-check/app-release-check.apk -Force
  Copy-Item build/app/outputs/mapping/release/mapping.txt build/release-check/mapping.txt -Force
  }
  # Inspect the actual cached APK as well, including when a production build has
  # subsequently replaced Gradle's intermediate manifest and mapping files.
  $checkAapt=Join-Path $env:LOCALAPPDATA 'Android\Sdk\build-tools\36.0.0\aapt.exe'
  $checkBadging=(& $checkAapt dump badging build/release-check/app-release-check.apk) -join "`n"
  if($LASTEXITCODE -ne 0 -or $checkBadging -notmatch "package: name='com.sundaram.germanreminder.releasecheck'" -or $checkBadging -match 'application-debuggable'){throw 'Cached APK isolation failed.'}
  $checkXml=(& $checkAapt dump xmltree build/release-check/app-release-check.apk AndroidManifest.xml) -join "`n"
  if($LASTEXITCODE -ne 0 -or $checkXml -match 'android.permission.INTERNET|com.google.firebase.provider.FirebaseInitProvider'){throw 'Cached APK network/Firebase isolation failed.'}
  if($BuildOnly){Write-Output 'Isolated optimized APK built: build/release-check/app-release-check.apk';return}
  if(-not $Device){throw 'Pass the paired device address to run the release check.'}
  $checkProductionBefore=(& $checkAdb -s $Device shell dumpsys package $checkProduction|Select-String 'versionCode=|versionName=').Line -join "`n"
  & $checkAdb -s $Device install -r (Join-Path $checkRoot 'build\release-check\app-release-check.apk')
  if($LASTEXITCODE -ne 0){throw 'Release-check APK could not be installed. No app was uninstalled.'}
  # Only this isolated test package is stopped; never the Play installation.
  & $checkAdb -s $Device shell am force-stop $checkPackage
  & $checkAdb -s $Device shell am start -W -n "$checkPackage/com.sundaram.germanreminder.app.MainActivity"
  if($LASTEXITCODE -ne 0){throw 'Release-check activity did not start.'}
  $checkResult=$null
  for($checkAttempt=0;$checkAttempt -lt 30;$checkAttempt++) {
    $checkPid=(& $checkAdb -s $Device shell pidof $checkPackage)
    if($checkPid) {
      $checkLine=(& $checkAdb -s $Device logcat -d "--pid=$($checkPid.Trim())" -v brief|Select-String 'REMINDER_RELEASE_SMOKE '|Select-Object -Last 1).Line
      if($checkLine){$checkResult=$checkLine.Substring($checkLine.IndexOf('REMINDER_RELEASE_SMOKE ')+'REMINDER_RELEASE_SMOKE '.Length)|ConvertFrom-Json;break}
    }
    Start-Sleep -Seconds 1
  }
  if($null -eq $checkResult -or $checkResult.result -ne 'PASS'){
    if($checkResult){Write-Output ('Release check failed at '+$checkResult.stage+' ('+$checkResult.type+').')}
    throw 'Optimized release checks did not pass.'
  }
  $checkProductionAfter=(& $checkAdb -s $Device shell dumpsys package $checkProduction|Select-String 'versionCode=|versionName=').Line -join "`n"
  if($checkProductionBefore -ne $checkProductionAfter){throw 'Play package version changed unexpectedly.'}
  $checkReport=[ordered]@{schemaVersion=1;testedOn=(Get-Date -Format 'yyyy-MM-dd');package=$checkPackage;apkSha256=(Get-FileHash build/release-check/app-release-check.apk -Algorithm SHA256).Hash.ToLowerInvariant();releaseMode=$true;debuggable=$false;networkPermission=$false;firebaseAutoInit=$false;
    result=$checkResult.result;checks=$checkResult.checks;playInstallationChanged=$false}
  $checkReport|ConvertTo-Json -Depth 5|Set-Content docs/m05-hotfix-release-smoke.json -Encoding utf8
  Write-Output ('Optimized release PASS: '+($checkResult.checks -join ', '))
  Write-Output 'Play installation and its version were unchanged.'
} finally {
  Pop-Location
}
