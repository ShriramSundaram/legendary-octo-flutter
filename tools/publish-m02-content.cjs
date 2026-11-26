// Applies the project owner's explicit 2026-11-25 content acceptance.
// Does not connect to Firestore or claim independent language certification.
const fs = require('node:fs');
const path = require('node:path');
const {createHash} = require('node:crypto');
const root = path.resolve(__dirname, '..');
const read = file => JSON.parse(fs.readFileSync(path.join(root,file),'utf8'));
const write = (file,data) => fs.writeFileSync(path.join(root,file),JSON.stringify(data,null,2)+'\n');
const approvedAt = '2026-11-25T00:00:00+05:30';
const reviewer = 'Project owner — explicit content acceptance in chat';
const manifestPath = 'docs/m02-owner-approval.json';
const existing = fs.existsSync(path.join(root,manifestPath)) ? read(manifestPath) : null;
const approvals = [];
for (const file of ['assets/content_catalog_v1.json','assets/quiz_catalog_v1.json']) {
  const catalog = read(file);
  if (existing && createHash('sha256').update(fs.readFileSync(path.join(root,file))).digest('hex') !== existing.catalogs[file].sha256) {
    throw Error('Content changed since owner approval; record a new explicit approval before rerunning: '+file);
  }
  let changed = false;
  for (const item of catalog.items) {
    if (existing && !existing.catalogs[file].ids.includes(item.id)) throw Error('New content needs separate owner approval: '+item.id);
    if (item.editorialStatus === 'published') continue;
    if (item.editorialStatus !== 'draft') throw Error('Refusing to replace existing editorial decision: '+item.id);
    item.editorialStatus = 'published';
    item.reviewer = reviewer;
    item.reviewedAt = approvedAt;
    item.approvalBasis = 'Owner accepted content and explicitly requested offline publication; not independent German/CEFR certification.';
    item.rights = 'Original AI-assisted project wording; accepted for inclusion by project owner on 2026-11-25.';
    item.version++;
    changed = true;
  }
  if (changed) catalog.version++;
  write(file,catalog);
  approvals.push([file,{version:catalog.version,ids:catalog.items.map(i=>i.id),sha256:createHash('sha256').update(fs.readFileSync(path.join(root,file))).digest('hex')}]);
}
const queue = read('.local-tools/legacy-content-candidates.json');
if (queue.candidateCount !== 1059 || queue.sourceRows !== 1060) throw Error('Legacy inventory changed; confirm new scope before publication.');
const legacy = {
  schemaVersion:1,version:1,sourceRows:queue.sourceRows,
  source:'Read-only snapshot of project Generic collections; originals unchanged in Firestore.',
  rights:'Owner-declared original writing, accepted for offline inclusion on 2026-11-25.',
  reviewer,reviewedAt:approvedAt,approvalBasis:'Owner acceptance; original strings retained. CEFR tags inherited, not independently certified.',
  items:queue.candidates.map(c=>({id:c.id,level:c.level,german:c.german,meaning:c.meaning,original:c.raw,sourcePath:c.sourcePath,sourceIndexes:c.sourceIndexes,warnings:c.warnings,possibleExistingItemIds:c.possibleExistingItemIds})),
};
if(legacy.items.some(i=>!i.german || !i.meaning)) throw Error('Unparsed legacy entry');
write('assets/legacy_vocabulary_v1.json',legacy);
write(manifestPath,{
  schemaVersion:1,acceptedOn:'2026-11-25',reviewer,
  evidence:['Content is fine. we can keep it.','Vocabulary fine. add it. and make it available offline. M02 last points and proceed'],
  independentLanguageReview:false,levelCertification:false,
  catalogs:Object.fromEntries(approvals),legacy:{sourceRows:1060,uniqueEntries:1059,originalsPreserved:true,duplicateSourceRows:1},
});
console.log('Owner-approved offline content: 269 structured words, 55 quizzes, 1059 preserved legacy entries.');
