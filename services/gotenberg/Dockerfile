# syntax=docker/dockerfile:1
#
# Gotenberg 9.9.1 for Railway.
#
# The official image, unchanged, plus one start script (railway-start.sh) that
# checks the deploy-form values before Gotenberg reads them: Gotenberg exits on an
# empty basic-auth password or an invalid flag value, and an exit would fail the
# deploy. Invalid values fall back to safe defaults with a warning in the log; an
# unusable password locks the API with a random one instead of opening it.
#
# Pin (checked 2026-11-20 on Docker Hub): gotenberg/gotenberg:9.9.1 index digest,
# pushed 2026-11-20 (latest stable release, Gotenberg 9 line).
ARG GOTENBERG_IMAGE=gotenberg/gotenberg:9.9.1@sha256:0fc05327fcc4af8ba84bb99b3da35fe728840d98cef9d3bf0d701bd077834eb5
FROM ${GOTENBERG_IMAGE}

COPY --chmod=0755 railway-start.sh /usr/local/bin/railway-start

# The image runs as the unprivileged "gotenberg" user; the script needs no root.
EXPOSE 3000
ENTRYPOINT ["/usr/bin/tini", "-s", "--", "/usr/local/bin/railway-start"]
CMD []
