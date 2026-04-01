/**
 * session-repair.mjs
 * Reads a Claude Code session JSONL file, normalizes foreign-provider assistant
 * messages to Anthropic format, writes back atomically.
 *
 * CLI:
 *   node lib/session-repair.mjs <session-uuid>          # repair specific session
 *   node lib/session-repair.mjs --all                    # repair all tagged foreign sessions
 *   node lib/session-repair.mjs --check <session-uuid>   # dry-run, report issues
 */

import { readFileSync, writeFileSync, mkdirSync, renameSync, existsSync, readdirSync } from 'fs';
import { join, dirname } from 'path';
import { homedir } from 'os';
import { randomBytes } from 'crypto';

const HOME = homedir();
const CLAUDE_DIR = join(HOME, '.claude');
const PROJECTS_DIR = join(CLAUDE_DIR, 'projects');
const SESSION_PROVIDERS_PATH = join(CLAUDE_DIR, 'session_providers.json');
const SESSION_BACKUPS_DIR = join(CLAUDE_DIR, 'session_backups');

// ---------------------------------------------------------------------------
// ID generation
// ---------------------------------------------------------------------------

function generateMsgId() {
  const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const bytes = randomBytes(24);
  let result = '';
  for (let i = 0; i < 24; i++) {
    result += charset[bytes[i] % charset.length];
  }
  return 'msg_01' + result;
}

function sanitizeToolId(id) {
  let sanitized = id.replace(/[^a-zA-Z0-9_-]/g, '_');
  if (!sanitized.startsWith('toolu_')) sanitized = 'toolu_' + sanitized;
  return sanitized;
}

function generateToolId(originalId) {
  return sanitizeToolId(originalId);
}

// ---------------------------------------------------------------------------
// Field normalizers
// ---------------------------------------------------------------------------

function normalizeUsage(usage) {
  if (!usage) return { input_tokens: 0, output_tokens: 0, cache_creation_input_tokens: 0, cache_read_input_tokens: 0 };
  const normalized = { ...usage };

  // OpenAI → Anthropic field names
  if ('prompt_tokens' in normalized && !('input_tokens' in normalized)) {
    normalized.input_tokens = normalized.prompt_tokens;
    delete normalized.prompt_tokens;
  }
  if ('completion_tokens' in normalized && !('output_tokens' in normalized)) {
    normalized.output_tokens = normalized.completion_tokens;
    delete normalized.completion_tokens;
  }
  if ('total_tokens' in normalized) {
    delete normalized.total_tokens;
  }

  // Add missing cache fields
  if (!('cache_creation_input_tokens' in normalized)) {
    normalized.cache_creation_input_tokens = 0;
  }
  if (!('cache_read_input_tokens' in normalized)) {
    normalized.cache_read_input_tokens = 0;
  }

  return normalized;
}

function normalizeStopReason(reason) {
  const VALID_ANTHROPIC = new Set(['end_turn', 'max_tokens', 'stop_sequence', 'tool_use']);
  if (VALID_ANTHROPIC.has(reason)) return reason;

  const map = {
    stop: 'end_turn',
    length: 'max_tokens',
    tool_calls: 'tool_use',
  };
  return map[reason] ?? reason;
}

function sortContentBlocks(blocks) {
  if (!Array.isArray(blocks)) return blocks;
  const ORDER = { thinking: 0, text: 1, tool_use: 2 };
  return [...blocks].sort((a, b) => {
    const oa = ORDER[a.type] ?? 99;
    const ob = ORDER[b.type] ?? 99;
    return oa - ob;
  });
}

// ---------------------------------------------------------------------------
// Message normalizers
// ---------------------------------------------------------------------------

function normalizeAssistantMessage(message, idRemapTable) {
  const issues = [];
  const msg = { ...message };

  // Normalize model
  if (msg.model && !msg.model.startsWith('claude-')) {
    issues.push(`model: "${msg.model}" → "claude-sonnet-4-5-20250514"`);
    msg.model = 'claude-sonnet-4-5-20250514';
  }

  // Normalize message ID
  if (msg.id && !msg.id.startsWith('msg_')) {
    const newId = generateMsgId();
    issues.push(`id: "${msg.id}" → "${newId}"`);
    msg.id = newId;
  }

  // Normalize stop_reason
  if (msg.stop_reason) {
    const normalized = normalizeStopReason(msg.stop_reason);
    if (normalized !== msg.stop_reason) {
      issues.push(`stop_reason: "${msg.stop_reason}" → "${normalized}"`);
      msg.stop_reason = normalized;
    }
  }

  // Normalize usage
  if (msg.usage) {
    const normalizedUsage = normalizeUsage(msg.usage);
    const usageChanged = JSON.stringify(normalizedUsage) !== JSON.stringify(msg.usage);
    if (usageChanged) {
      issues.push('usage: normalized field names and added cache fields');
      msg.usage = normalizedUsage;
    }
  } else {
    msg.usage = normalizeUsage(null);
    issues.push('usage: added missing usage block');
  }

  // Normalize content blocks
  if (Array.isArray(msg.content)) {
    msg.content = msg.content.map((block) => {
      const b = { ...block };

      if (b.type === 'tool_use' && b.id) {
        if (!b.id.startsWith('toolu_')) {
          const newToolId = generateToolId(b.id);
          idRemapTable[b.id] = newToolId;
          issues.push(`tool_use id: "${b.id}" → "${newToolId}"`);
          b.id = newToolId;
        }
      }

      if (b.type === 'thinking') {
        if (!('signature' in b) || (b.signature !== null && typeof b.signature !== 'string')) {
          issues.push(`thinking block: set missing/invalid signature to null`);
          b.signature = null;
        }
      }

      return b;
    });

    // Sort: thinking → text → tool_use
    msg.content = sortContentBlocks(msg.content);
  }

  return { message: msg, issues };
}

