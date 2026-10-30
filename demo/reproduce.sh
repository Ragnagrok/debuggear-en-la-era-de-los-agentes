#!/usr/bin/env bash
# Rule 2, make it fail: the bug report, as a yes-or-no question a machine can
# ask a thousand times. Run it from the project's directory.
#
# Report: "a customer typed their code in lowercase and the till said it doesn't exist".
# Exit 0: it works. Exit 1: it fails. Either way, it prints what it saw.
set -uo pipefail
node --input-type=module -e '
import { findCard } from "./src/codes.js";
const cards = [{ code: "ABC-123", balance: 5000 }];
const found = findCard(cards, " abc-123 ");
console.log(`typed " abc-123 ", found: ${JSON.stringify(found ?? null)}`);
process.exit(found ? 0 : 1);
'
