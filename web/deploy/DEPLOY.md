# Libre-life web demo package

Contains Quake 1 Shareware (start + e1m1–e1m8), Half-Life: Uplink
(hldemo1–hldemo3), and the Hazard Course (seven t0a0* maps).
All maps run with Libre-life's gameplay. The full Half-Life campaign is absent
and its New Game button is hidden. Other campaign buttons also depend on their
starting maps being installed. The launcher defaults to the main menu.

## Choose your web server

Already running Apache 2? Follow [APACHE.md](APACHE.md) and use `apache.conf`.
It adds `/libre-life/webport/` below your existing DocumentRoot, including sites behind Cloudflare.
The instructions below are for a VPS where you choose Nginx as the web server.

## Install with Nginx

Upload `librelife-web-demos.tar.gz` to your account using SCP/SFTP. Extract it
into a new directory, then run these commands from the extracted directory:

```sh
sha256sum -c SHA256SUMS
sudo apt update
sudo apt install nginx
sudo install -d -m 755 /var/www/librelife
sudo cp -R public/. /var/www/librelife/
sudo chmod -R a+rX /var/www/librelife
sudo cp nginx.conf /etc/nginx/sites-available/librelife
sudo nano /etc/nginx/sites-available/librelife
```

Replace `game.example.com` with your domain, point its DNS record at the VPS,
then enable the site:

```sh
sudo ln -s /etc/nginx/sites-available/librelife /etc/nginx/sites-enabled/librelife
sudo nginx -t
sudo systemctl reload nginx
```

For an initial IP-only test, use your server's public IP in `server_name`.
Keep any existing sites intact. If the symlink already exists, reuse it.
Allow inbound TCP 80 and 443 through your existing firewall/provider rules.
Configure HTTPS for your domain using your existing certificate manager or
reverse proxy before sharing the site. The supplied configuration is the HTTP
origin; it does not provision DNS or certificates.

Only `public/` is the web root. No Python, Node, Quake server, compiler, GPU,
or database is needed on the VPS. The game runs on each player's computer.
The 1-core/2-GB VPS serves static files; bandwidth and disk space determine
how many first-time downloads it can support. See `package-info.json` for sizes.

The archive includes original files and precompressed `.gz` copies.
Nginx's [gzip_static module](https://nginx.org/en/docs/http/ngx_http_gzip_static_module.html)
serves these without compressing each request. Check `nginx -V` for
`--with-http_gzip_static_module`; if unavailable, remove `gzip_static on;`
and the original files still work. Do not rename `.gz` files over originals.
The configuration deliberately revalidates cached files so updates do not mix
old engine code and new assets. Do not enable an HTML fallback for missing files.

## Check after installing

```sh
curl -I http://game.example.com/engine/ftewebgl.wasm
curl -I -H 'Accept-Encoding: gzip' http://game.example.com/librelife.pk3
curl -I http://game.example.com/not-a-real-file.wasm
```

Expect `application/wasm`, `Content-Encoding: gzip`, and HTTP 404 respectively.
Open the site in a desktop browser, launch the main menu, and choose New Game.
It should show Quake 1 Shareware, Hazard Course, and Half-Life: Uplink only.
P opens the menu and releases mouse capture; C crouches. The page's Menu,
Settings and Resume buttons also work. Esc and Ctrl combinations stay available
to the browser.

## Updating and limitations

To rebuild from the repository:

```sh
python tools/web_build.py --profile demos
python tools/web_deploy.py
```

Requires Python with Pillow, FTEQCC and the local game assets on the build
computer. Update the whole public directory together during a maintenance
window; active sessions retain their already downloaded assets until reload.

This remains an experimental port: full playthroughs, audio playback and reliable
persistent saves have not been certified. The custom quicksave integration needs
further work. Read `public/NOTICES.txt` for content and engine provenance.
