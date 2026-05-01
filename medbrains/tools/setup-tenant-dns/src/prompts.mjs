/**
 * Tiny readline-based prompt helpers (zero deps). Mirrors the
 * pattern used by tools/create-mobile-app.
 */

import { createInterface } from "node:readline/promises";

const rl = () => createInterface({ input: process.stdin, output: process.stdout });

export async function ask(question, defaultValue) {
  const r = rl();
  try {
    const hint = defaultValue !== undefined && defaultValue !== "" ? ` (${defaultValue})` : "";
    const ans = (await r.question(`${question}${hint}: `)).trim();
    return ans || defaultValue || "";
  } finally {
    r.close();
  }
}

export async function askSecret(question) {
  const r = rl();
  try {
    process.stdout.write(`${question}: `);
    const ans = (await r.question("")).trim();
    return ans;
  } finally {
    r.close();
  }
}

export async function askChoice(question, choices, defaultIndex = 0) {
  console.log(`\n${question}`);
  choices.forEach((c, i) => {
    const marker = i === defaultIndex ? "*" : " ";
    console.log(`  ${marker} ${i + 1}) ${c.label}`);
  });
  const r = rl();
  try {
    const raw = (await r.question(`Choice [${defaultIndex + 1}]: `)).trim();
    const idx = raw === "" ? defaultIndex : Number.parseInt(raw, 10) - 1;
    if (Number.isNaN(idx) || idx < 0 || idx >= choices.length) {
      throw new Error(`invalid choice: ${raw}`);
    }
    return choices[idx].value;
  } finally {
    r.close();
  }
}

export async function askYesNo(question, defaultYes = false) {
  const r = rl();
  try {
    const hint = defaultYes ? "Y/n" : "y/N";
    const raw = (await r.question(`${question} (${hint}): `)).trim().toLowerCase();
    if (raw === "") return defaultYes;
    return raw === "y" || raw === "yes";
  } finally {
    r.close();
  }
}
