# INK RIDER

A phone-first, draw-a-road physics game. You sketch a line of ink across the screen, a
rider drops onto it, and you try to carry enough speed through your own handwriting to
reach the flag without eating dirt.

**Play: https://jimdo-png.github.io/ink-rider/**

Works on iPhone, iPad, Android and desktop. Nothing to install, nothing to sign up for.

## How to play

**On a phone or tablet**

1. Open the link. Turn the phone sideways if it asks — the world is a landscape playfield.
2. Drag your finger to draw the road. Draw hills to build speed and ramps to get air.
3. Tap **GO**. **UNDO** takes back the last stroke, **CLEAR** wipes the canvas.
4. In the air, hold the left or right half of the screen to lean and land clean.
5. Reach the flag. Grab stars on the way for a better medal.

**On a desktop**

Same thing with the mouse, plus `SPACE` to go, `Z` to undo and `R` to retry.

## Where your progress lives

Levels cleared, medals and best times are written to your browser's **localStorage** — a
private store on your own device, tied to this one site. It never leaves the device. There
is no account, no login, no server, no database, no analytics and no third-party scripts of
any kind. Clearing your browser data for this site erases your progress, and that is the
only way it disappears.

## How it is built

The whole game is a **single static HTML file** — markup, styles, engine, artwork and audio
all inline, no build step at runtime, no CDN, no fonts, no images fetched over the network.
Sound is synthesised in the browser with the Web Audio API. Once the page has loaded it
needs no network at all, so it keeps working on a plane or in a tunnel.

It is served by GitHub Pages over HTTPS from the root of `main`. `.nojekyll` tells Pages to
publish the files exactly as committed.

## Security

Full plain-English threat model: [SECURITY.md](SECURITY.md).

Every build **must** carry this exact tag in `<head>`, and `audit.sh` fails without it:

```html
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'">
```

Read it directive by directive:

| Directive | Effect |
| --- | --- |
| `default-src 'none'` | Deny everything by default. Anything not listed below cannot load. This is what kills `connect-src` (no `fetch`/XHR/WebSocket/beacon — no data can be sent anywhere), `object-src` (no Flash/embeds), `frame-src`, `worker-src` and `media-src`. |
| `img-src 'self' data:` | Images only from this repo or inline `data:` URIs. No remote image can be used as a tracking pixel. |
| `style-src 'self' 'unsafe-inline'` | Inline `<style>` is required — the game is one file. No external stylesheet. |
| `script-src 'self' 'unsafe-inline'` | Inline `<script>` is required for the same reason. No external script, no CDN, so an injected `<script src="//evil">` is dead on arrival. |
| `base-uri 'none'` | Nothing can rewrite the document base and re-point relative URLs elsewhere. |
| `form-action 'none'` | No form can post anywhere, so no credential-harvesting form can be smuggled in. |
| `frame-ancestors 'none'` | No other site may embed this page in an iframe (anti-clickjacking). |

Two honest caveats:

- `frame-ancestors` is **ignored** when delivered in a `<meta>` tag; browsers only honour it
  as a real HTTP header, and GitHub Pages does not let us set headers. The build therefore
  also carries a three-line inline frame-buster that refuses to render inside a frame. Keep
  both.
- `'unsafe-inline'` is unavoidable for a single-file game, so CSP is not the last line of
  defence against XSS here. It doesn't need to be: the page takes **no** untrusted input.
  No URL parameters are read, no user text is rendered as HTML, and nothing is fetched. The
  only writable surface is the player's own localStorage on their own device.

Adding a web app manifest later would need `manifest-src 'self'` appended to the CSP. Until
then, the `apple-mobile-web-app-capable` meta tag covers home-screen install on iOS.

## Auditing a build before it ships

```sh
./audit.sh index.html
```

Greps the built file for network calls, dynamic code execution, external resources, cookies
and anything shaped like a credential, and checks the CSP tag is present. Exits non-zero on
a real finding. `localStorage.setItem` is reported but never fails the run — saving progress
is the point.

## Licence

MIT. See [LICENSE](LICENSE).
