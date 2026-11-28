// Preserve approval only when learner-visible content is unchanged.
const wordFields = ['schemaVersion','id','lemma','article','plural','meaning','example','exampleTranslation','topic','level','partOfSpeech','usageNotes','missionId'];
const missionFields = ['id','level','title','emoji','objective','situation','topic','minutes','usefulWords','steps','contentDigest'];
const same = (a,b,fields) => !!a && fields.every(k => JSON.stringify(a[k]) === JSON.stringify(b[k]));
function word(old, next) {
  if (!old) return next;
  if (!same(old,next,wordFields)) return {...next,version:old.version+1};
  return {...old,...next,version:old.version,source:old.source,rights:old.rights,
    editorialStatus:old.editorialStatus,reviewer:old.reviewer,reviewedAt:old.reviewedAt};
}
function mission(old,next) {
  if (!same(old,next,missionFields)) return next;
  return {...old,...next,status:old.status,source:old.source};
}
function status(items, key='editorialStatus') {
  const values = [...new Set(items.map(i=>i[key]))];
  return values.length === 1 ? values[0] : 'mixed';
}
module.exports={word,mission,status};
