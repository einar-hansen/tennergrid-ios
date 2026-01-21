# Tenner Grid Solving Strategy

A systematic approach to solving Tenner Grid puzzles efficiently and consistently.

---

## What is a Tenner Grid?

A Tenner Grid is a logic puzzle consisting of a rectangular grid (typically 10 columns wide) where:

- Each row must contain the digits 0–9 exactly once
- Adjacent cells (including diagonals) cannot contain the same digit
- Column sums are provided at the bottom and must be satisfied

---

## Phase 1: Setup & Easy Wins

Begin by establishing the foundational information that will guide all subsequent decisions.

### Step 1: Calculate Column Deficits

For each column, subtract all known values from the target sum at the bottom. Write the "remaining sum needed" in a working area below the puzzle. This immediately tells you how much value the empty cells must contribute.

### Step 2: List Row Candidates

For each row, identify which digits from 0–9 are still missing. Write these candidates on the right side of the grid. This serves as your master reference for what can legally be placed.

### Step 3: Claim the Freebies

Fill any cell where only one digit is possible:

- A column with a single empty cell (the remaining sum determines the digit)
- A cell where only one candidate from the row satisfies the column sum
- A cell where adjacency rules eliminate all candidates except one

---

## Phase 2: Constraint Propagation

This phase leverages the interaction between different rule sets to narrow possibilities dramatically.

### Step 4: Adjacency Elimination

For each empty cell, eliminate any digit that appears in the eight surrounding cells (left, right, and the six diagonal/vertical neighbors). This constraint is often more restrictive than sum constraints and should be applied rigorously.

### Step 5: Intersection Logic

A valid candidate for any cell must satisfy both constraints simultaneously:

- The digit must be missing from its row
- The digit must be feasible for its column's remaining sum

Compute the intersection of these two sets. The resulting candidate list is often surprisingly small—sometimes just one or two digits.

---

## Phase 3: Strategic Column Analysis

When easy wins are exhausted, shift to systematic column-by-column analysis.

### Step 6: Prioritize Columns Intelligently

Select which column to analyze based on multiple factors:

1. **Fewest empty cells** — Fewer cells means fewer combinations to consider
2. **Extreme target sums** — Columns needing very low (0–5) or very high (30+) sums have fewer valid digit combinations
3. **Heavy adjacency constraints** — Columns where surrounding filled cells have already eliminated most options

### Step 7: Sum Decomposition

For a column missing *n* cells that needs a remaining sum of *S*:

1. List all subsets of row-available digits that sum to exactly *S*
2. Filter these subsets by adjacency constraints
3. Often only one or two valid combinations remain

This technique transforms guesswork into systematic enumeration.

---

## Phase 4: Chain Reactions

Each placement creates new constraints. Exploit them immediately.

### Step 8: Propagate Every Placement

After filling any cell, immediately re-evaluate:

- **All adjacent cells** — New adjacency eliminations may apply
- **The entire row** — One fewer candidate remains for other cells
- **The entire column** — The remaining sum has changed

This propagation often triggers a cascade of forced placements, especially in the late game.

---

## Advanced Techniques

### Anchor Digits: 0 and 9

The extreme values 0 and 9 are strategic anchors. Placing them early provides maximum information:

- **0** contributes nothing to column sums, heavily constraining where remaining digits can go
- **9** contributes maximally, often determining whether other cells need high or low values

Prioritize resolving cells that might contain these digits.

### Forced Pairs (Naked Pairs)

If two cells in the same column can only contain the same two digits (e.g., both restricted to {3, 7}), then:

- Those two digits are "locked" to those two cells
- Eliminate both digits as candidates from all other cells in that column

This technique can break open stalled puzzles.

### Work Top-Down Within Columns

Upper cells in a column affect the adjacency constraints of more cells below them. When choosing which cell to resolve first within a column, prefer higher cells to maximize the constraint propagation downward.

### Parity and Sum Reasoning

For columns with two empty cells needing sum *S*:

- If *S* is odd, the two digits must have opposite parity (one odd, one even)
- If *S* is even, both digits share the same parity

This simple observation can halve your candidate combinations instantly.

---

## Recommended Workflow

1. **Initial scan** — Fill all obvious cells (single candidates, forced by sum or adjacency)
2. **Build candidate lists** — For remaining cells, write small candidate digits in corners
3. **Iterate constraint propagation** — Apply adjacency and sum filtering until no more eliminations occur
4. **Target the most constrained column** — Enumerate valid combinations and test
5. **Propagate and repeat** — After each placement, return to step 1

---

## Common Mistakes to Avoid

- **Forgetting diagonal adjacency** — All eight neighbors matter, not just horizontal
- **Not updating candidate lists** — Stale lists lead to invalid placements
- **Ignoring row uniqueness** — Each digit 0–9 appears exactly once per row
- **Guessing too early** — Exhaust logical deductions before considering trial-and-error

---

## Quick Reference Card

| Constraint | Rule |
|------------|------|
| Row uniqueness | Digits 0–9 appear exactly once per row |
| Column sum | Empty cells must sum to target minus known values |
| Adjacency | No digit may touch itself (8 directions) |

| Priority Order | Reasoning |
|----------------|-----------|
| Single-candidate cells | No analysis needed |
| Extreme column sums | Fewer valid combinations |
| Fewest empty cells | Smaller search space |
| Most constrained by adjacency | Eliminations already done |

---

*Master these techniques and Tenner Grids transform from frustrating guesswork into satisfying logical deduction.*