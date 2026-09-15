import { readFileSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

const DOMAIN_ROOT = dirname(fileURLToPath(import.meta.url));
const PACKAGE_ROOT = join(DOMAIN_ROOT, "..");

const FORBIDDEN = /\bfrom\s+['"][^'"]*(manifold|three|godot)[^'"]*['"]/;

function listTsFiles(dir: string): string[] {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) {
      return listTsFiles(path);
    }
    return entry.name.endsWith(".ts") && !entry.name.endsWith(".test.ts")
      ? [path]
      : [];
  });
}

describe("domain-floorplan import ban (NFR-015 / I2)", () => {
  it("does not import manifold, three, or godot", () => {
    const files = listTsFiles(join(PACKAGE_ROOT, "src"));
    expect(files.length).toBeGreaterThan(0);
    for (const file of files) {
      const source = readFileSync(file, "utf8");
      expect(source, file).not.toMatch(FORBIDDEN);
    }
  });
});
