# 一键准备 Flutter 工程（本地版，需已安装 Flutter SDK）
# 作用：生成 android/ios 平台目录 + 注入后台定位权限 + 拉依赖
# 用法：cd E:\dsh工作区\location-share\app  然后  .\prepare.ps1
$ErrorActionPreference = 'Stop'

Write-Host "[1/4] 生成平台目录 (android/ios/web)..."
flutter create --org com.linkupclone --project-name location_share .

Write-Host "[2/4] 注入 iOS 后台定位权限到 Info.plist..."
$plist = 'ios\Runner\Info.plist'
$keys = @"
<key>NSLocationWhenInUseUsageDescription</key>
<string>用于在地图上显示你的位置</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>用于在后台持续共享你的位置给配对的人</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>用于在后台持续共享你的位置</string>
<key>UIBackgroundModes</key>
<array>
	<string>location</string>
</array>
"@
$content = Get-Content $plist -Raw
if ($content -notmatch 'UIBackgroundModes') {
  $idx = $content.IndexOf('<dict>')
  if ($idx -ge 0) {
    $at = $idx + '<dict>'.Length
    $content = $content.Substring(0, $at) + "`n" + $keys + $content.Substring($at)
    [System.IO.File]::WriteAllText((Resolve-Path $plist), $content)
    Write-Host "  Info.plist 已补丁"
  }
} else {
  Write-Host "  Info.plist 已含后台定位，跳过"
}

Write-Host "[3/4] 注入 Android 权限到 AndroidManifest.xml..."
$manifest = 'android\app\src\main\AndroidManifest.xml'
$perms = @"
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
"@
$m = Get-Content $manifest -Raw
if ($m -notmatch 'ACCESS_BACKGROUND_LOCATION') {
  $idx = $m.IndexOf('<application')
  if ($idx -ge 0) {
    $m = $m.Substring(0, $idx) + $perms + "`n    " + $m.Substring($idx)
    [System.IO.File]::WriteAllText((Resolve-Path $manifest), $m)
    Write-Host "  AndroidManifest 已补丁"
  }
} else {
  Write-Host "  AndroidManifest 已含权限，跳过"
}

Write-Host "[4/4] 拉取依赖..."
flutter pub get

Write-Host ""
Write-Host "完成！后续可选："
Write-Host "  - 路线 C（安卓）: flutter build apk --release --dart-define=API_BASE=http://服务器地址:8788"
Write-Host "  - 路线 B（iOS 无签名）: 把本目录推到 GitHub，走 GitHub Actions"
