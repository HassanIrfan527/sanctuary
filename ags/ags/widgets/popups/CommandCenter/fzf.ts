// Minimal fzf-style fuzzy scoring.
// Inspired by junegunn/fzf's v1 algorithm. Not a full port — covers the
// common bonuses: prefix match, consecutive chars, camel/word boundary,
// and penalizes gaps.

const SCORE_MATCH = 16
const SCORE_GAP_START = -3
const SCORE_GAP_EXT = -1
const BONUS_BOUNDARY = 8
const BONUS_CAMEL = 4
const BONUS_CONSEC = 4
const BONUS_FIRST_CHAR = 12

function isBoundary(s: string, i: number): boolean {
  if (i === 0) return true
  const prev = s[i - 1]
  return prev === " " || prev === "-" || prev === "_" || prev === "/" || prev === "."
}

function isCamel(s: string, i: number): boolean {
  if (i === 0) return false
  const prev = s[i - 1]
  const cur = s[i]
  return prev === prev.toLowerCase() && cur === cur.toUpperCase() && cur !== prev
}

export interface FzfMatch {
  score: number
  indices: number[]
}

export function fzfScore(query: string, target: string): FzfMatch | null {
  if (!query) return { score: 0, indices: [] }
  const q = query.toLowerCase()
  const t = target.toLowerCase()

  let score = 0
  let ti = 0
  let lastMatch = -2
  const indices: number[] = []

  for (let qi = 0; qi < q.length; qi++) {
    const qc = q[qi]
    let found = -1
    for (let j = ti; j < t.length; j++) {
      if (t[j] === qc) { found = j; break }
    }
    if (found === -1) return null

    let bonus = SCORE_MATCH
    if (qi === 0 && found === 0) bonus += BONUS_FIRST_CHAR
    if (isBoundary(target, found)) bonus += BONUS_BOUNDARY
    if (isCamel(target, found)) bonus += BONUS_CAMEL
    if (found === lastMatch + 1) bonus += BONUS_CONSEC

    const gap = found - (lastMatch + 1)
    if (gap > 0 && lastMatch >= 0) {
      score += SCORE_GAP_START + (gap - 1) * SCORE_GAP_EXT
    }

    score += bonus
    indices.push(found)
    lastMatch = found
    ti = found + 1
  }

  return { score, indices }
}

// Rank a list of candidates against query; returns sorted, filtered items.
export function fzfRank<T>(
  query: string,
  items: T[],
  accessor: (item: T) => string,
  limit = 30,
): Array<{ item: T; score: number; indices: number[] }> {
  if (!query) return items.slice(0, limit).map((item) => ({ item, score: 0, indices: [] }))
  const scored: Array<{ item: T; score: number; indices: number[] }> = []
  for (const item of items) {
    const m = fzfScore(query, accessor(item))
    if (m) scored.push({ item, score: m.score, indices: m.indices })
  }
  scored.sort((a, b) => b.score - a.score)
  return scored.slice(0, limit)
}