function normalizeUserMessage(record, idRemapTable) {
  if (!record.message || !Array.isArray(record.message.content)) return record;
  if (Object.keys(idRemapTable).length === 0) return record;

  const rec = { ...record, message: { ...record.message } };
  rec.message.content = record.message.content.map((block) => {
    if (block.type === 'tool_result' && block.tool_use_id && idRemapTable[block.tool_use_id]) {
      return { ...block, tool_use_id: idRemapTable[block.tool_use_id] };
    }
    return block;
  });
  return rec;
}

// ---------------------------------------------------------------------------
// File discovery
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Core repair logic
// ---------------------------------------------------------------------------

function repairSession(uuid, dryRun = false) {
  const sessionPath = findSessionFile(uuid);
  if (!sessionPath) {
    return { changed: false, issues: [`Session file not found for UUID: ${uuid}`] };
  }

  const raw = readFileSync(sessionPath, 'utf8');
  const lines = raw.split('\n');
  const idRemapTable = {};
  const allIssues = [];
  let changed = false;

  const repairedLines = lines.map((line, lineNum) => {
    if (!line.trim()) return line;

    let record;
    try {
      record = JSON.parse(line);
    } catch {
      allIssues.push(`Line ${lineNum + 1}: invalid JSON, skipping`);
      return line;
    }

    if (record.type === 'assistant' && record.message) {
      const { message: normalizedMsg, issues } = normalizeAssistantMessage(record.message, idRemapTable);
      if (issues.length > 0) {
        allIssues.push(...issues.map((i) => `Line ${lineNum + 1}: ${i}`));
        changed = true;
        return JSON.stringify({ ...record, message: normalizedMsg });
      }
    } else if (record.type === 'user' && record.message) {
      const normalizedRecord = normalizeUserMessage(record, idRemapTable);
      if (JSON.stringify(normalizedRecord) !== JSON.stringify(record)) {
        allIssues.push(`Line ${lineNum + 1}: fixed tool_result.tool_use_id references`);
        changed = true;
        return JSON.stringify(normalizedRecord);
      }
    }

    return line;
  });

  if (!dryRun && changed) {
    // Backup original
    mkdirSync(SESSION_BACKUPS_DIR, { recursive: true });
    const backupPath = join(SESSION_BACKUPS_DIR, `${uuid}.jsonl.bak`);
    writeFileSync(backupPath, raw, 'utf8');

    // Atomic write
    const tmpPath = sessionPath + '.tmp';
    writeFileSync(tmpPath, repairedLines.join('\n'), 'utf8');
    renameSync(tmpPath, sessionPath);

    console.log(`Repaired session ${uuid} (${allIssues.length} fix(es)). Backup: ${backupPath}`);
  } else if (dryRun) {
    console.log(`[DRY RUN] Session ${uuid}: ${changed ? allIssues.length + ' issue(s) found' : 'no issues found'}`);
    allIssues.forEach((i) => console.log('  ' + i));
  } else {
    console.log(`Session ${uuid}: no repairs needed`);
  }

  return { changed, issues: allIssues };
}

function getAllForeignSessions() {
  if (!existsSync(SESSION_PROVIDERS_PATH)) return [];
  try {
    const data = JSON.parse(readFileSync(SESSION_PROVIDERS_PATH, 'utf8'));
    return Object.entries(data)
      .filter(([, tag]) => tag.provider && tag.provider !== 'anthropic')
      .map(([uuid]) => uuid);
  } catch {
    return [];
  }
}

// ---------------------------------------------------------------------------
// CLI handler — only runs when this file is the entry point, not when imported
// ---------------------------------------------------------------------------

import { fileURLToPath } from 'url';
const __filename_repair = fileURLToPath(import.meta.url);
const _isMain = process.argv[1] && (
  process.argv[1] === __filename_repair ||
  process.argv[1].endsWith('/session-repair.mjs')
);

if (_isMain) {
  const args = process.argv.slice(2);

  if (args[0] === '--all') {
    const sessions = getAllForeignSessions();
    if (sessions.length === 0) {
      console.log('No foreign-provider sessions found to repair.');
    } else {
      console.log(`Repairing ${sessions.length} foreign session(s)...`);
      for (const uuid of sessions) {
        repairSession(uuid, false);
      }
    }
  } else if (args[0] === '--check') {
    const uuid = args[1];
    if (!uuid) {
      console.error('Usage: node session-repair.mjs --check <session-uuid>');
      process.exit(1);
    }
    repairSession(uuid, true);
  } else if (args[0]) {
    repairSession(args[0], false);
  } else {
    console.error('Usage:');
    console.error('  node session-repair.mjs <session-uuid>');
    console.error('  node session-repair.mjs --all');
    console.error('  node session-repair.mjs --check <session-uuid>');
    process.exit(1);
  }
}

export {
  generateMsgId,
  generateToolId,
  sanitizeToolId,
  normalizeUsage,
  normalizeStopReason,
  normalizeAssistantMessage,
  normalizeUserMessage,
  findSessionFile,
  repairSession,
  getAllForeignSessions,
};
