# prisma-generic

This is a generic alpine Docker image for running prisma migrations within a container.  You can either run it on a local docker host, or you could use AWS Lambda or ECS to invoke running the container and have it handle your migration.  Simply pull this image from public.ecr.aws/tjsrowe/prisma-generic:latest (coming soon: version tags) and mount your 'prisma' dir containing the prisma.schema file and migrations.  Ensure that the environment you're running has the value you've defined as your database URL in your schema file (eg, `env("PRISMA_DATABASE_URL")`), preferably as a secret. Then invoke the command such as `prisma migrate dev`.  So long as the permission set is correct, and the running container has both network and SQL server permission, your migration will run as it would from any other host.

## About this container image

The container image is built on a recent node alpine image with an updated npm.  While I looked at using debian distroless, it turned out theat node-alpine was actually 40MB smaller after having node/npm/prisma installed!

## Building

If you want to build this container image locally, just use `docker build -t prisma-generic .`

It takes a few values, which are passed to the base image.

```docker
ARG NODE_VERSION=20.12.2
ARG ALPINE_VERSION=3.19
ARG NPM_VERSION=10.5.2
FROM ghcr.io/tjsr/node_patched_npm:${NODE_VERSION}-alpine${ALPINE_VERSION}-npm${NPM_VERSION} as prisma-build
ARG PRISMA_VERSION=5.12.1
```

From time-to-time I'll update the base container images available.  See https://github.com/tjsr/node_patched_npm for the qavailable releases.  These are the base images I use for the majority of my containerised builds and deployments.