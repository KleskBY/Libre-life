# Install on an existing Apache 2 website

This uses your existing domain and HTTPS at `https://YOUR-DOMAIN/libre-life/webport/`.
PHP and MySQL need no changes. Apache serves the game as static files.
Use the updated deployment archive containing `apache.conf` and this guide.
Do not install Nginx alongside Apache for this setup.

## 1. Upload and extract

Upload `librelife-web-demos.tar.gz` with SFTP/SCP to your home directory on the VPS.
Over SSH, run:

```sh
mkdir -p ~/librelife-deploy
tar -xzf ~/librelife-web-demos.tar.gz -C ~/librelife-deploy
cd ~/librelife-deploy
sha256sum -c SHA256SUMS
sudo install -d -m 755 /var/www/html/libre-life/webport
sudo cp -R public/. /var/www/html/libre-life/webport/
sudo chmod -R a+rX /var/www/html/libre-life/webport
sudo cp apache.conf /etc/apache2/librelife.conf
sudo a2enmod alias dir mime env rewrite headers
```

The `public/.` spelling copies the contents directly; the resulting file should
be `/var/www/html/libre-life/webport/index.html`, not a nested `public/index.html`.
This assumes your site's `DocumentRoot` is `/var/www/html` and its Libre-life
home page is `/var/www/html/libre-life/index.html`. If `apache2ctl -S` shows a
different DocumentRoot, change both paths consistently. The web port links back
to its parent `../`, so this layout makes the logo/home icon return to the mod page.
You do not need to change ownership to www-data or give Apache write access.

If the Libre-life homepage itself is `/var/www/html/index.html` and appears at
the domain root, use `/var/www/html/webport/` instead and change the `<Directory>`
path in `apache.conf` to match. Copying `public/.` directly into `/var/www/html/`
would publish the game at the domain root and replace the homepage's `index.html`.
It is valid only when that replacement is intentional.

## 2. Add the game to the existing website

Find the active virtual host for your domain:

```sh
sudo apache2ctl -S
```

Edit its configuration file (the command above prints the filename):

```sh
sudo nano /etc/apache2/sites-available/YOUR-SITE.conf
```

Inside the existing `<VirtualHost ...>` block that serves your website, add:

```apache
Include /etc/apache2/librelife.conf
```

For HTTPS hosted directly by Apache this is normally the `*:443` virtual host.
If your current reverse proxy terminates TLS before Apache, use the virtual host
it forwards to. Keep your current domain, certificates, PHP configuration, and
HTTP-to-HTTPS redirects. Do not create a second conflicting virtual host.

Because the files are below the existing DocumentRoot, Apache can serve them
directly; the configuration only supplies MIME types, precompressed-file rules,
and safe directory behavior. If that virtual host has catch-all rewrite rules
routing every URL into PHP,
add this immediately after its `RewriteEngine On` and before those catch-all rules:

```apache
RewriteRule ^/?libre-life/webport(?:/|$) - [L]
```

A catch-all `ProxyPass` is different: add
`ProxyPass /libre-life/webport/ !` before that proxy mapping, if present.

Validate first; reload only if the syntax check succeeds:

```sh
sudo apache2ctl configtest && sudo systemctl reload apache2
```

## 3. Open and check

Visit `https://YOUR-DOMAIN/libre-life/webport/`, including the trailing slash, and press
Launch game. New Game offers Quake 1 Shareware, Hazard Course, and Uplink.
P opens the menu; C crouches. The page also has Menu, Settings, and Resume buttons.

```sh
curl -I https://YOUR-DOMAIN/libre-life/webport/engine/ftewebgl.wasm
curl -I -H 'Accept-Encoding: gzip' https://YOUR-DOMAIN/libre-life/webport/librelife.pk3
curl -I https://YOUR-DOMAIN/libre-life/webport/missing.wasm
```

Expect a WASM content type of `application/wasm`, gzip encoding for the compressed
package, and HTTP 404 for the missing file. HTML returned for WASM or PK3 means
the request is being intercepted by your website routing or an edge rule.
For HTTP 500, inspect `sudo tail -n 50 /var/log/apache2/error.log` (or your
virtual host's custom error log). The configuration requires the modules enabled
above. It is based on Apache's
[precompressed-content example](https://httpd.apache.org/docs/2.4/mod/mod_deflate.html#precompressed)
and [MIME type/encoding rules](https://httpd.apache.org/docs/2.4/mod/mod_mime.html).
It has not been executed on your VPS.

## Cloudflare

Keep the existing DNS/proxy and TLS setup for your working website. No new DNS
record is needed for a subfolder. During initial setup, use a Cache Rule to bypass
cache where URI Path starts with `/libre-life/webport/` if existing rules force caching.
Keep script rewriting/optimization such as Rocket Loader disabled for this path
if you enabled it on the site. A challenge or login page must not replace the
game's JS, WASM, JSON or PK3 downloads.

The supplied config sends `Cache-Control: no-cache` so normal caches revalidate
assets when updated. Cloudflare's actual behavior also depends on your account's
rules; see its [cache defaults](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/).
After replacing the files, purge this path's cached assets if you configured edge
caching. Avoid an edge rule that forces old engine files and new packages to mix.

The initial compressed transfer is approximately 130 MiB. Files take about
357 MiB on disk. Game simulation/rendering run in the browser; the VPS does
not need to run a Quake server or allocate memory for each player's world.
