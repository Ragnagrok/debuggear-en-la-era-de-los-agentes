import { test } from "node:test";
import assert from "node:assert/strict";
import { findCard } from "../src/codes.js";

// The reproduction from demo/reproduce.sh, kept as a test so the bug can't come back.
test("finds a card typed in lowercase with spaces around", () => {
  const cards = [{ code: "ABC-123", balance: 5000 }];
  assert.equal(findCard(cards, " abc-123 ")?.code, "ABC-123");
});
