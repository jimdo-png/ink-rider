# Security — INK RIDER

Written for a non-engineer. If you only read one line: there is no server, so there is
almost nothing to attack.

## What this thing actually is

INK RIDER is one HTML file sitting on GitHub's web hosting. When you open the link, GitHub
hands your browser a copy of that file and the conversation ends. The game then runs
entirely inside your own browser, on your own phone or laptop.

There is no login, no account, no database, no API, no server that runs our code, and no
company collecting anything. Nothing you do in the game is transmitted anywhere.

## What an attacker cannot do

- **Steal user data from us.** We hold none. There is no user table to dump because there is
  no user table, no server, and no user accounts.
- **Break in through the game.** The usual ways into a web app — SQL injection, a leaky API,
  a broken login, server-side code execution — all need a server that runs our code. Pages
  only serves static files; it will never execute anything on our behalf.
- **Take the site down by attacking it.** It's hosted on GitHub's infrastructure, which is
  built to absorb that.
- **Read the player's saved progress from somewhere else.** Browsers isolate localStorage
  per site. Only pages served from `jimdo-png.github.io` can read this game's storage.
- **Reach a private machine through it.** Nothing on a personal computer, home network, or
  work laptop is exposed by publishing a static page.

## What the Content-Security-Policy adds

Every build carries a strict Content-Security-Policy — a set of rules the browser enforces
about what the page is allowed to do. Ours starts from "deny everything" and grants back
only the bare minimum. In practice it prevents three things:

1. **Injected code that loads more code.** The classic XSS payload is a `<script>` tag
   pointing at an attacker's server. Our policy allows no external scripts from anywhere, so
   that tag simply doesn't run.
2. **Clickjacking.** `frame-ancestors 'none'` tells browsers no other website may hide the
   game inside an invisible frame and trick players into clicking things. (Caveat: browsers
   only enforce this rule when it arrives as an HTTP header, and GitHub Pages doesn't let us
   set headers. The build carries a short inline frame-buster as a backstop.)
3. **Data exfiltration.** There is no `connect-src` permission at all, so the page is
   forbidden from opening any network connection — no `fetch`, no XHR, no WebSocket, no
   tracking beacon. Even if hostile code somehow ran on the page, the browser would block it
   from sending anything out. Nothing can phone home, because nothing can phone.

`audit.sh` in this repo re-checks all of that mechanically. Run it before every publish.

## What data exists, and where

| Data | Where it lives | Who can see it |
| --- | --- | --- |
| Levels cleared, medals, best times | localStorage in the player's own browser | Only that player, on that device |
| Everything else | Nothing else exists | — |

No cookies. No analytics. No fonts, CDNs or third-party scripts, so no third party is even
told the page was opened. GitHub sees the same web-server request logs any host sees, which
we neither control nor collect.

Progress is not backed up. Clearing browser data for this site wipes it, and that is the
only way it can be lost.

## The one risk that is real

Anyone can copy a public repo. Someone could fork INK RIDER, modify it — including in ugly
ways — and host their copy at their own address.

That is a copy, not this site. It cannot change what `jimdo-png.github.io/ink-rider/` serves,
and it cannot touch anyone's saved progress here, because browser storage is walled off per
site. The only real cost is reputational: someone could pass off a bad version as the
original. If that ever happens, report the fork to GitHub and point people at the canonical
URL.

The one way that risk becomes serious is if the **GitHub account itself** is compromised —
whoever controls the account controls what the real URL serves.

## Keeping the account safe

- **Turn on two-factor authentication** on the GitHub account, and keep the recovery codes
  somewhere offline. This is the single highest-value control here.
- **Keep personal access tokens narrow and short-lived.** Prefer fine-grained tokens scoped
  to this one repository, with an expiry date. A broad, non-expiring `repo` token is the
  thing you least want leaked.
- **Never commit a token, key or password.** `audit.sh` scans for the common shapes
  (`ghp_`, `sk-`, `AKIA`, PEM blocks), but a public repo means a leaked secret is public
  instantly, so treat prevention as the control and the scan as the net.

## If the account is ever compromised

1. Change the GitHub password and sign out all other sessions
   (Settings → Sessions → revoke).
2. Revoke every personal access token and OAuth app authorisation
   (Settings → Developer settings, and Settings → Applications).
3. Check Settings → SSH and GPG keys and remove anything unfamiliar.
4. Turn 2FA on, or reset it if it was already on.
5. In this repo: check Settings → Collaborators, Settings → Webhooks and the Actions tab for
   anything that wasn't put there deliberately. This project uses **no** Actions and **no**
   webhooks, so anything present is suspect.
6. Compare the served file against a known-good local copy, run `./audit.sh`, and
   force-restore from a clean copy if it differs.

## Reporting a problem

Open an issue on the repository. Please don't include personal information in it — issues on
a public repo are public.
