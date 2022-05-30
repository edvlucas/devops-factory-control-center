param($reset = $false, [Parameter(Mandatory=$true)]$ccadminpassword)

# Optionally reset everything
if ($reset) {
  Write-Host "Resetting the configuration"
  docker-compose down
  docker system prune -f
  if (Test-Path -path ./data) { Remove-Item -LiteralPath "./data" -Force -Recurse }
  # Get-ChildItem -Path ./platforms -Recurse| Foreach-object { Remove-item -Recurse -path $_.FullName }
  wsl -e "rm -rf platforms/empty-platform/.git"
}
# $env:BUILDKIT_PROGRESS = "plain"
$env:ccadminpassword = $ccadminpassword
docker-compose up --build
