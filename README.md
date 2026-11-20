# Deploy and Host Gotenberg with Railway

Gotenberg is an open-source API that converts HTML, URLs, Markdown and Office documents (Word, Excel, PowerPoint and about 100 other formats) to PDF, and merges, splits, stamps, signs and converts PDFs. This template runs Gotenberg 9.9.1 with HTTP basic auth switched on and a generated password.

> Community template, not affiliated with the Gotenberg project.

## About Hosting Gotenberg

Gotenberg is a stateless Go server that drives Chromium (HTML, URL and Markdown to PDF) and LibreOffice (Office documents to PDF) inside one container. Your app sends a multipart form to a route such as `/forms/chromium/convert/html` and gets the PDF back in the response.

Upstream Gotenberg has no authentication by default, so a public instance converts documents for anyone and can be pointed at internal URLs. This template turns on Gotenberg's built-in basic auth with a generated password: every route except `/health` requires it. A small start script checks the variables first, so a mistyped value never crashes the deploy and an unusable password locks the API instead of opening it.

## Common Use Cases

- Generate invoices, receipts, reports and tickets from HTML templates in your backend
- Convert uploaded Word, Excel or PowerPoint files to PDF in a document workflow
- Render web pages or dashboards to PDF or screenshots on a schedule (n8n, Make, cron jobs)
- Merge, split, watermark, flatten forms or produce PDF/A files for archiving
- PDF backend for apps that support Gotenberg, such as Paperless-ngx

## Dependencies for Gotenberg Hosting

- Gotenberg service (repo build on the official `gotenberg/gotenberg:9.9.1` image, pinned by digest)
- No database, no volume: Gotenberg keeps nothing between requests

### Deployment Dependencies

- [Gotenberg documentation](https://gotenberg.dev/docs/getting-started/introduction)
- [Gotenberg on GitHub](https://github.com/gotenberg/gotenberg) (MIT license)
- [Gotenberg 8 to 9 upgrade guide](https://gotenberg.dev/docs/getting-started/upgrade)

### Implementation Details

| Service | Image | Purpose |
|---|---|---|
| Gotenberg | `gotenberg/gotenberg:9.9.1` + start script | Conversion API on port 3000, public HTTPS domain |

**First steps**

1. Open the Gotenberg service, Variables tab, and copy `GOTENBERG_API_BASIC_AUTH_USERNAME` (default `gotenberg`) and `GOTENBERG_API_BASIC_AUTH_PASSWORD`.
2. Check it works: `https://{your-domain}/health` answers without a password; `https://{your-domain}/version` asks for it.
3. Convert HTML to PDF:

```bash
curl -u gotenberg:{password} \
  -F files=@index.html \
  -o result.pdf \
  https://{your-domain}/forms/chromium/convert/html
```

4. Convert a Word file: `curl -u gotenberg:{password} -F files=@report.docx -o report.pdf https://{your-domain}/forms/libreoffice/convert`
5. Convert a web page: `curl -u gotenberg:{password} -F url=https://example.com -o page.pdf https://{your-domain}/forms/chromium/convert/url`

Services in the same Railway project can call `http://gotenberg.railway.internal:3000` over the private network (same credentials, no egress fees).

**Security defaults**

- Basic auth is on, with a 32-character generated password. A password that is empty, shorter than 16 or longer than 256 characters, or contains spaces locks the API with a random password and the log says how to fix it.
- `API_ENABLE_BASIC_AUTH=false` is accepted only while the service has no public domain (private-network use, e.g. for an app that cannot send credentials). With a public domain the setting is ignored and logged.
- The `/version` route and the version header are only visible to authenticated clients. `/health` stays public for Railway's healthcheck.
- Anyone with the credentials can make Chromium load URLs, including addresses on your Railway private network. Share the credentials only with trusted apps. Gotenberg's own `CHROMIUM_DENY_PRIVATE_IPS=true` and `API_DOWNLOAD_FROM_DENY_PRIVATE_IPS=true` block private addresses if you need that.

**Variables**

`API_TIMEOUT` (default 90s, upstream 30s) limits each conversion; raise it for large Office files. `API_BODY_LIMIT` caps upload size (e.g. `100MB`). `CHROMIUM_AUTO_START` and `LIBREOFFICE_AUTO_START` (default true) start both engines at boot so the first request is fast; set them to false to save idle RAM. Other Gotenberg flags can be set as variables with their upper-case names (for example `--chromium-max-memory` becomes `CHROMIUM_MAX_MEMORY`); see the Gotenberg docs.

**Resources and plans**

Measured on Railway: about 0.37 GB idle with both engines started (0.22 GB right after boot), with short spikes while converting. It fits the Trial plan (1 GB per service) for typical documents; large spreadsheets or long web pages need more. Set `CHROMIUM_AUTO_START=false` and `LIBREOFFICE_AUTO_START=false` on the Free plan (0.5 GB).

**Scaling and upgrades**

Gotenberg is stateless, so you can raise replicas in the service settings for parallel conversions; Railway spreads requests across them. To upgrade, change `GOTENBERG_IMAGE` (tag and digest) in `services/gotenberg/Dockerfile` of your fork.

Gotenberg 9 changed some routes and fields: `/forms/pdfengines/*` became `/forms/pdf/*`, and post-processing fields became a `stages` list. Clients written for Gotenberg 8 that only use the Chromium and LibreOffice convert routes usually keep working; for others, follow the upgrade guide or pin `gotenberg/gotenberg:8.40.0` in the Dockerfile.

### Why Deploy Gotenberg on Railway?

Railway gives Gotenberg an HTTPS endpoint, private networking to your other services, logs and replicas without managing servers or Chromium and LibreOffice installs. You pay only for the CPU and memory the conversions use.
