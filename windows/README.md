# windows/ — this install's launcher

Scripts live in the repository; per-machine output and notes do not.

**Tracked (generic):**

- `Start-openGym.ps1` / `Stop-openGym.ps1` — start the API on `127.0.0.1:30347` and Caddy on the
  LAN `:8443` (HTTPS with the local CA), write `processes.json`, `access.json` and `Caddyfile`
  (all generated, ignored).
- `start-api.mjs` — keeps the unmodified upstream API on loopback only.
- `Allow-iPhone.ps1` — private-network firewall rule for `8080`/`8443`.
- `make-iphone-profile.mjs` / `make-qr.mjs` — the iPhone CA profile and the setup-page QR code.
- `Caddyfile` is written on every start from the detected LAN address, so it is not tracked.

**Local-only (gitignored, never committed):**

`README-zh-CN.md`, `INSTALLATION.json`, `verification.json`, `profile-verification.json`,
`*-preview.png`, `access.json`, `public-origin.txt`, `Caddyfile`, `Tailscale-remote-plan.md`,
`runtime/`, `logs/`, `caddy-storage/`, `setup/`, `processes.json`.

**Server origin:** when `windows/public-origin.txt` exists, `Start-openGym.ps1` makes that public
HTTPS origin the canonical `ORIGIN`/`RP_ID` and puts the LAN origin in `ORIGINS`, so both addresses
can sign in and write. Without it, the LAN address is the origin.

The real deployment record (domains, token URLs, tunnel id, machine paths) belongs to the local
installation, not this repository: `<install>/chatgpt/personal/DEPLOY-zh-CN.md` (gitignored, template
at `<install>/chatgpt/personal.example/DEPLOY-zh-CN.md`). The commit guard
`<install>/chatgpt/scripts/check-personal.mjs` refuses to publish those values.
