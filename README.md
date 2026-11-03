# prisma-generic

This is a generic alpine Docker image for running prisma migrations within a container.  You can either run it on a local docker host, or you could use AWS Lambda or ECS to invoke running the container and have it handle your migration.

Simply pull this image from public.ecr.aws/tjsrowe/prisma-generic:latest and mount your 'prisma' dir containing the prisma.schema file and migrations.  You can fin this image at [https://gallery.ecr.aws/tjsrowe/prisma-generic](https://gallery.ecr.aws/tjsrowe/prisma-generic)

Ensure that the environment you're running has the value you've defined as your database URL in your schema file (eg, `env("PRISMA_DATABASE_URL")`), preferably as a secret. Then invoke the command such as `prisma migrate dev`.  So long as the permission set is correct, and the running container has both network and SQL server permission, your migration will run as it would from any other host.

The default command this container will run is the migrate process, `prisma migrate deploy`.

## About this container image

The container image is built on a recent node alpine image with an updated npm, and installs the locked Prisma CLI, client and engines.  While I looked at using debian distroless, it turned out theat node-alpine was actually 40MB smaller after having node/npm/prisma installed!

## Building

If you want to build this container image locally, just use `docker build -t prisma-generic .`

The image installs dependencies with `npm ci` from `package-lock.json`. The Prisma
version in the image and the published version tag both come from that lockfile;
there is no separate `PRISMA_VERSION` build argument to keep in sync.

Both build and runtime stages share the official Node Alpine base. Defaults are
Node 24.22.2, Alpine 3.23 and npm 12.2.1. You can override `NODE_VERSION`,
`ALPINE_VERSION` and `NPM_VERSION` with Docker build arguments. CI also verifies
Node 22.23.4 with npm 12.2.1.

Run `npm ci && npm test` to check the local install. After building an image, run
`PRISMA_TEST_IMAGE=prisma-generic npm test` to verify its installed Prisma version
and deploy a temporary SQLite migration with container networking disabled.
These tests create no external databases.

Pull requests, branch pushes and manual workflow runs build and test without
logging into a registry or pushing images. Only successful pushes to `main`
publish the verified Node 24 image to ECR Public, tagged with the commit SHA and
the locked Prisma version.
