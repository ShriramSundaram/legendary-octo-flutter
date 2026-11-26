const fs = require('node:fs');
const path = require('node:path');
const {createHash} = require('node:crypto');
const root = path.resolve(__dirname, '..');
const read = file => JSON.parse(fs.readFileSync(path.join(root, file), 'utf8'));
const catalog = read('assets/content_catalog_v1.json');
const quizzes = read('assets/quiz_catalog_v1.json');
const queue = read('.local-tools/legacy-content-candidates.json');
const escape = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const field = (label, value) => `<p><strong>${escape(label)}:</strong> ${escape(value)}</p>`;
const byId = new Map(catalog.items.map(item => [item.id, item]));
const priority = queue.candidates.filter(c => c.warnings.length || c.possibleExistingItemIds.length);
const proposal = c => c.german?.normalize('NFD').replace(/\u0323/gu, '').normalize('NFC') ?? '';
const card = (section, id, title, body) => `<article data-section="${section}"><h3>${escape(title)}</h3><code>${escape(id)}</code>${body}</article>`;
const words = catalog.items.map(w => card('words', w.id, `${w.level} · ${[w.article,w.lemma].filter(Boolean).join(' ')}`,
  field('Meaning',w.meaning)+field('Example',w.example)+field('Translation',w.exampleTranslation)+
  field('Topic / type',`${w.topic} / ${w.partOfSpeech}`)+field('Plural',w.plural)+field('Usage',w.usageNotes)+
  field('Source',w.source)+field('Rights',w.rights)+field('Status',w.editorialStatus)));
const questions = quizzes.items.map(q => card('quizzes', q.id, `${q.level} · ${q.question}`,
  field('Linked word',q.itemId)+`<ol>${q.options.map((option,i)=>`<li>${escape(option)}${i===q.correctOption?' <strong>— keyed answer</strong>':''}</li>`).join('')}</ol>`+
  field('Explanation',q.explanation)+field('Source',q.source)+field('Rights',q.rights)+field('Status',q.editorialStatus)));
const legacy = priority.map(c => card('legacy',c.id,`${c.level} · ${c.raw}`,
  field('Original (unchanged)',c.raw)+field('Source',`${c.sourcePath}; zero-based indexes ${c.sourceIndexes.join(', ')}`)+
  field('Flags',c.warnings.join(', ') || 'Possible catalog overlap')+
  (proposal(c)!==c.german?field('Unapproved spelling proposal',proposal(c))+field('Proposal rule','Remove dot-below marks only; preserve umlauts. Verify spelling and meaning independently.'):'')+
  field('Parsed English',c.meaning)+field('Possible matches',c.possibleExistingItemIds.map(id=>`${id}: ${byId.get(id)?.meaning ?? ''}`).join('; ') || 'None')+
  field('Decision needed','Keep separate, merge by sense, correct or withdraw. No automatic merge or publication.')));
const html = `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>M02 content review</title><style>
body{font:16px/1.55 system-ui,sans-serif;background:#f6f4ef;color:#183042;margin:0}main{max-width:1000px;margin:auto;padding:24px}
header{position:sticky;top:0;background:#f6f4ef;padding:12px 0;border-bottom:1px solid #cbd5d6}h1{margin:0;font-size:26px}h3{margin:0 0 8px}
article{background:white;border:1px solid #cbd5d6;border-radius:12px;padding:20px;margin:16px 0;overflow-wrap:anywhere}p{margin:8px 0}code{font-size:12px}
input,select{padding:12px;border:1px solid #647a84;border-radius:6px;font:inherit;max-width:100%;box-sizing:border-box}input{width:60%}[hidden]{display:none}
</style><main><header><h1>M02 content reference</h1><p>${catalog.items.length} words · ${quizzes.items.length} quizzes · ${priority.length} priority legacy candidates</p>
<label>Search <input id="search" type="search" placeholder="Word, level, ID or meaning"></label>
<label>Section <select id="section"><option value="all">All</option><option value="words">Vocabulary</option><option value="quizzes">Quizzes</option><option value="legacy">Priority legacy</option></select></label><p id="count" aria-live="polite"></p></header>
<p>The owner accepted the content for offline inclusion on 2026-11-25; catalog cards show their current publication status. This is not independent German or CEFR certification. This reference page does not apply decisions. Existing Firebase vocabulary is owner-declared original writing. Its dot-below marks may be pronunciation annotations; proposed standard spellings remain unapplied. All source strings remain intact.</p>
<p>Record decisions by stable ID in a separate review record, naming the actual reviewer and date. This file never saves, uploads or changes app content. Reviewed items must still pass the catalog validator before publication.</p>
${[...words,...questions,...legacy].join('\n')}</main><script>
const cards=[...document.querySelectorAll('article')];
function filter(){const term=document.getElementById('search').value.toLocaleLowerCase();const section=document.getElementById('section').value;let count=0;for(const card of cards){card.hidden=!(section==='all'||card.dataset.section===section)||!card.textContent.toLocaleLowerCase().includes(term);if(!card.hidden)count++;}document.getElementById('count').textContent=count+' records shown';}
document.getElementById('search').addEventListener('input',filter);document.getElementById('section').addEventListener('change',filter);filter();
</script></html>`;
const out = path.join(root,'.local-tools/m02-content-review.html');
fs.writeFileSync(out,html);
const manifest = {
  schemaVersion:1,
  catalogVersion:catalog.version,
  wordCount:catalog.items.length,
  quizCount:quizzes.items.length,
  legacyCandidateCount:queue.candidateCount,
  priorityLegacyCount:priority.length,
  ownerProvenanceDeclaration:{date:'2026-11-25',statement:'Existing Firebase vocabulary is my own original writing',source:'Project owner chat response',editorialApproval:false},
  inputHashes:Object.fromEntries(['assets/content_catalog_v1.json','assets/quiz_catalog_v1.json','.local-tools/legacy-content-candidates.json'].map(file=>[file,createHash('sha256').update(fs.readFileSync(path.join(root,file))).digest('hex')])),
  localReviewFile:'.local-tools/m02-content-review.html',
  publicationDecisionsApplied:false,
};
fs.writeFileSync(path.join(root,'docs/m02-review-manifest.json'),JSON.stringify(manifest,null,2)+'\n');
console.log(JSON.stringify({wordCount:manifest.wordCount,quizCount:manifest.quizCount,priorityLegacyCount:priority.length,output:out}));
