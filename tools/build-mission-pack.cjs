// Reproducible generation from original, editable dialogue source. No network.
const fs = require('node:fs'), path = require('node:path'), crypto = require('node:crypto'), zlib = require('node:zlib');
const root = path.resolve(__dirname, '..');
const editorial = require('./content-editorial-state.cjs');
const read = p => JSON.parse(fs.readFileSync(path.join(root, p), 'utf8').replace(/^\uFEFF/, ''));
const write = (p, value) => fs.writeFileSync(path.join(root, p), JSON.stringify(value, null, 2) + '\n');
const hash = value => crypto.createHash('sha256').update(value).digest('hex');
const normalize = s => s.toLocaleLowerCase('de').replace(/^(der|die|das)\s+/, '').replace(/\s+/g, ' ').trim();
const base = read('assets/content_catalog_v1.json'), legacy = read('assets/legacy_vocabulary_v1.json');
const known = new Set([...base.items.map(w => w.level + ':' + normalize(w.lemma)), ...legacy.items.map(w => w.level + ':' + normalize(w.german))]);
const prior = read('assets/missions_catalog_v1.json').missions;
const priorWords = read('assets/mission_vocabulary_v1.json');
const archivePath = 'assets/missions_archive_v1.json';
const archive = fs.existsSync(path.join(root, archivePath)) ? read(archivePath).missions : [];
const rows = [], newWords = [], kinds = { noun: 0, phrase: 0 };
const thirdReplies = new Map(fs.readFileSync(path.join(root,'tools/content/m11-third-replies.txt'),'utf8').replace(/^\uFEFF/,'').trim().split(/\r?\n/).map(line => {
  const [id,...choices] = line.split('|');
  if (choices.length !== 10 || choices.some(c => !c.trim())) throw Error('Expected ten third replies: '+id);
  return [id,choices];
}));
for (const level of ['A1','A2','B1','B2','C1','C2']) {
  const file = 'tools/content/m11-' + level + '.txt';
  let current;
  for (const [index, raw] of fs.readFileSync(path.join(root, file), 'utf8').replace(/^\uFEFF/, '').split(/\r?\n/).entries()) {
    const line = raw.trim(); if (!line || line.startsWith('//')) continue;
    if (line.startsWith('@')) {
      const h = line.slice(1).split('|');
      if (h.length !== 7) throw Error(file + ':' + (index+1) + ' header needs seven fields');
      current = { level, id:h[0], title:h[1], emoji:h[2], topic:h[3], speaker:h[4], objective:h[5], situation:h[6], source:file, steps:[], vocab:[], lines:[line] };
      rows.push(current);
    } else {
      if (!current) throw Error('Missing mission header'); current.lines.push(line);
      if (line.startsWith('#')) {
        const w = line.slice(1).split('|');
        if (w.length !== 5) throw Error(file + ':' + (index+1) + ' word needs five fields');
        current.vocab.push(w);
      } else {
        const s = line.split('|');
        if (s.length !== 6 || s.some(v => !v.trim())) throw Error(file + ':' + (index+1) + ' dialogue needs six nonempty fields');
        current.steps.push(s);
      }
    }
  }
}
const missions = rows.map((row, missionIndex) => {
  if (row.steps.length !== 10 || row.vocab.length !== 2) throw Error(row.id + ': expected ten exchanges and two vocabulary candidates');
  const useful = [];
  const add = (lemma, meaning, partOfSpeech, article, plural, exampleIndex) => {
    const key = row.level + ':' + normalize(lemma); if (known.has(key)) return false;
    known.add(key); const s = row.steps[exampleIndex];
    if (!s) throw Error('Invalid vocabulary example in ' + row.id);
    const id = 'mission_' + row.level.toLowerCase() + '_' + hash(normalize(lemma)).slice(0,16);
    newWords.push({ schemaVersion:1,id,lemma,meaning,article,plural,partOfSpeech,
      example:s[0] + ' — ' + s[2],exampleTranslation:s[1] + ' — ' + s[3],
      topic:row.topic,level:row.level,source:'Original AI-assisted M11 dialogue, ' + row.source,
      rights:'Original project wording; editorial approval pending.',editorialStatus:'draft',reviewer:'',reviewedAt:'',version:1,
      usageNotes: 'From the mission “' + row.title + '”. Level tag is a practice guide, not certification.',missionId:row.id });
    kinds[partOfSpeech]++; useful.push(id); return true;
  };
  for (const [lemma, meaning, article, plural, example] of row.vocab) {
    if (!['der','die','das'].includes(article) || !plural) throw Error('Invalid noun in ' + row.id);
    const n = Number(example)-1, s = row.steps[n];
    if (!s || !(s[0]+' '+s[2]).toLowerCase().includes(lemma.toLowerCase())) throw Error(row.id + ': example does not contain ' + lemma);
    add(lemma,meaning,'noun',article,plural,n);
  }
  for (const i of [1,3,5,7,0,2,4,6,8,9]) {
    if (useful.length === 4) break;
    add(row.steps[i][2],row.steps[i][3],'phrase','','',i);
  }
  if (useful.length !== 4) throw Error('Not enough new expressions for ' + row.id);
  const thirds = thirdReplies.get(row.id);
  if (!thirds) throw Error('Missing third replies: '+row.id);
  const digest = hash(row.lines.join('\n') + '\n' + thirds.join('\n'));
  const old = prior.find(m => m.id === row.id);
  const version = old ? old.contentDigest === digest ? old.version : old.version + 1 : 1;
  if (old && old.version !== version && !archive.some(m => m.id === old.id && m.version === old.version)) archive.push(old);
  return {id:row.id,version,level:row.level,status:'draft',title:row.title,emoji:row.emoji,
    minutes:['C1','C2'].includes(row.level)?8:['B1','B2'].includes(row.level)?7:6,
    objective:row.objective,situation:row.situation,topic:row.topic,
    source:'Original AI-assisted dialogue; editorial approval pending. ' + row.source,
    contentDigest:digest,usefulWords:useful,
    steps:row.steps.map((s,i)=>{ const correct=(missionIndex+i)%3; const choices = [s[4],thirds[i]]; choices.splice(correct,0,s[2]);
      if (new Set(choices).size !== 3) throw Error('Duplicate reply in '+row.id+':'+i);
      return {id:'turn_'+(i+1),speaker:row.speaker,prompt:s[0],translation:s[1],listening:i===4||i===8,choices,correct,explanation:s[5]}; })};
}).map(m => editorial.mission(prior.find(old => old.id === m.id), m));
for (let i=0; i<newWords.length; i++) newWords[i] = editorial.word(priorWords.items.find(old=>old.id===newWords[i].id),newWords[i]);
for (const level of ['A1','A2','B1','B2','C1','C2']) {
  if (missions.filter(m=>m.level===level).length!==5 || newWords.filter(w=>w.level===level).length!==20) throw Error('Pack coverage mismatch: '+level);
}
if (new Set(missions.map(m=>m.id)).size !== 30) throw Error('Duplicate mission IDs');
write('assets/missions_catalog_v1.json',{schemaVersion:1,missions});
write(archivePath,{schemaVersion:1,missions:archive});
write('assets/mission_vocabulary_v1.json',{schemaVersion:1,version:JSON.stringify(priorWords.items)===JSON.stringify(newWords)?priorWords.version:priorWords.version+1,items:newWords});
const sizes = ['assets/missions_catalog_v1.json',archivePath,'assets/mission_vocabulary_v1.json'].map(file=>{
  const data=fs.readFileSync(path.join(root,file)); return {file,bytes:data.length,gzipBytes:zlib.gzipSync(data).length};
});
const report={missions:missions.length,steps:missions.reduce((n,m)=>n+m.steps.length,0),dialogueTurns:missions.reduce((n,m)=>n+2*m.steps.length,0),newVocabulary:newWords.length,kinds,editorialStatus:editorial.status(missions,'status'),sizes};
write('docs/m11-content-pack-report.json',report); console.log(JSON.stringify(report,null,2));
