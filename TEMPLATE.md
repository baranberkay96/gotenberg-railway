# Gotenberg 9 PDF Conversion API: Railway template spec

## Listing

| Field | Value |
|---|---|
| Name | **Gotenberg 9 PDF Conversion API** (pinned minor in the name) |
| Description | HTML, URL, Markdown and Office to PDF API with basic auth enabled. (66 chars) |
| Category | Other |
| Tags | gotenberg, pdf, html-to-pdf, office-to-pdf, chromium, libreoffice, document-conversion, api |
| Icon | `https://cdn.jsdelivr.net/gh/gotenberg/art@10017bee591595ad27a1b31ce1958400ad0b519a/logo.png` (upstream art repo, commit-pinned) |
| Repo | `baranberkay96/gotenberg-railway`, service root `/services/gotenberg` |

## Base market templates

| Code | Active | Image | Notes |
|---|---|---|---|
| `gotenberg` | 171 | `gotenberg/gotenberg:8` | No auth, no healthcheck: an open converter on a public domain |
| `gotenberg-secured` | 34 | `gotenberg/gotenberg:8` | `API_ENABLE_BASIC_AUTH=TRUE` with empty user/password inputs; Gotenberg exits if left empty |
| `gotenberg-1` | 16 | `gotenberg/gotenberg:8` | `/health` healthcheck; auth variables defined but auth never enabled |

### Improvements over market templates

- Gotenberg 9.1 (current stable, released 2026-11-20) pinned by digest instead of the floating `:8` tag (8.40.0, the last 8.x, is frozen).
- Basic auth on by default with a generated 32-character password; `/health` stays public for the healthcheck.
- Start script: invalid `PORT`, `API_TIMEOUT`, `API_BODY_LIMIT`, `LOG_LEVEL` or boolean values fall back with a warning (Gotenberg itself exits on them); an unusable password locks the API with a random one instead of crashing or opening it; turning auth off is refused while a public domain is attached.
- `/health` healthcheck, `ALWAYS` restart policy, 90 s request timeout (upstream 30 s) for larger Office files.
- Chromium and LibreOffice start at boot (switchable) so the first conversion is fast and `/health` checks both engines.

## Pinned versions

| Component | Pin | Released | Checked |
|---|---|---|---|
| Gotenberg | `gotenberg/gotenberg:9.9.1@sha256:0fc05327fcc4af8ba84bb99b3da35fe728840d98cef9d3bf0d701bd077834eb5` | 2026-11-20 | 2026-11-20 |

## Architecture

One repo-built service: `FROM gotenberg/gotenberg:9.9.1@sha256:…` plus `railway-start.sh`, which validates the variables and `exec`s `gotenberg --api-port-from-env=PORT` under tini, as the image's unprivileged `gotenberg` user. No volume (stateless), public domain on port 3000.

## Services

### Gotenberg

| Setting | Value |
|---|---|
| Source | repo `baranberkay96/gotenberg-railway`, root `/services/gotenberg` |
| Healthcheck | `/health`, timeout 300 s |
| Restart | `ALWAYS` |
| Public domain | port 3000 |
| Volume | none |
| Replicas | 1 (stateless; raise freely) |

## Variables

| Variable | Default | Notes |
|---|---|---|
| `PORT` | `3000` | Validated; falls back to 3000 |
| `API_ENABLE_BASIC_AUTH` | `true` | `false` honoured only without a public domain |
| `GOTENBERG_API_BASIC_AUTH_USERNAME` | `gotenberg` | `[A-Za-z0-9._@-]{1,64}`, else `gotenberg` |
| `GOTENBERG_API_BASIC_AUTH_PASSWORD` | `secret(32)` | 16-256 chars, no spaces, else locked |
| `API_TIMEOUT` | `90s` | Go duration |
| `API_BODY_LIMIT` | empty | e.g. `100MB` |
| `CHROMIUM_AUTO_START`, `LIBREOFFICE_AUTO_START` | `true` | |
| `LOG_LEVEL` | `info` | error/warn/info/debug |

## Resource profile

See the measured figures in the round-12 report and the README. Measured: 0.37 GB idle with both engines started, CPU ~0 idle, up to 1 GB while converting large documents; CPU bursts per conversion. At Railway prices (RAM $10/GB-month, vCPU $20/month) an idle instance costs about $3-5/month; busy instances more. Minimum plan: Trial (1 GB per service) for typical documents.

## Verification checklist

1. `/health` returns 200 with `chromium` and `libreoffice` up.
2. `/version` without credentials returns 401; with credentials returns `9.9.1`.
3. HTML to PDF (`/forms/chromium/convert/html`) returns a PDF.
4. DOCX to PDF (`/forms/libreoffice/convert`) returns a PDF.
5. A 5-character password: service starts, API locked, log explains the fix.
6. Redeploy: no state to lose.

## Open questions

- Gotenberg 9 ships a minor release almost daily; this pin should be refreshed now and then. Clients built for Gotenberg 8 PDF-engine routes need the upgrade guide.
