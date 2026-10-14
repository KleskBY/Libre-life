const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const output = path.resolve(__dirname, '../.web-test', process.env.WEB_TEST_NAME || 'zoom');
fs.mkdirSync(output, {recursive:true});
(async()=>{
 const browser = await chromium.launch({channel:process.env.WEB_BROWSER_CHANNEL || 'msedge',headless:true});
 const page = await browser.newPage({viewport:{width:1440,height:1000}});
 const logs=[], errors=[], measurements=[];
 page.on('console',m=>logs.push(m.text()));
 page.on('pageerror',e=>errors.push(e.message));
 await page.addInitScript(()=>{
  for(const cls of [WebGLRenderingContext,window.WebGL2RenderingContext].filter(Boolean)){
   const original=cls.prototype.uniformMatrix4fv;
   cls.prototype.uniformMatrix4fv=function(location,transpose,data,...args){
    const offset=args[0] || 0, m=data.subarray(offset,offset+16);
    const depth=Math.hypot(m[3],m[7],m[11]);
    if(depth>0.01){
     window.zoomProjection={x:Math.hypot(m[0],m[4],m[8])/depth,y:Math.hypot(m[1],m[5],m[9])/depth};
    }
    return original.call(this,location,transpose,data,...args);
   };
  }
 });
 async function cmd(s){await page.evaluate(text=>FTEC.cbufadd(text+'\n'),s)}
 async function sample(zoom){
  await cmd('poke_ssqc 1.viewzoom='+zoom);
  await page.waitForTimeout(350);
  const projection=await page.evaluate(()=>window.zoomProjection);
  assert(projection && projection.x>0 && projection.y>0, 'No perspective projection captured');
  return projection;
 }
 try{
  const url=new URL(process.env.WEB_TEST_URL || 'http://127.0.0.1:8002/webport/');
  const build=await (await page.request.get(new URL('build.json',url).href)).json();
  const qualker=build.game==='qualker';
  url.searchParams.set('map',qualker?'lobby':'t0a0');
  await page.goto(url.href);
  await page.locator('#play:not([disabled])').click();
  await page.locator('#menu:not([disabled])').waitFor({timeout:180000});
  await page.waitForTimeout(8000);
  await cmd('menu_cmd resume\ncon_notifytime 0');
  if(qualker)await cmd('poke_ssqc 1.qk_psyGrip=1');
  for(const ratio of ['16 / 9','4 / 3','9 / 16','21 / 9']){
   await page.evaluate(value=>{document.getElementById('canvas').style.aspectRatio=value;window.dispatchEvent(new Event('resize'));},ratio);
   await page.waitForTimeout(600);
   for(const mode of [4,0,1,2,3]){
    await cmd('scr_fov_mode '+mode);
    const base=await sample(1);
    const [width,height]=ratio.split('/').map(Number);
    assert(Math.abs(base.y/base.x/(width/height)-1)<0.01, 'Canvas aspect ratio was not applied');
    for(const zoom of [254/255,0.8,0.5,254/255,1,0]){
     const p=await sample(zoom), quantized=zoom===0?1:Math.round(zoom*255)/255;
     for(const axis of ['x','y'])assert(Math.abs(p[axis]*quantized/base[axis]-1)<0.002,`Projection discontinuity: ${ratio}, mode ${mode}, zoom ${zoom}, ${axis}`);
     assert(Math.abs((p.x/p.y)/(base.x/base.y)-1)<0.002,'Zoom changed aspect ratio');
     measurements.push({ratio,mode,zoom,base,projection:p});
    }
    console.log(`PASS ${build.game || 'librelife'} ${ratio}, FOV mode ${mode}`);
   }
  }
  assert.deepEqual(errors,[]);
  assert.deepEqual(logs.filter(s=>/RuntimeError|Host_Error:|SV_Error:|csqc error/.test(s)),[]);
  console.log('PASS zoom-in, zoom-out, unset zoom, all FOV modes and screen shapes');
 }finally{
  fs.writeFileSync(path.join(output,'measurements.json'),JSON.stringify(measurements,null,2));
  fs.writeFileSync(path.join(output,'engine.log'),logs.join('\n'));
  await browser.close();
 }
})().catch(e=>{console.error(e);process.exitCode=1});
