param([string]$SourcePath)
$ErrorActionPreference = 'Stop'
$draftCatalogPath = Join-Path $PSScriptRoot '..\assets\content_catalog_v1.json'
$draftSourcePath = if ($SourcePath) { (Resolve-Path -LiteralPath $SourcePath).Path } else { Join-Path $PSScriptRoot '..\docs\content\m02-drafts.psv' }
$draftCatalog = Get-Content -LiteralPath $draftCatalogPath -Raw -Encoding utf8 | ConvertFrom-Json
$draftItems = [Collections.Generic.List[object]]::new()
$draftKeys = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($draftExisting in $draftCatalog.items) {
  $draftItems.Add($draftExisting)
  [void]$draftKeys.Add($draftExisting.level + ':' + $draftExisting.lemma.Trim())
}
$draftHash = [Security.Cryptography.SHA256]::Create()
try {
  foreach ($draftRow in (Import-Csv -LiteralPath $draftSourcePath -Delimiter '|' -Encoding utf8)) {
    $draftKey = $draftRow.level + ':' + $draftRow.lemma.Trim()
    if (-not $draftKeys.Add($draftKey)) { continue }
    $draftDigest = [BitConverter]::ToString($draftHash.ComputeHash([Text.Encoding]::UTF8.GetBytes($draftKey))).Replace('-','').ToLowerInvariant()
    $draftItems.Add([ordered]@{
      schemaVersion=1;id=('de_'+$draftRow.level.ToLowerInvariant()+'_'+$draftDigest.Substring(0,16));
      lemma=$draftRow.lemma;meaning=$draftRow.meaning;example=$draftRow.example;
      exampleTranslation=$draftRow.exampleTranslation;topic=$draftRow.topic;
      partOfSpeech=$draftRow.partOfSpeech;article=$draftRow.article;plural=$draftRow.plural;
      usageNotes='';level=$draftRow.level;
      source='Original AI-assisted project draft, 2026-11-25; CEFR placement provisional.';
      rights='Original draft wording; editorial and usage-rights confirmation pending.';
      editorialStatus='draft';reviewer='';reviewedAt='';version=1
    })
  }
} finally { $draftHash.Dispose() }
[ordered]@{schemaVersion=1;version=[math]::Max(2,[int]$draftCatalog.version + [int]($draftItems.Count -gt @($draftCatalog.items).Count));items=@($draftItems.ToArray())} |
  ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $draftCatalogPath -Encoding utf8
Write-Output ('Catalog contains '+$draftItems.Count+' items; no review or publication status changed.')
