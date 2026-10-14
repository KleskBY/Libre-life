/* Requires Playwright and an installed Edge (or set WEB_BROWSER_CHANNEL). */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');

(async () => {
  const output = path.resolve(__dirname, '../.web-test');
  fs.mkdirSync(output, {recursive: true});
  const browser = await chromium.launch({
    headless: true,
    channel: process.env.WEB_BROWSER_CHANNEL || 'msedge',
  });
  const page = await browser.newPage({viewport: {width: 1280, height: 960}});
  const logs = [];
  const errors = [];
  page.on('console', message => logs.push(message.text()));
  page.on('pageerror', error => errors.push(error.message));
  page.on('dialog', async dialog => { errors.push(dialog.message()); await dialog.dismiss(); });
  async function command(value) {
    await page.evaluate(text => FTEC.cbufadd(text + '\n'), value);
  }
  async function inspect(expression) {
    let text;
    for (let attempt = 0; attempt < 5; attempt++) {
      const result = page.waitForEvent('console', {predicate: message => message.text().startsWith('Result:')});
      await command(expression);
      text = (await result).text();
      if (text !== 'Result: (unable to evaluate)') return text;
      await page.waitForTimeout(100);
    }
    return text;
  }
  try {
    await page.goto(process.env.WEB_TEST_URL || 'http://127.0.0.1:8000/');
    const build = await (await page.request.get(new URL('build.json', page.url()).href)).json();
    await page.getByRole('button', {name: 'Launch game'}).waitFor();
    await page.waitForFunction(() => document.querySelector('.launcher-logo').complete && document.querySelector('.launcher-logo').naturalWidth > 0);
    await page.waitForFunction(() => document.fonts.check('16px "Share Tech Mono"') && document.fonts.check('16px "Oswald"'));
    const railBox = await page.locator('.control-rail').boundingBox();
    const frameBox = await page.locator('.game-frame').boundingBox();
    assert(railBox.x < frameBox.x, 'Icon control rail must be left of the game frame');
    await page.screenshot({path: path.join(output, 'launcher.png')});
    await page.locator('#map').selectOption(build.profile === 'demos' ? '' : 't0a0');
    await page.getByRole('button', {name: 'Launch game'}).click();
    await page.waitForFunction(() => document.getElementById('launcher').hidden && getComputedStyle(document.getElementById('launcher')).display === 'none', null, {timeout: 300000});
    if (build.profile === 'demos') {
      assert.equal(build.maps.length, 19);
      assert(!build.maps.includes('c0a0'));
      assert.deepEqual(build.campaigns.map(campaign => campaign.label),
        ['Quake 1 Shareware', 'Half-Life: Uplink', 'Hazard Course']);
      await page.waitForFunction(() => !document.getElementById('menu').disabled, null, {timeout: 60000});
      await page.waitForTimeout(1000);
      assert.equal(await inspect('poke_menuqc menu_enabled'), 'Result: 1');
      await page.screenshot({path: path.join(output, 'main-menu.png')});
      await command('map t0a0');
      await page.locator('#resume').click();
    }
    await page.waitForFunction(() => document.getElementById('log').textContent.includes('Hazard Course'), null, {timeout: 60000});
    await page.waitForTimeout(1000);
    let before;
    for (let attempt = 0; attempt < 50; attempt++) {
      before = await inspect('poke_csqc pmove_org');
      if (before !== "Result: '0 0 0'") break;
      await page.waitForTimeout(100);
    }
    assert.match(before, /Result: '[\d .-]+'/);
    assert.notEqual(before, "Result: '0 0 0'", 'Wait for the client to finish spawning before testing movement');
    await page.locator('#canvas').click({position: {x: 600, y: 350}});
    await page.keyboard.down('a');
    await page.waitForTimeout(1200);
    await page.keyboard.up('a');
    const after = await inspect('poke_csqc pmove_org');
    assert.notEqual(before, after, 'Keyboard movement must change the CSQC player position');
    await page.screenshot({path: path.join(output, 'movement.png')});
    await page.keyboard.press('Backquote');
    await page.waitForTimeout(150);
    await page.keyboard.type('echo webinputok');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(250);
    assert(logs.some(line => line.trim() === 'webinputok'), 'Console keyboard input must enter each character once');
    assert(!logs.some(line => line.includes('eecchhoo')), 'Console keyboard input must not be doubled');
    await page.keyboard.press('Backquote');
    await page.waitForTimeout(150);
    await page.keyboard.press('p');
    await page.waitForTimeout(150);
    assert.equal(await inspect('poke_menuqc menu_enabled'), 'Result: 1');
    await page.screenshot({path: path.join(output, 'menu.png')});
    await page.keyboard.press('p');
    await page.waitForTimeout(150);
    assert.equal(await inspect('poke_menuqc menu_enabled'), 'Result: 0');
    await page.waitForFunction(() => document.pointerLockElement === null);
    await page.locator('#settings').click();
    assert.equal(await inspect('poke_menuqc win_settings.ui_win_open'), 'Result: 1');
    assert.equal(await inspect('poke_menuqc menu_enabled'), 'Result: 1');
    await page.screenshot({path: path.join(output, 'settings.png')});
    await page.locator('#resume').click();
    assert.equal(await inspect('poke_menuqc menu_enabled'), 'Result: 0');
    await page.locator('#menu').click();
    assert.equal(await inspect('poke_menuqc menu_enabled'), 'Result: 1');
    await page.locator('#resume').click();
    const changed = page.waitForEvent('console', {predicate: message => message.text().includes('Changing map')});
    await command('map t0a0b');
    await changed;
    await page.waitForTimeout(4000);
    assert.match(await inspect('poke_csqc mapname'), /t0a0b/);
    await page.screenshot({path: path.join(output, 'second-map.png')});
    if (build.profile === 'demos') {
      for (const level of ['start', 'e1m1', 'hldemo1']) {
        await command('map ' + level);
        await page.waitForTimeout(level === 'hldemo1' ? 45000 : 5000);
        assert.match(await inspect('poke_csqc mapname'), new RegExp(level));
        await page.screenshot({path: path.join(output, level + '.png')});
      }
    }
    const fatal = logs.filter(line => /SV_Error:|Host_Error:|csqc error|Not enough addressable memory|32bit qc statement support was disabled/.test(line));
    assert.deepEqual([...errors, ...fatal], [], 'No JavaScript or fatal VM errors');
    console.log(`PASS: ${build.profile}, Hazard Course movement (${before} → ${after}), P menu, MenuQC page buttons, second map${build.profile === 'demos' ? ', conditional campaigns, Quake start/e1m1, Uplink intro' : ''}. Evidence: ${output}`);
  } finally {
    fs.writeFileSync(path.join(output, 'engine.log'), logs.join('\n'));
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
