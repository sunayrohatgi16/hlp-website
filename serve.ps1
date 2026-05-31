# ════════════════════════════════════════════════════════════════════
# Tiny local web server for testing the site.
# Usage:   .\serve.ps1
# Then open http://localhost:8000/  in your browser.
# Press Ctrl+C to stop.
# ════════════════════════════════════════════════════════════════════

$port = 8000
$root = $PSScriptRoot

$mime = @{
  '.html' = 'text/html; charset=utf-8'
  '.htm'  = 'text/html; charset=utf-8'
  '.js'   = 'application/javascript; charset=utf-8'
  '.css'  = 'text/css; charset=utf-8'
  '.json' = 'application/json; charset=utf-8'
  '.svg'  = 'image/svg+xml'
  '.png'  = 'image/png'
  '.jpg'  = 'image/jpeg'
  '.jpeg' = 'image/jpeg'
  '.gif'  = 'image/gif'
  '.webp' = 'image/webp'
  '.ico'  = 'image/x-icon'
  '.woff' = 'font/woff'
  '.woff2'= 'font/woff2'
  '.ttf'  = 'font/ttf'
  '.txt'  = 'text/plain; charset=utf-8'
  '.md'   = 'text/markdown; charset=utf-8'
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
try { $listener.Start() }
catch {
  Write-Host "Failed to start listener on port $port." -ForegroundColor Red
  Write-Host $_.Exception.Message
  exit 1
}

Write-Host ""
Write-Host "  Humanistic Leadership Project - local test server" -ForegroundColor Green
Write-Host "  --------------------------------------------------"
Write-Host ("  Serving:  {0}" -f $root)
Write-Host ("  URL:      http://localhost:{0}/" -f $port)
Write-Host "  Stop:     Ctrl+C"
Write-Host ""

try {
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response

    $relPath = [Uri]::UnescapeDataString($req.Url.AbsolutePath)
    if ($relPath -eq '/' -or $relPath -eq '') { $relPath = '/index.html' }
    $relPath = $relPath.TrimStart('/')

    $full = Join-Path $root $relPath

    $fullResolved = $null
    try { $fullResolved = (Resolve-Path -LiteralPath $full -ErrorAction Stop).Path } catch {}
    if (-not $fullResolved -or -not $fullResolved.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
      $res.StatusCode = 404
      $res.Close()
      Write-Host ("404  /{0}" -f $relPath)
      continue
    }

    if (Test-Path -LiteralPath $fullResolved -PathType Container) {
      $fullResolved = Join-Path $fullResolved 'index.html'
    }

    if (-not (Test-Path -LiteralPath $fullResolved -PathType Leaf)) {
      $res.StatusCode = 404
      $body = [Text.Encoding]::UTF8.GetBytes("404 Not Found: /" + $relPath)
      $res.OutputStream.Write($body, 0, $body.Length)
      $res.Close()
      Write-Host ("404  /{0}" -f $relPath)
      continue
    }

    $ext = [IO.Path]::GetExtension($fullResolved).ToLower()
    if ($mime.ContainsKey($ext)) { $ct = $mime[$ext] } else { $ct = 'application/octet-stream' }

    try {
      $bytes = [IO.File]::ReadAllBytes($fullResolved)
      $res.ContentType = $ct
      $res.ContentLength64 = $bytes.Length
      $res.AddHeader('Cache-Control', 'no-store, no-cache, must-revalidate')
      $res.AddHeader('Pragma', 'no-cache')
      $res.StatusCode = 200
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
      $msg = "200  /{0}  ({1} bytes)" -f $relPath, $bytes.Length
      Write-Host $msg
    } catch {
      $res.StatusCode = 500
      $errmsg = "500  /{0}  {1}" -f $relPath, $_.Exception.Message
      Write-Host $errmsg -ForegroundColor Red
    } finally {
      $res.Close()
    }
  }
} finally {
  $listener.Stop()
  $listener.Close()
  Write-Host ""
  Write-Host "Server stopped." -ForegroundColor Yellow
}
