// Public source previews only. No API key, cookies, page scripts or model calls.
import https from 'node:https';
import { lookup } from 'node:dns/promises';
import { isIP } from 'node:net';
import { publicUrl } from './project.mjs';

export function publicIPv4(address) {
  if (isIP(address) !== 4) return false;
  const [a,b,c] = address.split('.').map(Number);
  return !(a === 0 || a === 10 || a === 127 || a >= 224 ||
    a === 100 && b >= 64 && b <= 127 || a === 169 && b === 254 ||
    a === 172 && b >= 16 && b <= 31 || a === 192 && (b === 168 || b === 0 || b === 2) ||
    a === 198 && (b === 18 || b === 19 || b === 51 && c === 100) ||
    a === 203 && b === 0 && c === 113);
}

// DNS is checked and pinned to the TLS connection, including every redirect.
// IPv6 is deliberately unsupported; no fallback to an unchecked address.
export async function readPublic(url, {signal, maxBytes = 650_000,
  resolve = lookup, request = https.request, redirects = 2} = {}) {
  const safe = publicUrl(url);
  if (!safe) throw Error('Blocked URL');
  signal?.throwIfAborted();
  const u = new URL(safe);
  const addresses = await new Promise((accept,reject) => {
    const abort=()=>reject(signal.reason || Error('Cancelled'));
    signal?.addEventListener('abort',abort,{once:true});
    Promise.resolve().then(()=>resolve(u.hostname,{all:true,family:4})).then(accept,reject)
      .finally(()=>signal?.removeEventListener('abort',abort));
  });
  signal?.throwIfAborted();
  if (!addresses.length || addresses.some(a => !publicIPv4(a.address))) throw Error('Blocked address');
  const selected = addresses[0].address;
  const response = await new Promise((accept,reject) => {
    const req = request(u, {method:'GET', agent:false, signal,
      lookup:(_host, options, callback) => callback(null, options?.all ? [{address:selected,family:4}] : selected, 4),
      headers:{'User-Agent':'RealHero/0.3.1 (public source preview)',
        Accept:'text/html,image/jpeg,image/png,image/webp', 'Accept-Encoding':'identity'}}, accept);
    req.on('error', reject); req.end();
  });
  if ([301,302,303,307,308].includes(response.statusCode)) {
    response.destroy();
    if (redirects <= 0 || !response.headers.location) throw Error('Redirect limit');
    return readPublic(new URL(response.headers.location,u).href,
      {signal,maxBytes,resolve,request,redirects:redirects-1});
  }
  if (response.statusCode !== 200 || Number(response.headers['content-length'] || 0) > maxBytes ||
    response.headers['content-encoding'] && response.headers['content-encoding'] !== 'identity') {
    response.destroy(); throw Error('Unavailable resource');
  }
  const chunks=[]; let bytes=0;
  try {
    for await (const chunk of response) {
      bytes += chunk.length;
      if (bytes > maxBytes) throw Error('Resource too large');
      chunks.push(chunk);
    }
  } catch(error) { response.destroy(); throw error; }
  return {url:u.href, type:String(response.headers['content-type'] || '').split(';')[0].toLowerCase(),
    body:Buffer.concat(chunks)};
}

function decode(value) {
  return value.replace(/&(?:amp|quot|apos|lt|gt|#\d+|#x[\da-f]+);/gi, entity => {
    const known={'&amp;':'&','&quot;':'"','&apos;':"'",'&lt;':'<','&gt;':'>'};
    if (known[entity.toLowerCase()]) return known[entity.toLowerCase()];
    const code = entity[2].toLowerCase()==='x' ? parseInt(entity.slice(3),16) : parseInt(entity.slice(2),10);
    return code > 0 && code <= 0x10ffff ? String.fromCodePoint(code) : '';
  });
}
export function previewCandidates(html, pageUrl) {
  const found=[];
  // Only publisher-declared page preview metadata. Never execute HTML or follow
  // arbitrary img tags (ads, trackers, unrelated navigation images).
  for (const tag of html.match(/<meta\b[^>]{0,4096}>/gi) || []) {
    const attrs={};
    for (const m of tag.matchAll(/([\w:-]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/g))
      attrs[m[1].toLowerCase()]=decode(m[2] ?? m[3] ?? m[4]);
    if (!['og:image','og:image:secure_url','twitter:image','twitter:image:src'].includes((attrs.property || attrs.name || '').toLowerCase())) continue;
    try {
      const url=publicUrl(new URL(attrs.content,pageUrl).href);
      if (url && !/(?:logo|favicon|sprite|placeholder|avatar|tracking|pixel)(?:[\W_]|$)/i.test(url) && !found.includes(url)) found.push(url);
    } catch { /* malformed publisher metadata */ }
  }
  return found.slice(0,3);
}
export function isRaster(resource) {
  const b=resource.body;
  return resource.type==='image/jpeg' && b.length>1000 && b[0]===255 && b[1]===216 && b[2]===255 ||
    resource.type==='image/png' && b.length>1000 && b.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])) &&
      b.length>=24 && b.readUInt32BE(16)>=200 && b.readUInt32BE(20)>=150 ||
    resource.type==='image/webp' && b.length>1000 && b.toString('ascii',0,4)==='RIFF' && b.toString('ascii',8,12)==='WEBP';
}

export async function enrichImages(sources, {read = readPublic, signal = AbortSignal.timeout(7000)} = {}) {
  const used=new Set();
  // At most four source pages, three candidates per page, all within one deadline.
  const results=await Promise.all(sources.slice(0,4).map(async source => {
    const verify=async url => {
      if (!url || signal.aborted) return '';
      try {
        const image=await read(url,{signal,maxBytes:3_000_000});
        return isRaster(image) ? publicUrl(image.url) : '';
      } catch { return ''; }
    };
    let imageUrl=await verify(source.imageUrl);
    let origin=imageUrl ? 'search' : '';
    if (!imageUrl && !signal.aborted) {
      try {
        const page=await read(source.url,{signal});
        if (['text/html','application/xhtml+xml'].includes(page.type)) {
          for (const candidate of previewCandidates(page.body.toString('utf8'),page.url)) {
            imageUrl=await verify(candidate);
            if (imageUrl) { origin='page_preview'; break; }
          }
        }
      } catch { /* blocked/unavailable page stays a useful source link */ }
    }
    return {...source,imageUrl,imageOrigin:origin,
      // Page preview isn't a claim that the assistant inspected this costume.
      title:origin==='page_preview' ? `Превью страницы: ${source.title}`.slice(0,240) : source.title};
  }));
  return [...results,...sources.slice(4).map(s=>({...s,imageUrl:''}))].map(s=>{
    if (!s.imageUrl) return s;
    if (used.has(s.imageUrl)) return {...s,imageUrl:''};
    used.add(s.imageUrl); return s;
  });
}

export function applyVisualStatus(data, wanted) {
  if (!wanted) return;
  const count=data.sources.filter(s=>s.imageUrl).length;
  data.visualStatus=count>=3 ? 'available' : count ? 'partial' : 'unavailable';
  // The model wrote its reply before this independent retrieval step. Do not
  // preserve an unsupported assertion that three actual pictures were shown.
  const notice=count ? `Изображений доступно: ${count}. Превью страницы может показывать обложку, а не конкретный костюм. Остальные фотографии — по ссылке на источник.`
    : 'Картинки получить не удалось: ниже пока только ссылки, визуальная подборка не готова.';
  data.reply = `${notice}\n\n${data.reply}`;
}
