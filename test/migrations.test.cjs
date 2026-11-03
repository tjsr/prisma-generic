const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const { mkdtempSync, mkdirSync, writeFileSync, rmSync } = require('node:fs');
const { tmpdir } = require('node:os');
const { join } = require('node:path');
const { DatabaseSync } = require('node:sqlite');
const { test } = require('node:test');
const lock = require('../package-lock.json');

// Run the same migration checks against a local install or the finished image.
test('the locked Prisma packages deploy repeatable migrations', () => {
  const directory = mkdtempSync(join(tmpdir(), 'prisma-generic-'));
  const image = process.env.PRISMA_TEST_IMAGE;
  const database = join(directory, 'test.db');
  const databaseUrl = `file:${image ? '/opt/migrator/prisma/test.db' : database}`;
  const prisma = (...args) => {
    const result = image
      ? spawnSync('docker', ['run', '--rm', '--network=none',
        '--mount', `type=bind,src=${directory},dst=/opt/migrator/prisma`,
        '-e', `DATABASE_URL=${databaseUrl}`, image, 'prisma', ...args], { encoding: 'utf8' })
      : spawnSync(process.execPath, [require.resolve('prisma/build/index.js'), ...args], {
        encoding: 'utf8', env: { ...process.env, DATABASE_URL: databaseUrl },
      });
    assert.ifError(result.error);
    assert.equal(result.status, 0, `${result.stdout}\n${result.stderr}`);
    return result.stdout;
  };
  try {
    const version = lock.packages['node_modules/prisma'].version;
    for (const name of ['@prisma/client', '@prisma/engines']) {
      assert.equal(lock.packages[`node_modules/${name}`].version, version);
    }
    const versions = prisma('--version');
    assert.match(versions, new RegExp(`^prisma\\s+: ${version.replaceAll('.', '\\.')}\\s*$`, 'm'));
    assert.match(versions, new RegExp(`^@prisma/client\\s+: ${version.replaceAll('.', '\\.')}\\s*$`, 'm'));
    writeFileSync(join(directory, 'schema.prisma'), `
datasource db {
  provider = "sqlite"
  url = env("DATABASE_URL")
}
model Smoke {
  id Int @id
  message String
}
`);
    mkdirSync(join(directory, 'migrations', '20260101000000_smoke'), { recursive: true });
    writeFileSync(join(directory, 'migrations', 'migration_lock.toml'), 'provider = "sqlite"\n');
    writeFileSync(join(directory, 'migrations', '20260101000000_smoke', 'migration.sql'),
      'CREATE TABLE "Smoke" ("id" INTEGER PRIMARY KEY, "message" TEXT NOT NULL);\n' +
      'INSERT INTO "Smoke" ("id", "message") VALUES (1, \'migrated\');\n');
    const schema = image ? '/opt/migrator/prisma/schema.prisma' : join(directory, 'schema.prisma');
    prisma('validate', '--schema', schema);
    prisma('migrate', 'deploy', '--schema', schema);
    prisma('migrate', 'deploy', '--schema', schema);
    prisma('migrate', 'status', '--schema', schema);
    const db = new DatabaseSync(database, { readOnly: true });
    try {
      assert.equal(db.prepare('SELECT message FROM Smoke WHERE id = 1').get().message, 'migrated');
      assert.equal(db.prepare('SELECT COUNT(*) AS count FROM _prisma_migrations WHERE finished_at IS NOT NULL').get().count, 1);
    } finally {
      db.close();
    }
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});
