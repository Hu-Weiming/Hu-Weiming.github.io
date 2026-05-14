$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$public = Join-Path $root "public"
$index = Join-Path $public "index.html"
$postsDir = Join-Path $public "posts"
$postsIndex = Join-Path $postsDir "index.html"
$aiPost = Join-Path $postsDir "ai-engineer-gap-notes\index.html"
$cssFile = Get-ChildItem -Path (Join-Path $public "css") -File -Filter "*.css" -ErrorAction SilentlyContinue |
  Select-Object -First 1

function Assert-Contains {
  param(
    [string] $Path,
    [string] $Needle,
    [string] $Message
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Missing file: $Path"
  }

  $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  if ($content -notlike "*$Needle*") {
    throw $Message
  }
}

function Assert-NotContains {
  param(
    [string] $Path,
    [string] $Needle,
    [string] $Message
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Missing file: $Path"
  }

  $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  if ($content -like "*$Needle*") {
    throw $Message
  }
}

if (-not (Test-Path -LiteralPath $index)) {
  throw "Missing built homepage: $index"
}

$postHtml = Get-ChildItem -LiteralPath $postsDir -Recurse -File -Filter "index.html" |
  Where-Object { $_.FullName -notmatch "\\posts\\index.html$" } |
  Select-Object -First 1

if (-not $postHtml) {
  throw "No built post detail page found under $postsDir"
}

Assert-Contains -Path $index -Needle 'az-header-search' -Message "Homepage is missing the compact header search."
Assert-Contains -Path $index -Needle 'az-search-result' -Message "Homepage is missing the search result status."
Assert-Contains -Path $index -Needle 'az-home-writing' -Message "Homepage is missing the centered writing section."
Assert-NotContains -Path $index -Needle 'az-hero' -Message "Homepage should not include the large hero block."
Assert-NotContains -Path $index -Needle 'az-tag-cabinet' -Message "Homepage should not include the keyword cabinet."
Assert-Contains -Path $postsIndex -Needle 'az-header-search' -Message "Posts list is missing the compact header search."
Assert-NotContains -Path $postsIndex -Needle 'az-page-head' -Message "Posts list should not include the large page heading block."
Assert-Contains -Path $aiPost -Needle '#ai' -Message "Imported AI article is missing the ai tag."
Assert-Contains -Path $aiPost -Needle '%E6%9C%AC%E8%B4%A8' -Message "Imported AI article is missing the 本质 tag."
Assert-Contains -Path $aiPost -Needle 'https://linux.do/t/topic/2145779' -Message "Imported AI article is missing the original source link."
Assert-Contains -Path $postHtml.FullName -Needle 'az-reader-shell' -Message "Article page is missing the reader shell."
Assert-Contains -Path $postHtml.FullName -Needle 'az-mobile-article-tools' -Message "Article page is missing mobile article tools."
Assert-Contains -Path $postHtml.FullName -Needle 'az-reader-note' -Message "Article page is missing the marginal note area."
if (-not $cssFile) {
  throw "No compiled CSS file found under public/css."
}

Assert-Contains -Path $cssFile.FullName -Needle '--az-radius-drop' -Message "Compiled CSS is missing droplet radius tokens."
Assert-Contains -Path $cssFile.FullName -Needle 'max-width:760px' -Message "Compiled CSS is missing the mobile breakpoint."

Write-Host "Site structure checks passed."
