# syntax=docker/dockerfile:1
ARG NODE_VERSION=24.22.2
ARG ALPINE_VERSION=3.23
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} AS prisma-base
ARG NPM_VERSION=12.2.1

# The optional CA is used only by managed build environments with an HTTPS proxy.
RUN --mount=type=secret,id=proxy_ca \
    --mount=type=cache,target=/root/.npm \
    if [ -f /run/secrets/proxy_ca ]; then export NODE_EXTRA_CA_CERTS=/run/secrets/proxy_ca; fi; \
    set -eu; \
    npm install --global "npm@${NPM_VERSION}"

FROM prisma-base AS prisma-build
WORKDIR /opt/migrator
COPY package.json package-lock.json ./
RUN --mount=type=secret,id=proxy_ca \
    --mount=type=cache,target=/root/.npm \
    if [ -f /run/secrets/proxy_ca ]; then export NODE_EXTRA_CA_CERTS=/run/secrets/proxy_ca; fi; \
    npm ci --include=dev --no-audit --no-fund

FROM prisma-base AS prisma-migrate
ARG NODE_VERSION
ARG ALPINE_VERSION

LABEL org.opencontainers.image.title="prisma-generic"
LABEL org.opencontainers.image.description="Prisma CLI and Migrate"
LABEL org.opencontainers.image.source="https://github.com/tjsr/prisma-generic"
LABEL org.opencontainers.image.authors="Tim Rowe <tim@tjsr.id.au>"
LABEL org.opencontainers.image.documentation="https://github.com/tjsr/prisma-generic/blob/main/README.md"
LABEL org.opencontainers.image.base.name="node:${NODE_VERSION}-alpine${ALPINE_VERSION}"

WORKDIR /opt/migrator
COPY --from=prisma-build /opt/migrator/node_modules ./node_modules
ENV PATH="${PATH}:/opt/migrator/node_modules/.bin"

# Mount the schema and migrations at /opt/migrator/prisma.
CMD ["prisma", "migrate", "deploy"]
