const fs=require('node:fs');
const path=require('node:path');
const {createHash}=require('node:crypto');
const levels={GenericCollections:'A1',GenericCollectionsA2:'A2',GenericCollectionsB1:'B1',GenericCollectionsB2:'B2',GenericCollectionsC1:'C1'};
function parseLegacyWord(raw) {
  if(typeof raw!=='string') return {german:null,meaning:null,warnings:['non-string']};
  const pieces=raw.split(/\s+-\s*/u);
  const warnings=[];
  if(/\s+-\S/u.test(raw)) warnings.push('nonstandard-separator-spacing');
  if(pieces.length!==2 || pieces.some(x=>!x.trim())) warnings.push('ambiguous-or-missing-pair');
  const german=pieces.length===2?pieces[0].trim():null;
  const meaning=pieces.length===2?pieces[1].trim():null;
  if(german && /[\u0300-\u0307\u0309-\u036f]/u.test(german.normalize('NFD'))) warnings.push('diacritic-needs-review');
  return {german,meaning,warnings};
}
function prepare(snapshot,catalog) {
  const byId=new Map();
  for(const document of snapshot.documents) {
    const sourcePath=document.name.split('/documents/')[1];
    const docId=sourcePath.split('/').at(-1);
    const level=levels[docId];
    if(!level) throw new Error('Unmapped legacy level: '+docId);
    const values=document.fields?.wordStorage?.arrayValue?.values;
    if(!Array.isArray(values)) throw new Error('Unexpected legacy source shape: '+sourcePath);
    values.forEach((value,index)=>{
      const raw=value.stringValue;
      const id='legacy_'+createHash('sha256').update(sourcePath+'\0'+JSON.stringify(value)).digest('hex');
      const prior=byId.get(id);
      if(prior) {prior.sourceIndexes.push(index);return;}
      const parsed=parseLegacyWord(raw);
      const lemma=parsed.german?.replace(/^(der|die|das)\s+/u,'');
      byId.set(id,{id,sourcePath,sourceIndexes:[index],raw,level,...parsed,
        possibleExistingItemIds:catalog.items.filter(item=>item.level===level && item.lemma.toLowerCase()===lemma?.toLowerCase()).map(item=>item.id),
        status:'quarantined-pending-editorial-and-rights-review',
        requiredBeforeImport:['verify German/English pairing','verify spelling and meaning','confirm usage rights and provenance','add example, translation and noun metadata','editorial signoff'],
      });
    });
  }
  const candidates=[...byId.values()];
  return {sourceCapturedAt:snapshot.capturedAt,sourceRows:candidates.reduce((n,c)=>n+c.sourceIndexes.length,0),
    candidateCount:candidates.length,duplicateRows:candidates.reduce((n,c)=>n+c.sourceIndexes.length-1,0),
    ambiguousPairs:candidates.filter(c=>c.warnings.includes('ambiguous-or-missing-pair')).length,
    separatorSpacingFlags:candidates.filter(c=>c.warnings.includes('nonstandard-separator-spacing')).length,
    diacriticFlags:candidates.filter(c=>c.warnings.includes('diacritic-needs-review')).length,
    possibleCatalogMatches:candidates.filter(c=>c.possibleExistingItemIds.length>0).length,candidates};
}
if(require.main===module) {
  const root=path.resolve(__dirname,'..');
  const snapshot=JSON.parse(fs.readFileSync(path.join(root,'.local-tools/legacy-generic-snapshot.json'),'utf8'));
  const catalog=JSON.parse(fs.readFileSync(path.join(root,'assets/content_catalog_v1.json'),'utf8'));
  const result=prepare(snapshot,catalog);
  fs.writeFileSync(path.join(root,'.local-tools/legacy-content-candidates.json'),JSON.stringify(result,null,2)+'\n');
  const {candidates,...summary}=result;
  fs.writeFileSync(path.join(root,'docs/m02-legacy-pairing-summary.json'),JSON.stringify(summary,null,2)+'\n');
  console.log(JSON.stringify(summary,null,2));
}
module.exports={parseLegacyWord,prepare};
