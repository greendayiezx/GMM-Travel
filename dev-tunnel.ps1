# dev-tunnel.ps1 — Nyalakan backend lokal (Laravel) + Cloudflare Tunnel,
# lalu cetak URL publik + perintah Flutter siap-pakai.
# Jalankan dari PowerShell:  .\dev-tunnel.ps1
$ErrorActionPreference = "Stop"

$backend = "e:\GMM Travle.id\kliktrip-backend-laravel"
$mobile  = "e:\GMM Travle.id\kliktrip_mobile"
$cf      = "C:\Users\Faras\tools\cloudflared.exe"
$outLog  = "$env:TEMP\cf_tunnel.out.log"
$errLog  = "$env:TEMP\cf_tunnel.err.log"

Write-Host "[1/3] Menyalakan Laravel di port 8000..." -ForegroundColor Cyan
Start-Process -FilePath "php" `
  -ArgumentList "artisan","serve","--host=127.0.0.1","--port=8000" `
  -WorkingDirectory $backend -WindowStyle Minimized
Start-Sleep -Seconds 3

Write-Host "[2/3] Menyalakan Cloudflare Tunnel..." -ForegroundColor Cyan
Remove-Item $outLog,$errLog -ErrorAction SilentlyContinue
Start-Process -FilePath $cf `
  -ArgumentList "tunnel","--url","http://127.0.0.1:8000" `
  -RedirectStandardOutput $outLog -RedirectStandardError $errLog -WindowStyle Minimized

Write-Host "[3/3] Menunggu URL tunnel..." -ForegroundColor Cyan
$url = $null
for ($i = 0; $i -lt 15; $i++) {
    Start-Sleep -Seconds 2
    foreach ($f in @($errLog, $outLog)) {
        if (Test-Path $f) {
            $m = Select-String -Path $f -Pattern "https://[a-z0-9-]+\.trycloudflare\.com" | Select-Object -First 1
            if ($m) { $url = $m.Matches[0].Value; break }
        }
    }
    if ($url) { break }
}

if (-not $url) {
    Write-Host "GAGAL mendapat URL tunnel. Cek log: $errLog" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host " URL Backend publik : $url" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Jalankan Flutter (salin-tempel):" -ForegroundColor Yellow
Write-Host "cd `"$mobile`"; flutter run -d chrome --dart-define=API_BASE_URL=$url/api" -ForegroundColor White
Write-Host ""
Write-Host "Biarkan jendela ini + proses berjalan selama development." -ForegroundColor DarkGray
