const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const {createHash}=require('node:crypto');
const root=path.resolve(__dirname,'..');
const read=file=>JSON.parse(fs.readFileSync(path.join(root,file),'utf8'));
const snapshot=read('.local-tools/legacy-generic-snapshot.json');
const legacy=read('assets/legacy_vocabulary_v1.json');
const bySource=new Map();
for(const item of legacy.items) {
  for(const index of item.sourceIndexes) {
    const key=item.sourcePath+':'+index;
    assert.ok(!bySource.has(key),'Duplicate source position');
    bySource.set(key,item.original);
  }
}
let checked=0;
for(const doc of snapshot.documents) {
  const source=doc.name.split('/documents/')[1];
  doc.fields.wordStorage.arrayValue.values.forEach((value,index)=>{
    assert.equal(bySource.get(source+':'+index),value.stringValue,'Original source mismatch');
    checked++;
  });
}
assert.equal(checked,1060);assert.equal(bySource.size,checked);assert.equal(legacy.items.length,1059);
const manifest=read('docs/m02-owner-approval.json');
for(const [file,approval] of Object.entries(manifest.catalogs)) {
  assert.equal(createHash('sha256').update(fs.readFileSync(path.join(root,file))).digest('hex'),approval.sha256);
  assert.deepEqual(read(file).items.map(i=>i.id),approval.ids);
}
const report={schemaVersion:1,verifiedOn:'2026-11-25',sourceRows:checked,offlineLegacyEntries:legacy.items.length,
  duplicateRowsCollapsed:checked-legacy.items.length,sourcePositionsReconciled:true,originalStringsUnchanged:true,
  snapshotSha256:createHash('sha256').update(fs.readFileSync(path.join(root,'.local-tools/legacy-generic-snapshot.json'))).digest('hex'),
  legacyAssetSha256:createHash('sha256').update(fs.readFileSync(path.join(root,'assets/legacy_vocabulary_v1.json'))).digest('hex'),
  firestoreWritesPerformed:0};
fs.writeFileSync(path.join(root,'docs/m02-offline-reconciliation.json'),JSON.stringify(report,null,2)+'\n');
console.log('All 1060 original source positions reconciled to 1059 bundled entries; approval hashes match.');
