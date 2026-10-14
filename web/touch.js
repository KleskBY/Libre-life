/* Touch controls for the FTEQW web launchers (phones and tablets).
 *
 * Layout follows the Zircon/DarkPlaces Android Quake layout: a movement stick on the
 * left, aiming on the right, action buttons above the right thumb and the menu button
 * in the top-left corner. The engine receives input the same way as desktop play:
 *  - movement: a virtual "standard" gamepad left stick (FTE polls navigator.getGamepads()
 *    every frame), so walking speed is analog;
 *  - aiming: relative mouse deltas through FTE's own mouse callback, so aim follows the
 *    finger exactly and respects the player's sensitivity setting;
 *  - buttons: console commands (+attack/-attack etc.), independent of key binds.
 * While a menu or the console is open FTE stops asking for pointer lock; the sticks then
 * step aside and taps become absolute mouse clicks. (FTE's own touch path passes unscaled
 * page coordinates, which miss on high-DPI phones.)
 *
 * Pages may define window.TOUCH_BUTTONS before this script:
 *   [{id, label, command, hold?, x, y, size?}]  x/y: % from right/bottom edge.
 * Force on/off with ?touch=1 or ?touch=0. Load before launcher.js. */
(() => {
  'use strict';
  const params = new URLSearchParams(location.search);
  const coarse = window.matchMedia?.('(pointer: coarse)').matches && navigator.maxTouchPoints > 0;
  if (params.get('touch') === '0' || (params.get('touch') !== '1' && !coarse)) return;

  const LOOK_SCALE = 2.5;   // mouse units per CSS pixel of finger travel
  const STICK_RADIUS = 56;  // CSS px for full deflection
  const buttons = window.TOUCH_BUTTONS || [
    {id: 'fire', label: 'Fire', command: '+attack', hold: true, x: 6, y: 26, size: 84},
    {id: 'jump', label: 'Jump', command: '+jump', hold: true, x: 22, y: 10, size: 64},
    {id: 'next', label: 'Next', command: 'impulse 10', x: 5, y: 58, size: 50},
  ];

  document.documentElement.classList.add('touch-mode');
  const style = document.createElement('style');
  style.textContent = `
.touch-mode .key-strip { display: none; }
#touch-ui { position: absolute; inset: 0; z-index: 5; pointer-events: none; user-select: none; -webkit-user-select: none; -webkit-touch-callout: none; }
#touch-ui[hidden] { display: none; }
#touch-ui .zone { position: absolute; top: 18%; bottom: 0; pointer-events: auto; touch-action: none; }
#touch-ui .zone.move { left: 0; width: 45%; }
#touch-ui .zone.look { right: 0; width: 55%; }
#touch-ui.menu-open .zone, #touch-ui.menu-open .action, #touch-ui.menu-open .stick { display: none; }
#touch-ui .zone.tap { display: none; inset: 0; }
#touch-ui.menu-open .zone.tap { display: block; }
#touch-ui .stick { position: absolute; width: ${STICK_RADIUS * 2}px; height: ${STICK_RADIUS * 2}px; margin: -${STICK_RADIUS}px 0 0 -${STICK_RADIUS}px; border: 2px solid rgba(255,255,255,.35); border-radius: 50%; background: rgba(255,255,255,.06); pointer-events: none; }
#touch-ui .stick::after { content: ""; position: absolute; left: 50%; top: 50%; width: 46px; height: 46px; margin: -23px 0 0 -23px; border-radius: 50%; background: rgba(255,255,255,.35); transform: translate(var(--kx, 0px), var(--ky, 0px)); }
#touch-ui .stick.idle { opacity: .45; }
#touch-ui .btn { position: absolute; display: grid; place-items: center; border: 2px solid rgba(255,255,255,.4); border-radius: 50%; color: rgba(255,255,255,.85); background: rgba(13,110,253,.25); font: 600 13px/1 system-ui, sans-serif; letter-spacing: .5px; text-transform: uppercase; pointer-events: auto; touch-action: none; }
#touch-ui .btn.down { background: rgba(13,110,253,.65); border-color: #fff; }
#touch-ui .btn.menu, #touch-ui .btn.screen { top: 10px; width: 46px; height: 46px; border-radius: 8px; background: rgba(0,0,0,.35); }
#touch-ui .btn.menu { left: 10px; }
#touch-ui .btn.back { display: none; left: 66px; top: 10px; height: 46px; padding: 0 14px; border-radius: 8px; background: rgba(0,0,0,.35); }
#touch-ui.menu-open .btn.back { display: grid; }
#touch-ui .btn.screen { right: 10px; }
#touch-ui .btn.menu svg, #touch-ui .btn.screen svg { width: 22px; height: 22px; fill: none; stroke: currentColor; stroke-width: 2; stroke-linecap: round; }
#touch-rotate { position: absolute; inset: 0; z-index: 6; display: none; place-items: center; padding: 24px; color: #fff; text-align: center; font: 16px/1.5 system-ui, sans-serif; background: rgba(11,16,20,.92); }
#touch-rotate button { margin-top: 14px; padding: 10px 18px; border: 0; border-radius: 6px; color: #fff; background: #0d6efd; font: 600 15px/1 system-ui, sans-serif; }
@media (orientation: portrait) { .touch-running #touch-rotate { display: grid; } }
.game-frame:fullscreen, .game-frame.touch-fullscreen { width: 100vw !important; height: 100vh !important; max-width: none !important; aspect-ratio: auto !important; margin: 0 !important; border: 0 !important; border-radius: 0 !important; }
.game-frame.touch-fullscreen { position: fixed !important; inset: 0; z-index: 10000; height: 100dvh !important; }
.touch-fs main { z-index: 10000 !important; }
.touch-fs body { overflow: hidden; }
.game-frame:fullscreen #canvas, .game-frame.touch-fullscreen #canvas { width: 100% !important; height: 100% !important; aspect-ratio: auto !important; }
`;
  document.head.appendChild(style);

  const frame = document.querySelector('.game-frame');
  const canvas = document.getElementById('canvas');
  // Emscripten pins the canvas to a screen-derived inline size (!important) whenever the
  // fullscreen element is the canvas's direct parent, as .game-frame is here. Mid-rotation
  // that size is the stale portrait one, and FTE measures the pinned canvas on every later
  // resize, so the game stayed small and portrait-shaped. A layout-neutral wrapper keeps
  // the frame from being the canvas's parent.
  const canvasBox = document.createElement('div');
  canvasBox.style.display = 'contents';
  canvas.before(canvasBox);
  canvasBox.appendChild(canvas);
  const ui = document.createElement('div');
  ui.id = 'touch-ui';
  ui.hidden = true;
  ui.innerHTML = '<div class="zone move"></div><div class="zone look"></div><div class="zone tap"></div>' +
    '<div class="stick idle"></div>' +
    '<button class="btn menu" type="button" aria-label="Menu"><svg viewBox="0 0 24 24"><path d="M5 7h14M5 12h14M5 17h14"/></svg></button>' +
    '<button class="btn back" type="button" aria-label="Back">Back</button>' +
    '<button class="btn screen" type="button" aria-label="Toggle fullscreen"><svg viewBox="0 0 24 24"><path d="M9 4H4v5M15 4h5v5M9 20H4v-5M15 20h5v-5"/></svg></button>';
  const rotate = document.createElement('div');
  rotate.id = 'touch-rotate';
  rotate.innerHTML = '<div>Rotate your device to landscape to play.<br><button type="button">Go fullscreen</button></div>';
  frame.append(ui, rotate);

  const capture = (element, id) => { try { element.setPointerCapture(id); } catch (error) { /* pointer already gone */ } };
  const engineReady = () => typeof window.FTEC?.cbufadd === 'function' && window.FTEC.evcb?.jaxis;
  const command = text => { if (engineReady()) window.FTEC.cbufadd(text + '\n'); };

  // Virtual gamepad. FTE crashes if it sees a pad before its callbacks exist, and it
  // tracks button edges on the button objects themselves, so they must persist.
  const pad = {id: 'quake.zone touch controls', index: 0, connected: true, mapping: 'standard', timestamp: 0,
    axes: [0, 0, 0, 0], buttons: Array.from({length: 17}, () => ({pressed: false, touched: false, value: 0}))};
  const nativeGetGamepads = navigator.getGamepads ? navigator.getGamepads.bind(navigator) : () => [];
  navigator.getGamepads = () => {
    const real = [...(nativeGetGamepads() || [])].filter(Boolean);
    if (!engineReady()) return real;
    pad.index = real.length;
    pad.timestamp = performance.now();
    return [...real, pad];
  };

  // Floating movement stick: appears where the left thumb lands.
  const stick = ui.querySelector('.stick');
  const moveZone = ui.querySelector('.zone.move');
  let moveId = null, originX = 0, originY = 0;
  const parkStick = () => {
    const rect = ui.getBoundingClientRect();
    stick.style.left = `${Math.min(rect.width * .16, 140)}px`;
    stick.style.top = `${rect.height - Math.min(rect.height * .28, 130)}px`;
    stick.style.setProperty('--kx', '0px');
    stick.style.setProperty('--ky', '0px');
    stick.classList.add('idle');
  };
  moveZone.addEventListener('pointerdown', event => {
    if (moveId !== null) return;
    moveId = event.pointerId;
    capture(moveZone, moveId);
    const rect = ui.getBoundingClientRect();
    originX = event.clientX; originY = event.clientY;
    stick.style.left = `${originX - rect.left}px`;
    stick.style.top = `${originY - rect.top}px`;
    stick.classList.remove('idle');
    event.preventDefault();
  });
  moveZone.addEventListener('pointermove', event => {
    if (event.pointerId !== moveId) return;
    let dx = event.clientX - originX, dy = event.clientY - originY;
    const length = Math.hypot(dx, dy);
    if (length > STICK_RADIUS) { dx *= STICK_RADIUS / length; dy *= STICK_RADIUS / length; }
    stick.style.setProperty('--kx', `${dx}px`);
    stick.style.setProperty('--ky', `${dy}px`);
    pad.axes[0] = dx / STICK_RADIUS;
    pad.axes[1] = dy / STICK_RADIUS;
  });
  const releaseMove = event => {
    if (event.pointerId !== moveId) return;
    moveId = null;
    pad.axes[0] = pad.axes[1] = 0;
    parkStick();
  };
  moveZone.addEventListener('pointerup', releaseMove);
  moveZone.addEventListener('pointercancel', releaseMove);

  // Aiming: every finger that drags on the look zone or on a held button turns the view.
  const last = new Map();
  const look = event => {
    const previous = last.get(event.pointerId);
    if (!previous) return;
    last.set(event.pointerId, {x: event.clientX, y: event.clientY});
    const dx = (event.clientX - previous.x) * LOOK_SCALE, dy = (event.clientY - previous.y) * LOOK_SCALE;
    if ((dx || dy) && engineReady() && window.FTEC.evcb.mouse && window.wasmTable)
      window.wasmTable.get(window.FTEC.evcb.mouse)(0, false, dx, dy, 0, 0);
  };
  const startLook = event => last.set(event.pointerId, {x: event.clientX, y: event.clientY});
  const endLook = event => last.delete(event.pointerId);
  const lookZone = ui.querySelector('.zone.look');
  lookZone.addEventListener('pointerdown', event => { capture(lookZone, event.pointerId); startLook(event); event.preventDefault(); });
  lookZone.addEventListener('pointermove', look);
  lookZone.addEventListener('pointerup', endLook);
  lookZone.addEventListener('pointercancel', endLook);

  for (const spec of buttons) {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = `btn action ${spec.id}`;
    button.textContent = spec.label;
    const size = spec.size || 60;
    Object.assign(button.style, {right: `${spec.x}%`, bottom: `${spec.y}%`, width: `${size}px`, height: `${size}px`});
    button.addEventListener('pointerdown', event => {
      event.preventDefault();
      capture(button, event.pointerId);
      button.classList.add('down');
      startLook(event);
      command(spec.command);
    });
    const release = event => {
      endLook(event);
      button.classList.remove('down');
      if (spec.hold) command(spec.command.replace(/^\+/, '-'));
    };
    button.addEventListener('pointermove', look);
    button.addEventListener('pointerup', release);
    button.addEventListener('pointercancel', release);
    ui.appendChild(button);
  }
  ui.querySelector('.btn.menu').addEventListener('click', () => command(window.PLAY_CONFIG?.menuCommands?.menu || 'togglemenu'));
  // Escape steps back one menu level (and closes the console).
  const key = (down, code) => { if (engineReady() && window.FTEC.evcb.key) window.wasmTable.get(window.FTEC.evcb.key)(0, down, code, 0); };
  ui.querySelector('.btn.back').addEventListener('click', () => { key(true, 27); setTimeout(() => key(false, 27), 120); });

  // Menu taps: absolute mouse position in canvas pixels, then a left click.
  const tapZone = ui.querySelector('.zone.tap');
  const pointTo = event => {
    const rect = canvas.getBoundingClientRect();
    if (engineReady() && window.FTEC.evcb.mouse) window.wasmTable.get(window.FTEC.evcb.mouse)(0, true,
      (event.clientX - rect.left) * canvas.width / rect.width, (event.clientY - rect.top) * canvas.height / rect.height, 0, 0);
  };
  const click = down => { if (engineReady() && window.FTEC.evcb.button) window.wasmTable.get(window.FTEC.evcb.button)(0, down, 0); };
  // The engine samples the button once per frame: press a little after the cursor move
  // and keep it held briefly, or a quick tap can be missed entirely.
  let tapId = null, pressedAt = 0, pressTimer = 0;
  tapZone.addEventListener('pointerdown', event => {
    if (tapId !== null) return;
    tapId = event.pointerId;
    capture(tapZone, tapId);
    event.preventDefault();
    pointTo(event);
    pressedAt = 0;
    pressTimer = setTimeout(() => { pressedAt = performance.now(); click(true); }, 60);
  });
  tapZone.addEventListener('pointermove', event => { if (event.pointerId === tapId) pointTo(event); });
  const endTap = event => {
    if (event.pointerId !== tapId) return;
    tapId = null;
    const release = () => setTimeout(() => click(false), Math.max(0, 120 - (performance.now() - pressedAt)));
    if (pressedAt) release();
    else {
      clearTimeout(pressTimer);
      setTimeout(() => { pressedAt = performance.now(); click(true); release(); }, 60);
    }
  };
  tapZone.addEventListener('pointerup', endTap);
  tapZone.addEventListener('pointercancel', endTap);
  // An owning game can release every held input after focus/orientation changes.
  window.addEventListener('play-release-inputs', () => {
    moveId = null;
    pad.axes[0] = pad.axes[1] = 0;
    last.clear();
    clearTimeout(pressTimer);
    tapId = null;
    click(false);
    for (const spec of buttons) if (spec.hold) command(spec.command.replace(/^\+/, '-'));
    for (const button of ui.querySelectorAll('.down')) button.classList.remove('down');
    parkStick();
  });
  ui.addEventListener('contextmenu', event => event.preventDefault());

  // Fullscreen the whole frame (not just the canvas) so the controls stay visible.
  // Rotation and fullscreen changes can report the old viewport first, and FTE only
  // resizes on window resize: repeat it once the new layout has settled.
  const settle = () => {
    canvas.style.removeProperty('width');
    canvas.style.removeProperty('height');
    for (const delay of [0, 150, 400, 800]) setTimeout(() => window.dispatchEvent(new Event('resize')), delay);
  };
  document.addEventListener('fullscreenchange', settle);
  window.addEventListener('orientationchange', settle);
  screen.orientation?.addEventListener?.('change', settle);
  window.visualViewport?.addEventListener('resize', () => { if (document.fullscreenElement || frame.classList.contains('touch-fullscreen')) settle(); });

  const pseudoFullscreen = on => {   // iPhone Safari has no element fullscreen
    frame.classList.toggle('touch-fullscreen', on);
    document.documentElement.classList.toggle('touch-fs', on);
    settle();
  };
  const fullscreen = () => {
    if (document.fullscreenElement || frame.classList.contains('touch-fullscreen')) return;
    if (frame.requestFullscreen && document.fullscreenEnabled) {
      frame.requestFullscreen({navigationUI: 'hide'})
        .then(() => screen.orientation?.lock?.('landscape').catch(() => {}))
        .catch(() => pseudoFullscreen(true));
    } else pseudoFullscreen(true);
  };
  const fullscreenButton = document.getElementById('fullscreen');
  const toggleFullscreen = event => {
    event.stopImmediatePropagation();
    if (document.fullscreenElement) document.exitFullscreen().catch(() => {});
    else if (frame.classList.contains('touch-fullscreen')) pseudoFullscreen(false);
    else fullscreen();
  };
  fullscreenButton?.addEventListener('click', toggleFullscreen, true);
  ui.querySelector('.btn.screen').addEventListener('click', toggleFullscreen);
  // Fullscreen is what lets Android lock landscape, so offer it on the rotate prompt.
  rotate.querySelector('button').addEventListener('click', fullscreen);
  document.getElementById('play')?.addEventListener('click', fullscreen);
  document.addEventListener('fullscreenchange', () => setTimeout(parkStick, 100));

  // Show the controls once the engine runs; hide the sticks while menus/console are up.
  const poll = () => {
    if (!canvas.hidden && engineReady()) {
      if (ui.hidden) {
        ui.hidden = false;
        document.documentElement.classList.add('touch-running');
        parkStick();
        const status = document.getElementById('status');
        if (status) status.textContent = 'Left thumb moves, drag on the right to aim. Menu button: top-left.';
      }
      const inMenu = window.FTEC.pointerwantlock === 0 || window.FTEC.pointerwantlock === false;
      if (inMenu !== ui.classList.contains('menu-open')) {
        ui.classList.toggle('menu-open', inMenu);
        if (inMenu) window.dispatchEvent(new Event('play-release-inputs'));
      }
    }
  };
  setInterval(poll, 100);
  window.addEventListener('resize', () => { if (moveId === null) parkStick(); });
})();
