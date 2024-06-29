ARG NODE_VERSION=20.15.0
ARG ALPINE_VERSION=3.20
ARG NPM_VERSION=10.8.1
FROM ghcr.io/tjsr/node_patched_npm:${NODE_VERSION}-alpine${ALPINE_VERSION}-npm${NPM_VERSION} as prisma-build
ARG PRISMA_VERSION=5.16.1

WORKDIR /opt/migrator
RUN npm init --force && \
  npm install prisma@${PRISMA_VERSION} @prisma/client@${PRISMA_VERSION} @prisma/engines@${PRISMA_VERSION}

ENV PATH="${PATH}:/opt/migrator/node_modules/.bin"

# Then mount the prisma directory from the host to the container at /opt/migrator/prisma
#COPY prisma /opt/migrator


