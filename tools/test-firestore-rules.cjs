// Uses the installed Firebase CLI authentication, never prints credentials.
// Remote Rules API simulation only: no emulator, deployment, or data writes.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const cli = name => require(path.join(root, '.local-tools/node_modules/firebase-tools/lib', name));
const {configstore} = cli('configstore');
const {requireAuth} = cli('requireAuth');
const {Client} = cli('apiv2');
const id = 'p_' + 'a'.repeat(64);
const word = {schemaVersion:1, id, lemma:'Straße'};
const cases = [];
function check(name, method, target, uid, data, expected, prior) {
  const request = {path:'/databases/(default)/documents/' + target, method,
    auth: uid ? {uid,token:{}} : null};
  if(data) request.resource = {data};
  cases.push({name, test:{expectation:expected, request,
    ...(prior ? {resource:{data:prior}} : {})}});
}
for(const [who, uid] of [['owner','alice'],['other','bob'],['anonymous',null]]) {
  for(const method of ['get','create','update']) {
    check(`${who} word ${method}`,method,`User/alice/personalWordsV1/${id}`,uid,
      method==='get'?null:word,who==='owner'?'ALLOW':'DENY',word);
  }
  check(`${who} legacy read`,'get','User/alice',uid,null,who==='owner'?'ALLOW':'DENY',{wordStorage:['Straße']});
  check(`${who} legacy overwrite`,'update','User/alice',uid,{wordStorage:[]},'DENY',{wordStorage:['Straße']});
  check(`${who} curated write`,'create','contentV1/item',uid,{editorialStatus:'published'},'DENY');
  check(`${who} published read`,'get','contentV1/item',uid,null,uid?'ALLOW':'DENY',{editorialStatus:'published'});
  check(`${who} draft read`,'get','contentV1/item',uid,null,'DENY',{editorialStatus:'draft'});
}
for(const method of ['create','update']) {
  for(const [name,data] of Object.entries({extra:{...word,admin:true},oversize:{...word,lemma:'x'.repeat(10001)},wrongType:{...word,lemma:12},missing:{schemaVersion:1,id},wrongId:{...word,id:'other'}})) {
    check(`${method} rejects ${name}`,method,`User/alice/personalWordsV1/${id}`,'alice',data,'DENY',word);
  }
}
check('immutable lemma','update',`User/alice/personalWordsV1/${id}`,'alice',{...word,lemma:'changed'},'DENY',word);
check('unmatched collection','get','Secrets/example','alice',null,'DENY',{});
const state = {schemaVersion:1,itemId:id,dueAt:'2026-11-24T00:00:00Z',lastAttempt:null,intervalSeconds:60,lapseCount:0,schedulerVersion:1};
check('owner state create','create',`User/alice/learningStateV1/${id}`,'alice',state,'ALLOW');
const report = {schemaVersion:1,sourceDigest:'a'.repeat(64),uniqueWords:2,copiedWords:2,invalidEntries:0,reconciled:true};
for(const [who,uid] of [['owner','alice'],['other','bob'],['anonymous',null]]) {
  for(const method of ['get','create','update','delete']) {
    check(`${who} state ${method}`,method,`User/alice/learningStateV1/${id}`,uid,
      ['create','update'].includes(method)?state:null,who==='owner'?'ALLOW':'DENY',state);
  }
  for(const method of ['create','update']) {
    check(`${who} checkpoint ${method}`,method,'User/alice/migrations/personalWordsV1',uid,report,who==='owner'?'ALLOW':'DENY',report);
  }
}
for(const method of ['create','update']) {
  for(const [name,data] of Object.entries({negative:{...state,intervalSeconds:-1},overflow:{...state,lapseCount:1000001},extra:{...state,admin:true},missing:{itemId:id},badDate:{...state,dueAt:'tomorrow'},wrongId:{...state,itemId:'someone-else'}})) {
    check(`${method} state rejects ${name}`,method,`User/alice/learningStateV1/${id}`,'alice',data,'DENY',state);
  }
  check(`${method} incomplete checkpoint`,method,'User/alice/migrations/personalWordsV1','alice',{...report,copiedWords:1},'DENY',report);
}
for(const [limit,expected] of [[50,'ALLOW'],[51,'DENY'],[null,'DENY']]) {
  check(`word list limit ${limit}`,'list',`User/alice/personalWordsV1/${id}`,'alice',null,expected,word);
  cases[cases.length-1].test.request.query=limit===null?{}:{limit};
}
(async()=>{
  await requireAuth({project:'germanreminderapp',user:configstore.get('user'),tokens:configstore.get('tokens')});
  const client=new Client({urlPrefix:'https://firebaserules.googleapis.com',apiVersion:'v1'});
  const response=await client.post('/projects/germanreminderapp:test',{
    source:{files:[{name:'firestore.rules',content:fs.readFileSync(path.join(root,'firestore.rules'),'utf8')}]},
    testSuite:{testCases:cases.map(c=>c.test)}
  },{skipLog:{body:true}});
  const result=response.body;
  const summary = {issues:result.issues || [],results:result.testResults?.map((t,i)=>({name:cases[i].name,state:t.state,errors:t.errors}))};
  fs.writeFileSync(path.join(root,'docs/m01-rules-test-results.json'),JSON.stringify(summary,null,2)+'\n');
  console.log(JSON.stringify({tests:cases.length,passed:result.testResults?.filter(t=>t.state==='SUCCESS').length,issues:summary.issues,
    failures:summary.results?.filter(t=>t.state!=='SUCCESS')},null,2));
  if(result.issues?.some(i=>i.severity==='ERROR') || !result.testResults ||
    result.testResults.length!==cases.length || result.testResults.some(t=>t.state!=='SUCCESS')) process.exitCode=1;
})().catch(e=>{console.error(e.message);process.exitCode=1;});
