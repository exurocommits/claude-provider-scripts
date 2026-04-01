/**
 * session-guard.mjs
 * Provider detection + auto-repair trigger.
 * Called before `claude --resume <uuid>`.
 * Exits 0 on success (proceed), non-zero on failure.
 *
 * CLI: node lib/session-guard.mjs <session-uuid>
 */

import { readFileSync, existsSync, readdirSync } from 'fs';
import { join, dirname } from 'path';
import { homedir } from 'os';
import { fileURLToPath } from 'url';
import { spawn } from 'child_process';

const HOME = homedir();
const CLAUDE_DIR = join(HOME, '.claude');
const PROJECTS_DIR = join(CLAUDE_DIR, 'projects');
const SESSION_PROVIDERS_PATH = join(CLAUDE_DIR, 'session_providers.json');

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function readProviderTags() {
  if (!existsSync(SESSION_PROVIDERS_PATH)) return {};
  try {
    return JSON.parse(readFileSync(SESSION_PROVIDERS_PATH, 'utf8'));
  } catch {
    return {};
  }
}

function isForeignSession(uuid, tags) {
  if (!tags[uuid]) return false;
  return tags[uuid].provider !== 'anthropic';
}

function findSessionFile(uuid) {
  if (!existsSync(PROJECTS_DIR)) return null;
  const projectDirs = readdirSync(PROJECTS_DIR, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => join(PROJECTS_DIR, d.name));
  for (const projectDir of projectDirs) {
    const sessionsDir = join(projectDir, 'sessions');
    if (!existsSync(sessionsDir)) continue;
    const candidate = join(sessionsDir, `${uuid}.jsonl`);
    if (existsSync(candidate)) return candidate;
  }
  return null;
}

function scanSessionForForeignModels(sessionPath) {
  try {
    const raw = readFileSync(sessionPath, 'utf8');
    const lines = raw.split('\n');
    for (const line of lines) {
      if (!line.trim()) continue;
      let record;
      try {
        record = JSON.parse(line);
      } catch {
        continue;
      }
      if (record.type === 'assistant' && record.message && record.message.model) {
        if (!record.message.model.startsWith('claude-')) {
          return true;
        }
      }
    }
    return false;
  } catch {
    return false;
  }
}

function runRepair(uuid) {
  return new Promise((resolve, reject) => {
    const repairPath = join(__dirname, 'session-repair.mjs');
    const child = spawn(process.execPath, ['--input-type=module', repairPath, uuid], {
      stdio: 'inherit',
    });
    // Fallback: try direct spawn with node
    const child2 = spawn('node', [repairPath, uuid], {
      stdio: 'inherit',
    });
    child2.on('close', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`session-repair.mjs exited with code ${code}`));
      }
    });
    child2.on('error', (err) => {
      reject(err);
    });
    // Kill the first child if second starts
    child.kill();
  });
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function getAllForeignUuids() {
  const tags = readProviderTags();
  return Object.entries(tags)
    .filter(([, tag]) => tag.provider && tag.provider !== 'anthropic')
    .map(([uuid]) => uuid);
}

async function repairOne(uuid) {
  const tags = readProviderTags();
  let isForeign = isForeignSession(uuid, tags);

  if (!isForeign) {
    const sessionPath = findSessionFile(uuid);
    if (sessionPath) {
      isForeign = scanSessionForForeignModels(sessionPath);
      if (isForeign) {
        console.log(`Session ${uuid}: foreign model detected via JSONL scan, repairing...`);
      }
    }
  } else {
    console.log(`Session ${uuid}: tagged as foreign provider (${tags[uuid].provider}), repairing...`);
  }

  if (isForeign) {
    await runRepair(uuid);
    console.log(`Session ${uuid}: repair complete.`);
    return true;
  }
  return false;
}

async function main() {
  const uuid = process.argv[2];

  // No UUID — repair ALL tagged foreign sessions (for interactive -r mode)
  if (!uuid || uuid === '--all') {
    const foreignUuids = getAllForeignUuids();
    if (foreignUuids.length === 0) {
      process.exit(0);
    }
    console.log(`Repairing ${foreignUuids.length} foreign-provider session(s)...`);
    let failed = 0;
    for (const id of foreignUuids) {
      try {
        await repairOne(id);
      } catch (err) {
        console.error(`Session ${id}: repair failed — ${err.message}`);
        failed++;
      }
    }
    process.exit(failed > 0 ? 1 : 0);
  }

  // Specific UUID
  try {
    const repaired = await repairOne(uuid);
    if (!repaired) console.log(`Session ${uuid}: OK, no repair needed.`);
    process.exit(0);
  } catch (err) {
    console.error(`Session ${uuid}: repair failed — ${err.message}`);
    process.exit(1);
  }
}

main();
