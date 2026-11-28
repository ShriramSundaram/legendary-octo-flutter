const fs = require('node:fs'), path = require('node:path'), crypto = require('node:crypto'), zlib = require('node:zlib');
const root = path.resolve(__dirname, '..');
const editorial = require('./content-editorial-state.cjs');
const read = p => JSON.parse(fs.readFileSync(path.join(root,p),'utf8').replace(/^\uFEFF/,''));
const normalize = s => s.normalize('NFC').toLocaleLowerCase('de').replace(/^(der|die|das)\s+/,'').replace(/\s+/g,' ').trim();
const known = new Map();
for (const file of ['assets/content_catalog_v1.json','assets/legacy_vocabulary_v1.json','assets/mission_vocabulary_v1.json']) {
  for (const w of read(file).items) known.set(normalize(w.lemma || w.german), w.level);
}
const source = 'tools/content/advanced-vocabulary-v1.txt';
let level;
const rows = [], duplicates = [];
for (const [i, raw] of fs.readFileSync(path.join(root,source),'utf8').replace(/^\uFEFF/,'').split(/\r?\n/).entries()) {
  const line = raw.trim(); if (!line) continue;
  if (line.startsWith('@')) { level = line.slice(1); continue; }
  const fields = line.split('|');
  if (!['B1','B2','C1','C2'].includes(level) || ![8,9].includes(fields.length)) throw Error('Invalid row '+(i+1));
  const [lemma,partOfSpeech,article,plural,meaning,topic,example,exampleTranslation,usageNotes=''] = fields;
  if (![lemma,meaning,topic,example,exampleTranslation].every(s=>s.trim()) || !['noun','verb','adjective'].includes(partOfSpeech)) throw Error('Incomplete row '+(i+1));
  if (partOfSpeech === 'noun' && (!['der','die','das'].includes(article) || !plural)) throw Error('Missing noun forms: '+lemma);
  if (partOfSpeech !== 'noun' && (article || plural)) throw Error('Unexpected noun forms: '+lemma);
  const key = normalize(lemma);
  if (known.has(key)) duplicates.push(level+': '+lemma+' (already '+known.get(key)+')');
  known.set(key, level);
  rows.push({schemaVersion:1,id:'advanced_'+level.toLowerCase()+'_'+crypto.createHash('sha256').update(key).digest('hex').slice(0,16),
    lemma,partOfSpeech,article,plural,meaning,topic,level,example,exampleTranslation,usageNotes,
    source:'Original AI-assisted project vocabulary; '+source,
    rights:'Original project wording; editorial approval pending.',editorialStatus:'draft',reviewer:'',reviewedAt:'',version:1});
}
if (duplicates.length) throw Error('Choose new vocabulary:\n'+duplicates.join('\n'));
for (const l of ['B1','B2','C1','C2']) if (rows.filter(w=>w.level===l).length !== 40) throw Error('Expected forty entries: '+l);
const file = 'assets/advanced_vocabulary_v1.json';
let version = 1;
if (fs.existsSync(path.join(root,file))) {
  const previous = read(file);
  for (let i=0; i<rows.length; i++) {
    const w = rows[i];
    const old = previous.items.find(p=>p.id===w.id);
    rows[i] = editorial.word(old,w);
  }
  version = JSON.stringify(previous.items) === JSON.stringify(rows) ? previous.version : previous.version+1;
}
const text = JSON.stringify({schemaVersion:1,version,items:rows},null,2)+'\n';
fs.writeFileSync(path.join(root,file),text);
const report = {items:rows.length,perLevel:Object.fromEntries(['B1','B2','C1','C2'].map(l=>[l,rows.filter(w=>w.level===l).length])),
  kinds:Object.fromEntries(['noun','verb','adjective'].map(k=>[k,rows.filter(w=>w.partOfSpeech===k).length])),
  editorialStatus:editorial.status(rows),bytes:Buffer.byteLength(text),gzipBytes:zlib.gzipSync(text).length};
fs.writeFileSync(path.join(root,'docs/m11-advanced-vocabulary-report.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify(report,null,2));
