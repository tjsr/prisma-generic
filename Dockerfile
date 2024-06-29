ARG NODE_VERSION=20.15.0
ARG ALPINE_VERSION=3.20
ARG NPM_VERSION=10.8.1
FROM ghcr.io/tjsr/node_patched_npm:${NODE_VERSION}-alpine${ALPINE_VERSION}-npm${NPM_VERSION} AS prisma-build
ARG PRISMA_VERSION=5.16.1

LABEL org.opencontainers.image.title="prisma-generic"
LABEL org.opencontainers.image.description="Prisma CLI and Migrate"
LABEL org.opencontainers.image.source="https://github.com/tjsr/prisma-generic"
LABEL org.opencontainers.image.authors="Tim Rowe <tim@tjsr.id.au>"
LABEL org.opencontainers.image.documentation="https://github.com/tjsr/prisma-generic/blob/main/README.md"
LABEL org.opencontainers.image.base.name="ghcr.io/tjsr/node_patched_npm:${NODE_VERSION}-alpine${ALPINE_VERSION}-npm${NPM_VERSION}"

RUN --mount=type=cache,target=/root/.npm mkdir /opt/tagtool && \
  npm config set fund false --location=global && \
  npm config set update-notifier false --location=global

WORKDIR /opt/migrator
RUN --mount=type=cache,target=/root/.npm npm init --force && \
  npm install prisma@${PRISMA_VERSION} @prisma/client@${PRISMA_VERSION} @prisma/engines@${PRISMA_VERSION}

ENV PATH="${PATH}:/opt/migrator/node_modules/.bin"

# Then mount the prisma directory from the host to the container at /opt/migrator/prisma
# Alternatively, copy your prisma files directly with the COPY command below.
# COPY prisma /opt/migrator

