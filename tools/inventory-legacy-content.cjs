// Read-only administrative inventory. Never accesses User documents or writes Firestore.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const cli = name => require(path.join(root, '.local-tools/node_modules/firebase-tools/lib', name));
const {configstore} = cli('configstore');
const {requireAuth} = cli('requireAuth');
const {Client} = cli('apiv2');
function value(field) {
  if ('stringValue' in field) return field.stringValue;
  if ('arrayValue' in field) return (field.arrayValue.values || []).map(value);
  if ('mapValue' in field) return Object.fromEntries(Object.entries(field.mapValue.fields || {}).map(([k,v]) => [k,value(v)]));
  if ('integerValue' in field) return Number(field.integerValue);
  if ('doubleValue' in field) return field.doubleValue;
  if ('booleanValue' in field) return field.booleanValue;
  return null;
}
(async()=>{
  await requireAuth({project:'germanreminderapp',user:configstore.get('user'),tokens:configstore.get('tokens')});
  const client = new Client({urlPrefix:'https://firestore.googleapis.com',apiVersion:'v1'});
  const base = '/projects/germanreminderapp/databases/(default)';
  const database = (await client.get(base)).body;
  const documents=[];
  let pageToken;
  do {
    if(documents.length >= 500) throw new Error('Inventory safety limit reached; no partial report written.');
    const response=await client.get(base+'/documents/Generic',{queryParams:{pageSize:50,...(pageToken?{pageToken}:{})}});
    documents.push(...(response.body.documents || []));
    pageToken=response.body.nextPageToken;
  } while(pageToken);
  const entries=documents.map(doc=>{
    const data=Object.fromEntries(Object.entries(doc.fields||{}).map(([k,v])=>[k,value(v)]));
    return {path:doc.name.split('/documents/')[1],updateTime:doc.updateTime,
      sha256:crypto.createHash('sha256').update(JSON.stringify(doc.fields||{})).digest('hex'),
      fields:Object.fromEntries(Object.entries(data).map(([k,v])=>[k,{
        type:Array.isArray(v)?'array':v===null?'null':typeof v,
        ...(Array.isArray(v)?{count:v.length,stringCount:v.filter(x=>typeof x==='string').length,
          uniqueStringCount:new Set(v.filter(x=>typeof x==='string')).size}:{}),
      }])),
      disposition:'retain-original; quarantine-from-reviewed-catalog-until-pairing-and-rights-review'};
  });
  const capturedAt=new Date().toISOString();
  const snapshot={capturedAt,database:{name:database.name,edition:database.databaseEdition,location:database.locationId},documents};
  fs.writeFileSync(path.join(root,'.local-tools/legacy-generic-snapshot.json'),JSON.stringify(snapshot,null,2)+'\n');
  const inventory={capturedAt,database:snapshot.database,documentCount:documents.length,entries};
  fs.writeFileSync(path.join(root,'docs/m02-legacy-inventory.json'),JSON.stringify(inventory,null,2)+'\n');
  console.log(JSON.stringify(inventory,null,2));
})().catch(error=>{console.error(error.message);process.exitCode=1;});
