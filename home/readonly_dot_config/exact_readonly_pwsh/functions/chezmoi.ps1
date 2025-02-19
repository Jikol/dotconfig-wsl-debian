function Invoke-Chezmoi-Sync {
  $path = $(chezmoi source-path)
  if (!(Test-Path -Path $path)) { New-Item -ItemType Directory -Path $path -Force }

  $paths = (chezmoi list --path-style source-absolute) -split "`n" | 
    Where-Object { $_ -notmatch "chezmoiscripts" }

  foreach ($path in $paths) {
    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "$path removed from managed files" -ForegroundColor Yellow
  }

  $managed = Get-Content -Path "$env:CHEZMOI_LOCAL_PATH\managed.json" | ConvertFrom-Json
  foreach ($data in $managed.data) {
    $path = Resolve-Path $data.path
    chezmoi add --secrets ignore $path
    foreach ($attr in $data.attributes) {
      chezmoi chattr +"$($attr)" $path
    }
    Write-Host "$path added to managed files" -ForegroundColor Cyan 
  }

  $output = chezmoi diff
  if ([string]::IsNullOrWhiteSpace($output)) {
    Write-Host "All chezmoi files synced to source path ($(chezmoi source-path))" -ForegroundColor Green
  } else {
    Write-Host "Chezmoi synced files are inconsistent!" -ForegroundColor Yellow
    Write-Output $output
  }
}