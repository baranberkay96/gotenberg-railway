# NOTICE: Gotenberg 9.9 PDF Conversion API template

**This template runs Gotenberg (gotenberg/gotenberg).** Gotenberg is © Julien Neuhart and contributors, licensed under the MIT License. This is a community template; it is not affiliated with or endorsed by the Gotenberg project or Railway.

## Components

| Component | Source | License | How it is used |
|---|---|---|---|
| Gotenberg 9.9.1 | https://github.com/gotenberg/gotenberg, image `gotenberg/gotenberg:9.9.1@sha256:0fc05327fcc4af8ba84bb99b3da35fe728840d98cef9d3bf0d701bd077834eb5` | MIT | Base image, unmodified |
| Chromium, LibreOffice, fonts and other packages inside the image | Debian packages and upstream builds bundled by the Gotenberg image | Each package's own license (BSD-3-Clause for Chromium, MPL-2.0 for LibreOffice, various for fonts) | Run by Gotenberg inside the container |
| Gotenberg logo (marketplace icon) | https://github.com/gotenberg/art, commit `10017bee591595ad27a1b31ce1958400ad0b519a`, `logo.png` | as published by the Gotenberg project | Icon only, unmodified, refers to the project |

The Gotenberg MIT license requires keeping its copyright notice; the image ships it, and it is reproduced here: "Copyright (c) Julien Neuhart" — see https://github.com/gotenberg/gotenberg/blob/main/LICENSE for the full text.

## Files written for this template

`services/gotenberg/Dockerfile` and `services/gotenberg/railway-start.sh` were written for this template (no upstream file copied). The start script validates the template variables and starts the unchanged `gotenberg` binary with `--api-port-from-env=PORT`. They are offered under the MIT License.

## Upstream files checked

At tag `v9.9.1` (2026-11-20): `build/Dockerfile` (user `gotenberg`, tini entrypoint, port 3000), `pkg/modules/api/api.go` (basic-auth flag and `GOTENBERG_API_BASIC_AUTH_*` variables, which routes the auth covers, `/health` stays public), `pkg/modules/api/middlewares.go`, `pkg/gotenberg/env.go` and `pkg/gotenberg/flags.go` (every flag can be overridden by its upper-case environment variable; an invalid value or an empty basic-auth variable stops the process), `pkg/modules/chromium/chromium.go` and `pkg/modules/libreoffice/api/api.go` (auto-start and deny-list flags), release notes of v9.0.0.

## Market templates reviewed

`gotenberg` (171 active projects), `gotenberg-secured` (34) and `gotenberg-1` (16), read on 2026-11-20. All use the floating `gotenberg/gotenberg:8` tag. The most used one has no authentication; `gotenberg-1` defines the basic-auth variables but never enables auth; `gotenberg-secured` enables it with empty username/password inputs (Gotenberg exits at start if they stay empty). Nothing was copied from them.
