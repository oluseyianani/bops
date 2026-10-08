import "server-only";
import { chmodSync, existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";

/**
 * Fork-local (see FORK.md): secrets on a Linux server, where there is no macOS Keychain. The same
 * three calls as lib/server/keychain.ts, kept in .data/secrets.json (mode 0600, next to state.json).
 * keychain.ts hands over to this when the server isn't running on a Mac.
 */
const FILE = join(process.cwd(), ".data", "secrets.json");

function readAll(): Record<string, string> {
  if (!existsSync(FILE)) return {};
  try {
    return JSON.parse(readFileSync(FILE, "utf8")) as Record<string, string>;
  } catch {
    return {};
  }
}

function writeAll(all: Record<string, string>) {
  mkdirSync(dirname(FILE), { recursive: true, mode: 0o700 });
  const tmp = `${FILE}.${process.pid}.tmp`;
  writeFileSync(tmp, JSON.stringify(all, null, 2), { mode: 0o600 });
  renameSync(tmp, FILE);
  chmodSync(FILE, 0o600);
}

export const fileSecrets = {
  async set(account: string, value: string) {
    writeAll({ ...readAll(), [account]: value });
  },
  async get(account: string): Promise<string | null> {
    return readAll()[account] ?? null;
  },
  async delete(account: string) {
    const all = readAll();
    if (!(account in all)) return;
    delete all[account];
    writeAll(all);
  },
};
