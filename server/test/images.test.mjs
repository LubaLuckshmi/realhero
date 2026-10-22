import test from 'node:test';
import assert from 'node:assert/strict';
import { Readable } from 'node:stream';
import { EventEmitter } from 'node:events';
import { readPublic, publicIPv4, previewCandidates, enrichImages, applyVisualStatus } from '../images.mjs';
const jpeg=Buffer.concat([Buffer.from([255,216,255]),Buffer.alloc(1200)]);
const picture=url=>({url,type:'image/jpeg',body:jpeg});
const html=(url,body)=>({url,type:'text/html',body:Buffer.from(body)});

test('real-world text-only search sources obtain publisher previews without another model call',async()=>{
  const calls=[];
  const refs=[{url:'https://theatre.example/nutcracker',title:'Щелкунчик',imageUrl:''}];
  const result=await enrichImages(refs,{read:async url=>{
    calls.push(url);
    return url===refs[0].url ? html(url,'<meta content="/photos/nutcracker.jpg?a=1&amp;b=2" property="og:image">') : picture(url);
  }});
  assert.equal(result[0].imageUrl,'https://theatre.example/photos/nutcracker.jpg?a=1&b=2');
  assert.equal(result[0].imageOrigin,'page_preview');
  assert.match(result[0].title,/Превью страницы/);
  assert.equal(calls.length,2);
});
test('blocked images remain links, preserve the actual assistant reply, and cannot claim visual success',async()=>{
  const sources=await enrichImages([{url:'https://theatre.example/show',title:'Спектакль',imageUrl:'https://cdn.example/fail.jpg'}],
    {read:async()=>{throw Error('403');}});
  const data={sources,reply:'Для коллекции полезны костюмы из этой постановки.'};
  applyVisualStatus(data,true);
  assert.equal(data.visualStatus,'unavailable');
  assert.match(data.reply,/Картинки получить не удалось/);
  assert.match(data.reply,/Для коллекции полезны/);
  assert.equal(data.sources[0].imageUrl,'');
});
test('metadata rejects logos, scripts, insecure URLs and duplicate images',async()=>{
  assert.deepEqual(previewCandidates(`<meta property="og:image" content="https://cdn.example/logo.png">
    <meta name='twitter:image' content='javascript:alert(1)'>
    <meta property="og:image" content="http://cdn.example/photo.jpg">
    <script>image='https://cdn.example/invented.jpg'</script>`, 'https://theatre.example/'),[]);
  const sources=await enrichImages([1,2].map(n=>({url:`https://theatre.example/${n}`,title:'Спектакль',imageUrl:'https://cdn.example/same.jpg'})),{read:async url=>picture(url)});
  assert.equal(sources.filter(s=>s.imageUrl).length,1);
  const data={sources,reply:'Костюмы.'};applyVisualStatus(data,true);assert.equal(data.visualStatus,'partial');
});
test('HTML pretending to be a photo never becomes an image',async()=>{
  const sources=await enrichImages([{url:'https://theatre.example/a',imageUrl:'https://cdn.example/a.jpg',title:'А'}],
    {read:async url=>({url,type:'image/jpeg',body:Buffer.alloc(1200)})});
  assert.equal(sources[0].imageUrl,'');
});
test('private, metadata, reserved and mapped IPs are blocked',async()=>{
  for(const ip of ['127.0.0.1','10.0.0.1','172.16.2.3','169.254.169.254','192.168.0.1','100.64.0.1','198.18.0.1','203.0.113.1','224.0.0.1','::ffff:127.0.0.1']) assert.equal(publicIPv4(ip),false,ip);
  assert.equal(publicIPv4('93.184.216.34'),true);
  let network=0;
  await assert.rejects(readPublic('https://theatre.example/',{resolve:async()=>[{address:'127.0.0.1'}],request:()=>{network++;}}),/Blocked/);
  assert.equal(network,0);
});
function fakeRequest(responses, inspect=()=>{}) {
  return (u,options,callback)=>{
    inspect(u,options);
    const req=new EventEmitter();
    req.end=()=>{const r=responses.shift();const stream=Readable.from(r.chunks || [Buffer.from(r.body || '')]);
      Object.assign(stream,{statusCode:r.status || 200,headers:r.headers || {}});callback(stream);};
    return req;
  };
}
test('HTTPS pins checked DNS, follows public redirects, and enforces byte limit',async()=>{
  let calls=0;
  const request=fakeRequest([{status:302,headers:{location:'/gallery'}},{body:'photo page',headers:{'content-type':'text/html'}}],(_,options)=>{
    calls++;assert.equal(options.headers.Authorization,undefined);assert.equal(options.agent,false);
    options.lookup('theatre.example',{},(_,ip,family)=>{assert.equal(ip,'93.184.216.34');assert.equal(family,4);});
  });
  const resolve=async()=>[{address:'93.184.216.34'}];
  const r=await readPublic('https://theatre.example/',{resolve,request});assert.equal(r.url,'https://theatre.example/gallery');assert.equal(calls,2);
  await assert.rejects(readPublic('https://theatre.example/',{resolve,request:fakeRequest([{chunks:[Buffer.alloc(8),Buffer.alloc(8)]}]),maxBytes:10}),/large/);
});
test('redirect to internal host is blocked before second connection',async()=>{
  let calls=0;
  const request=fakeRequest([{status:302,headers:{location:'https://internal.example/secret'}}],()=>calls++);
  const resolve=async host=>[{address:host==='internal.example'?'10.0.0.1':'93.184.216.34'}];
  await assert.rejects(readPublic('https://theatre.example/',{request,resolve}),/Blocked/);assert.equal(calls,1);
});
