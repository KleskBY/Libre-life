/* Libre-life / Q.U.A.L.K.E.R. FTEQW WebAssembly launcher (kept in step with quake.zone/play/shared/launcher.js).
 * FTE's Module.files mounts ArrayBuffers directly into its virtual filesystem. */
const canvas = document.getElementById('canvas');
const statusElement = document.getElementById('status');
const progress = document.getElementById('progress');
const play = document.getElementById('play');
const mapSelect = document.getElementById('map');
const logElement = document.getElementById('log');
const logLines = [];
let build;
let failed = false;
// Quit from the game menu: FTE calls Module.close (otherwise history.back()/window.close()).
// Skip FTE's own "leave page?" prompt and the errors the engine raises while unwinding.
let quitting = false;
window.addEventListener('beforeunload', event => { if (quitting) event.stopImmediatePropagation(); }, true);
function quitGame() {
  quitting = true;
  statusElement.textContent = 'Game closed. Returning…';
  document.exitPointerLock?.();
  window.close(); // Succeeds only for tabs opened by a script; otherwise go back to the parent page.
  location.replace(new URL('../', location.href));
}

function log(message) {
  logLines.push(String(message));
  if (logLines.length > 500) logLines.shift();
  logElement.textContent = logLines.join('\n');
  if (!quitting && /SV_Error:|Host_Error:|csqc error|RuntimeError:|memory access out of bounds|Not enough addressable memory|32bit qc statement support was disabled/.test(String(message))) {
    failed = true;
    statusElement.textContent = 'The game stopped with an engine error. See engine log; reload to retry.';
    progress.hidden = true;
  }
}
const originalConsoleLog = console.log.bind(console);
console.log = (...args) => { originalConsoleLog(...args); log(args.join(' ')); };
function fail(error) {
  if (quitting) return;
  failed = true;
  statusElement.textContent = `Unable to start: ${error.message || error}. See engine log; reload to retry.`;
  progress.hidden = true;
  log(error.stack || error);
}
window.addEventListener('error', event => fail(event.error || event.message));
window.addEventListener('unhandledrejection', event => fail(event.reason));
canvas.addEventListener('contextmenu', event => event.preventDefault());
// FTE listens on both document and canvas and consumes keydown + legacy keypress,
// which doubles console input. Route focused canvas key events into FTE exactly once.
function routeGameKeyboardEvent(event) {
  if (typeof window.FTEC?.handleevent !== 'function') return;
  // FTE's document listener must not consume text entered in page controls.
  if (event.target !== canvas) {
    if (event.target.closest?.('input, textarea, select, button, [contenteditable]')) event.stopImmediatePropagation();
    return;
  }
  event.stopImmediatePropagation();
  // Keep Ctrl/Alt/Meta combinations for the browser (Ctrl+W must never reach the game).
  if (event.ctrlKey || event.metaKey || event.altKey) return;
  if (event.type === 'keypress') {
    event.preventDefault();
    return;
  }
  if (event.type === 'keydown' && event.code === 'KeyP' && !event.ctrlKey && !event.altKey && !event.metaKey) {
    document.exitPointerLock?.();
  }
  window.FTEC.handleevent(event);
}
for (const type of ['keypress', 'keydown', 'keyup']) {
  document.addEventListener(type, routeGameKeyboardEvent, true);
}
canvas.addEventListener('webglcontextlost', event => {
  event.preventDefault();
  fail('The browser lost its graphics context');
});

async function download(url, expectedBytes, expectedHash) {
  // The content hash in the query string keeps CDN caches from mixing old and new packages.
  const response = await fetch(expectedHash ? `${url}?v=${expectedHash}` : url, {cache: expectedHash ? 'default' : 'no-cache'});
  if (!response.ok) throw new Error(`${url}: HTTP ${response.status}`);
  const reader = response.body.getReader();
  const chunks = [];
  const allocated = expectedBytes ? new Uint8Array(expectedBytes) : null;
  let received = 0;
  progress.hidden = false;
  progress.max = expectedBytes || Number(response.headers.get('content-length')) || 1;
  while (true) {
    const {done, value} = await reader.read();
    if (done) break;
    if (allocated) {
      if (received + value.byteLength > allocated.byteLength) throw new Error('Package size differs from build.json. Refresh the deployed files and CDN cache.');
      allocated.set(value, received);
    } else chunks.push(value);
    received += value.byteLength;
    progress.value = received;
    statusElement.textContent = `Loading ${url}: ${(received / 1048576).toFixed(1)} MiB`;
  }
  if (expectedBytes && received !== expectedBytes) throw new Error('Incomplete or stale game package. Refresh the deployed files and CDN cache.');
  const buffer = allocated || new Uint8Array(received);
  let offset = 0;
  for (const chunk of chunks) { buffer.set(chunk, offset); offset += chunk.byteLength; }
  if (expectedHash && window.crypto?.subtle) {
    const hash = [...new Uint8Array(await crypto.subtle.digest('SHA-256', buffer))].map(value => value.toString(16).padStart(2, '0')).join('');
    if (hash !== expectedHash) throw new Error('Game package does not match build.json. Sync both files and purge the CDN cache.');
  }
  return buffer.buffer;
}

