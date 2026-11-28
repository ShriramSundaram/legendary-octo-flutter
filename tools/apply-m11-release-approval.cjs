// Applies the owner's explicit release-inclusion decision; never contacts Firebase.
const fs=require('node:fs'),path=require('node:path'),{createHash}=require('node:crypto');
const root=path.resolve(__dirname,'..');
const files=['assets/missions_catalog_v1.json','assets/mission_vocabulary_v1.json','assets/advanced_vocabulary_v1.json'];
const manifestPath=path.join(root,'docs/m11-release-content-approval.json');
const hash=b=>createHash('sha256').update(b).digest('hex');
const read=p=>JSON.parse(fs.readFileSync(p,'utf8').replace(/^\uFEFF/,''));
if(fs.existsSync(manifestPath)){
  const approved=read(manifestPath);
  for(const file of files) if(hash(fs.readFileSync(path.join(root,file)))!==approved.catalogs[file].sha256)
    throw Error('Content differs from release approval; obtain approval for the changed content: '+file);
  console.log('Release approval hashes already match.'); process.exit(0);
}
const catalogs={};
for(const file of files){
  const absolute=path.join(root,file), data=read(absolute), rows=data.missions||data.items;
  const before=hash(fs.readFileSync(absolute));
  for(const row of rows){
    const key=data.missions?'status':'editorialStatus';
    if(row[key]!=='draft') throw Error('Unexpected prior editorial state: '+row.id);
    row[key]='published';
    row.reviewer='Project owner — explicit release inclusion in chat';
    row.reviewedAt='2026-11-27';
    row.approvalBasis='Owner answered “Include the new content” when asked about these 30 missions and 280 vocabulary entries. This records release inclusion, not independent language/CEFR certification.';
    if(row.rights) row.rights='Original AI-assisted project wording; owner authorized release inclusion on 2026-11-27.';
    if(row.source) row.source=row.source.replace(/editorial approval pending/gi,'owner-approved release inclusion');
    // Step content/indices and stable vocabulary IDs are unchanged.
    if(data.items) row.version++;
  }
  if(data.items) data.version++;
  fs.writeFileSync(absolute,JSON.stringify(data,null,2)+'\n');
  catalogs[file]={beforeSha256:before,sha256:hash(fs.readFileSync(absolute)),count:rows.length,
    ids:rows.map(r=>r.id),versions:Object.fromEntries(rows.map(r=>[r.id,r.version]))};
}
const approval={schemaVersion:1,approvedOn:'2026-11-27',ownerDecision:'Include the new content',
  approvalScope:'30 current missions and 280 added vocabulary entries',independentLanguageCertification:false,
  firebaseWrites:0,cloudRecoveryImplemented:false,catalogs};
fs.writeFileSync(manifestPath,JSON.stringify(approval,null,2)+'\n');
console.log('Owner release inclusion recorded: 30 missions and 280 vocabulary entries.');
