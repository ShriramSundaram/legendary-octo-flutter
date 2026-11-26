$ErrorActionPreference='Stop'
$quizRoot=Join-Path $PSScriptRoot '..'
$quizCatalog=Get-Content (Join-Path $quizRoot 'assets/content_catalog_v1.json') -Raw -Encoding utf8 | ConvertFrom-Json
$quizAuditPath=Join-Path $quizRoot 'docs/m02-quiz-audit.json'
$quizAudit=Get-Content $quizAuditPath -Raw -Encoding utf8 | ConvertFrom-Json
$quizOutputPath=Join-Path $quizRoot 'assets/quiz_catalog_v1.json'
$quizPrevious=if (Test-Path -LiteralPath $quizOutputPath) { Get-Content $quizOutputPath -Raw -Encoding utf8 | ConvertFrom-Json } else { $null }
$quizCorrections=@(Import-Csv (Join-Path $quizRoot 'docs/content/m02-quiz-corrections.psv') -Delimiter '|' -Encoding utf8)
if ($quizCorrections.Count -ne $quizAudit.items.Count -or $quizCorrections.Count -ne 55) { throw 'Expected one correction for each of the 55 original questions.' }
$quizDrafts=for ($quizNumber=0; $quizNumber -lt $quizCorrections.Count; $quizNumber++) {
  $quizCorrection=$quizCorrections[$quizNumber]
  $quizWords=@($quizCatalog.items | Where-Object { $_.lemma -ceq $quizCorrection.lemma })
  if ($quizWords.Count -ne 1) { throw ('Expected one content item for '+$quizCorrection.lemma) }
  $quizWord=$quizWords[0]
  $quizOriginal=$quizAudit.items[$quizNumber]
  $quizCorrect=($quizWord.article+' '+$quizWord.lemma).Trim()
  $quizDistractors=@($quizCorrection.distractor1,$quizCorrection.distractor2,$quizCorrection.distractor3)
  $quizOptions=[Collections.Generic.List[string]]::new()
  $quizDistractorIndex=0
  for ($quizOption=0; $quizOption -lt 4; $quizOption++) {
    if ($quizOption -eq $quizOriginal.correctOption) { $quizOptions.Add($quizCorrect) }
    else { $quizOptions.Add($quizDistractors[$quizDistractorIndex]); $quizDistractorIndex++ }
  }
  $quizId='quiz_legacy_{0:D3}' -f ($quizNumber+1)
  $quizPreserved=@($quizPrevious.items | Where-Object { $_.id -eq $quizId -and $_.editorialStatus -in @('reviewed','published','quarantined') })
  if ($quizPreserved.Count -gt 0) { $quizPreserved[0]; continue }
  $quizOriginal | Add-Member -NotePropertyName proposedQuestionId -NotePropertyValue $quizId -Force
  $quizOriginal | Add-Member -NotePropertyName proposedDisposition -NotePropertyValue 'corrected-draft; independent editorial approval pending' -Force
  $quizOriginal.itemId=$quizWord.id
  $quizOriginal.explanation=$quizCorrection.explanation
  [ordered]@{schemaVersion=1;id=$quizId;itemId=$quizWord.id;level=$quizWord.level;
    direction='enToDe';question=$quizCorrection.question;options=@($quizOptions.ToArray());
    correctOption=[int]$quizOriginal.correctOption;explanation=$quizCorrection.explanation;
    legacyAuditReference=$quizOriginal.auditReference;
    source='Original project correction of the legacy quiz; AI-assisted, 2026-11-25.';
    rights='Original wording; editorial and usage-rights confirmation pending.';
    editorialStatus='draft';reviewer='';reviewedAt='';version=1}
}
$quizVersion=if ($quizPrevious) { [int]$quizPrevious.version } else { 1 }
if ($quizPrevious -and (($quizPrevious.items | ConvertTo-Json -Depth 12 -Compress) -cne ($quizDrafts | ConvertTo-Json -Depth 12 -Compress))) { $quizVersion++ }
[ordered]@{schemaVersion=1;version=$quizVersion;items=@($quizDrafts)} | ConvertTo-Json -Depth 12 |
  Set-Content $quizOutputPath -Encoding utf8
$quizAudit | ConvertTo-Json -Depth 12 | Set-Content $quizAuditPath -Encoding utf8
Write-Output ('Prepared '+$quizDrafts.Count+' corrected draft questions; originals retained in the audit.')