// Explicit arguments prevent arbitrary query strings becoming engine commands.
var Module = window.Module = {
  canvas,
  close: quitGame,
  files: {},
  arguments: [],
  locateFile: name => `engine/${name}`,
  print: log,
  printErr: log,
  printError: log,
  setStatus: text => { if (!failed && text) statusElement.textContent = text; },
  onAbort: reason => fail(reason || 'WebAssembly aborted'),
  postRun: [() => {
    Module.files = {};
    progress.hidden = true;
    if (failed) return;
    if (typeof Module.sched !== 'function') return fail('FTE did not start its game loop');
    statusElement.textContent = 'Click the game to capture the mouse and enable audio. P opens the menu; Esc releases the mouse.';
    document.getElementById('fullscreen').disabled = false;
    document.getElementById('settings').disabled = false;
    document.getElementById('menu').disabled = false;
    document.getElementById('resume').disabled = false;
    canvas.focus({preventScroll: true});
    document.querySelector('.game-frame').scrollIntoView({behavior: 'smooth', block: 'center'});
  }],
};

play.addEventListener('click', async () => {
  play.disabled = true;
  mapSelect.disabled = true;
  try {
    if (!window.WebAssembly) throw new Error('WebAssembly is unavailable');
    const probe = document.createElement('canvas');
    const gl = probe.getContext('webgl2') || probe.getContext('webgl');
    if (!gl) throw new Error('WebGL is unavailable; enable hardware acceleration');
    gl.getExtension('WEBGL_lose_context')?.loseContext();
    Module.files['default.fmf'] = await download('default.fmf');
    Module.files['data/pak0.pk3'] = await download(build.package, build.packageBytes, build.packageSha256);
    // Uncapped, vsync-paced frames: a cl_maxfps cap below the display rate judders on 90/120 Hz screens.
    Module.arguments = ['-nohome', '+exec', 'web.cfg', '+cl_maxfps', '0'];
    if (build.game === 'qualker' && mapSelect.value === 'wild') Module.arguments.push('+coop', '1', '+set', 'gamemode', '8', '+teamplay', '1');
    if (mapSelect.value) Module.arguments.push('+map', mapSelect.value);
    document.getElementById('launcher').hidden = true;
    canvas.hidden = false;
    statusElement.textContent = 'Starting FTEQW…';
    const script = document.createElement('script');
    script.src = 'engine/ftewebgl.js';
    script.onerror = () => fail('Could not load the engine JavaScript');
    document.head.appendChild(script);
  } catch (error) { fail(error); }
});

document.getElementById('fullscreen').addEventListener('click', async () => {
  try { await canvas.requestFullscreen(); canvas.focus(); }
  catch (error) { statusElement.textContent = `Fullscreen unavailable: ${error.message}`; }
});

for (const action of ['menu', 'settings', 'resume']) {
  document.getElementById(action).addEventListener('click', () => {
    if (failed || typeof window.FTEC?.cbufadd !== 'function') return;
    document.exitPointerLock?.();
    window.FTEC.cbufadd(`menu_cmd ${action}\n`);
    canvas.focus();
  });
}

fetch('build.json', {cache: 'no-cache'}).then(response => {
  if (!response.ok) throw new Error(`build.json: HTTP ${response.status}`);
  return response.json();
}).then(info => {
  build = info;
  for (const name of ['', ...info.maps]) {
    const option = document.createElement('option');
    option.value = name;
    option.textContent = info.campaigns?.find(campaign => campaign.map === name)?.label || name || 'Main menu';
    mapSelect.appendChild(option);
  }
  const requested = new URLSearchParams(location.search).get('map');
  mapSelect.value = info.maps.includes(requested) ? requested : info.startMap;
  mapSelect.disabled = false;
  play.disabled = false;
  play.textContent = 'Launch game';
  const buildDate = info.builtAt ? ` · Updated ${new Date(info.builtAt).toLocaleDateString()}` : '';
  document.getElementById('build-info').textContent = `${info.maps.length} maps · ${(info.packageBytes / 1048576).toFixed(1)} MiB game assets${buildDate}`;
  statusElement.textContent = 'Ready. Desktop keyboard and mouse recommended.';
}).catch(fail);
