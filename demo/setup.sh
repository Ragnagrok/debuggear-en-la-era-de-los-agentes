#!/usr/bin/env bash
# Builds the demo project: a small gift card library with a real git history of
# twelve small commits. Somewhere after the tag v0.1, a commit that only
# claimed to tidy the code also changed what it does.
#
# Usage: demo/setup.sh <empty-or-new-directory>
set -euo pipefail
dir=$1
mkdir -p "$dir"
cd "$dir"
git init -q -b main
git config user.name "Demo"
git config user.email "demo@example.com"
mkdir -p src test

commit() { git add -A; git commit -q -m "$1"; }

cat > package.json <<'JSON'
{ "name": "gift-codes", "version": "0.1.0", "type": "module", "private": true }
JSON
cat > src/codes.js <<'JS'
export function findCard(cards, typed) {
  return cards.find((card) => card.code === typed);
}
JS
commit "Add code lookup"

cat > src/codes.js <<'JS'
export function findCard(cards, typed) {
  return cards.find((card) => card.code === typed.toUpperCase());
}
JS
commit "Accept codes typed in lowercase"

cat >> src/codes.js <<'JS'

export function formatBalance(cents) {
  return `$${(cents / 100).toFixed(2)}`;
}
JS
commit "Add balance formatting"

cat > test/format.test.js <<'JS'
import { test } from "node:test";
import assert from "node:assert/strict";
import { formatBalance } from "../src/codes.js";

test("formats cents as dollars", () => {
  assert.equal(formatBalance(1050), "$10.50");
});
JS
commit "Add tests for formatting"

sed -i 's/typed.toUpperCase()/typed.trim().toUpperCase()/' src/codes.js
commit "Trim spaces around typed codes"
git tag v0.1

cat >> src/codes.js <<'JS'

export function redeem(card, cents) {
  if (cents > card.balance) throw new Error("insufficient balance");
  return { ...card, balance: card.balance - cents };
}
JS
commit "Add redeem()"

# The culprit: a tidy-up that also changes behaviour. The extracted function
# trims, but no longer upper-cases.
cat > src/codes.js <<'JS'
export function normalizeCode(typed) {
  return typed.trim();
}

export function findCard(cards, typed) {
  return cards.find((card) => card.code === normalizeCode(typed));
}

export function formatBalance(cents) {
  return `$${(cents / 100).toFixed(2)}`;
}

export function redeem(card, cents) {
  if (cents > card.balance) throw new Error("insufficient balance");
  return { ...card, balance: card.balance - cents };
}
JS
commit "tidy: extract normalizeCode()"

cat >> src/codes.js <<'JS'

export function isExpired(card, today) {
  return card.expiresOn < today;
}
JS
commit "Add expiry check"

cat > README.md <<'MD'
# gift-codes

Look up gift cards by the code a customer types, format balances, redeem.
MD
commit "Add README"

cat > test/redeem.test.js <<'JS'
import { test } from "node:test";
import assert from "node:assert/strict";
import { redeem } from "../src/codes.js";

test("redeem lowers the balance", () => {
  assert.equal(redeem({ code: "A", balance: 500 }, 200).balance, 300);
});
JS
commit "Add tests for redeem"

cat >> src/codes.js <<'JS'

export function history(redemptions, code) {
  return redemptions.filter((r) => r.code === code);
}
JS
commit "Add redemption history"

sed -i 's/"version": "0.1.0"/"version": "0.2.0"/' package.json
commit "Release 0.2.0"
