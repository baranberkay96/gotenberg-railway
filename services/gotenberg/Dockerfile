# syntax=docker/dockerfile:1
#
# Gotenberg 9.10.0 for Railway.
#
# The official image, unchanged, plus one start script (railway-start.sh) that
# checks the deploy-form values before Gotenberg reads them: Gotenberg exits on an
# empty basic-auth password or an invalid flag value, and an exit would fail the
# deploy. Invalid values fall back to safe defaults with a warning in the log; an
# unusable password locks the API with a random one instead of opening it.
#
# Pin (checked 2026-11-24 on Docker Hub): gotenberg/gotenberg:9.10.0 index digest,
# pushed 2026-11-24 (latest stable release, Gotenberg 9 line; fixes the 2026-11-22 advisories).
ARG GOTENBERG_IMAGE=gotenberg/gotenberg:9.10.0@sha256:2ce6fcd3f5019c82b0376065b9103d6d4938d34c1c06a39a8263a9fcf47a6f5b
FROM ${GOTENBERG_IMAGE}

COPY --chmod=0755 railway-start.sh /usr/local/bin/railway-start

# The image runs as the unprivileged "gotenberg" user; the script needs no root.
EXPOSE 3000
ENTRYPOINT ["/usr/bin/tini", "-s", "--", "/usr/local/bin/railway-start"]
CMD []
