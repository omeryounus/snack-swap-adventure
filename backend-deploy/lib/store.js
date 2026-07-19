/**
 * Durable game store for Snack Swap Adventure.
 * - Always seeds demo rivals so the board is never empty.
 * - Persists real players to Upstash Redis when UPSTASH_REDIS_REST_URL + TOKEN are set.
 * - Also mirrors to /tmp for warm-instance durability on Vercel.
 */

const GLOBAL_KEY = "__snack_swap_store_v2__";
const REDIS_KEY = "snack-swap:store:v1";
const TMP_PATH = "/tmp/snack-swap-store-v2.json";

function emptyStats() {
  return {
    highScore: 0, totalScore: 0, levelsCompleted: 0, levelsPlayed: 0, highestLevel: 0,
    totalStars: 0, maxCombo: 0, wins: 0, losses: 0, gamesPlayed: 0,
    bestSingleLevelScore: 0, currentWinStreak: 0, bestWinStreak: 0,
  };
}

function winRate(stats) {
  if (stats.gamesPlayed <= 0) return 0;
  return Math.round((stats.wins / stats.gamesPlayed) * 1000) / 10;
}

function redisConfigured() {
  return !!(process.env.UPSTASH_REDIS_REST_URL && process.env.UPSTASH_REDIS_REST_TOKEN);
}

async function redisGet(key) {
  if (!redisConfigured()) return null;
  try {
    const res = await fetch(`${process.env.UPSTASH_REDIS_REST_URL}/get/${encodeURIComponent(key)}`, {
      headers: { Authorization: `Bearer ${process.env.UPSTASH_REDIS_REST_TOKEN}` },
      cache: "no-store",
    });
    if (!res.ok) return null;
    const body = await res.json();
    if (body.result == null) return null;
    return typeof body.result === "string" ? JSON.parse(body.result) : body.result;
  } catch {
    return null;
  }
}

async function redisSet(key, value) {
  if (!redisConfigured()) return false;
  try {
    const res = await fetch(`${process.env.UPSTASH_REDIS_REST_URL}/set/${encodeURIComponent(key)}`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${process.env.UPSTASH_REDIS_REST_TOKEN}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(value),
    });
    return res.ok;
  } catch {
    return false;
  }
}

function writeTmp(snapshot) {
  try {
    const fs = require("fs");
    fs.writeFileSync(TMP_PATH, JSON.stringify(snapshot));
  } catch {
    // ignore
  }
}

function readTmp() {
  try {
    const fs = require("fs");
    if (!fs.existsSync(TMP_PATH)) return null;
    return JSON.parse(fs.readFileSync(TMP_PATH, "utf8"));
  } catch {
    return null;
  }
}

function snapshotFromStore(store) {
  return {
    players: Array.from(store.players.values()),
    scores: store.scores.slice(0, 500),
  };
}

function applySnapshot(store, snapshot) {
  if (!snapshot || !Array.isArray(snapshot.players)) return;
  for (const p of snapshot.players) {
    if (!p?.id) continue;
    store.players.set(p.id, {
      ...p,
      stats: { ...emptyStats(), ...(p.stats || {}) },
    });
  }
  if (Array.isArray(snapshot.scores)) {
    store.scores = snapshot.scores.slice(0, 500);
  }
}

async function persist(store) {
  const snap = snapshotFromStore(store);
  writeTmp(snap);
  await redisSet(REDIS_KEY, snap);
}

function getStore() {
  if (!globalThis[GLOBAL_KEY]) {
    globalThis[GLOBAL_KEY] = {
      players: new Map(),
      scores: [],
      seeded: false,
      hydratePromise: null,
    };
  }
  const store = globalThis[GLOBAL_KEY];
  if (!store.seeded) {
    seedDemoPlayers(store);
    const tmp = readTmp();
    if (tmp) applySnapshot(store, tmp);
    store.seeded = true;
  }
  return store;
}

/** Ensure Redis hydrate runs once per cold start. */
async function ensureHydrated() {
  const store = getStore();
  if (store.hydratedFromRedis) return store;
  if (!store.hydratePromise) {
    store.hydratePromise = (async () => {
      const remote = await redisGet(REDIS_KEY);
      if (remote) applySnapshot(store, remote);
      store.hydratedFromRedis = true;
    })();
  }
  await store.hydratePromise;
  return store;
}

const DEMO = [
  ["bot-munch-master", "MunchMaster", "👾", { highScore: 10250, totalScore: 78400, levelsCompleted: 30, levelsPlayed: 42, highestLevel: 30, totalStars: 90, maxCombo: 14, wins: 36, losses: 6, gamesPlayed: 42, bestSingleLevelScore: 10250, currentWinStreak: 9, bestWinStreak: 15 }],
  ["bot-candy-crusher", "CandyCrusher", "🍬", { highScore: 9680, totalScore: 61200, levelsCompleted: 30, levelsPlayed: 38, highestLevel: 30, totalStars: 84, maxCombo: 12, wins: 30, losses: 8, gamesPlayed: 38, bestSingleLevelScore: 9680, currentWinStreak: 6, bestWinStreak: 14 }],
  ["bot-cookie-queen", "CookieQueen", "🍪", { highScore: 8420, totalScore: 45200, levelsCompleted: 28, levelsPlayed: 34, highestLevel: 28, totalStars: 72, maxCombo: 9, wins: 28, losses: 6, gamesPlayed: 34, bestSingleLevelScore: 8420, currentWinStreak: 4, bestWinStreak: 11 }],
  ["bot-popcorn-pro", "PopcornPro", "🍿", { highScore: 7150, totalScore: 38100, levelsCompleted: 22, levelsPlayed: 30, highestLevel: 24, totalStars: 55, maxCombo: 7, wins: 22, losses: 8, gamesPlayed: 30, bestSingleLevelScore: 7150, currentWinStreak: 2, bestWinStreak: 8 }],
  ["bot-lolli-legend", "LolliLegend", "🍭", { highScore: 6890, totalScore: 30500, levelsCompleted: 19, levelsPlayed: 25, highestLevel: 20, totalStars: 48, maxCombo: 8, wins: 19, losses: 6, gamesPlayed: 25, bestSingleLevelScore: 6890, currentWinStreak: 3, bestWinStreak: 7 }],
  ["bot-snack-ninja", "SnackNinja", "🥷", { highScore: 5900, totalScore: 27400, levelsCompleted: 17, levelsPlayed: 24, highestLevel: 18, totalStars: 40, maxCombo: 7, wins: 17, losses: 7, gamesPlayed: 24, bestSingleLevelScore: 5900, currentWinStreak: 2, bestWinStreak: 6 }],
  ["bot-donut-dash", "DonutDash", "🍩", { highScore: 5340, totalScore: 22100, levelsCompleted: 15, levelsPlayed: 22, highestLevel: 16, totalStars: 33, maxCombo: 6, wins: 15, losses: 7, gamesPlayed: 22, bestSingleLevelScore: 5340, currentWinStreak: 1, bestWinStreak: 5 }],
  ["bot-cupcake-champ", "CupcakeChamp", "🧁", { highScore: 4120, totalScore: 15800, levelsCompleted: 11, levelsPlayed: 18, highestLevel: 12, totalStars: 24, maxCombo: 5, wins: 11, losses: 7, gamesPlayed: 18, bestSingleLevelScore: 4120, currentWinStreak: 0, bestWinStreak: 4 }],
];

function seedDemoPlayers(store) {
  const now = new Date().toISOString();
  for (const [id, displayName, avatarEmoji, stats] of DEMO) {
    if (store.players.has(id)) continue;
    store.players.set(id, {
      id, displayName, avatarEmoji,
      createdAt: now, updatedAt: now, lastPlayedAt: now,
      stats: { ...emptyStats(), ...stats },
    });
  }
}

function sanitizeName(name) {
  const cleaned = String(name || "").replace(/[^\w\s\-'.]/g, "").trim().slice(0, 20);
  return cleaned || "Snack Star";
}

function clampInt(n, min, max) {
  if (!Number.isFinite(n)) return min;
  return Math.max(min, Math.min(max, Math.floor(n)));
}

function listPlayers() {
  return Array.from(getStore().players.values());
}

function getPlayer(id) {
  return getStore().players.get(id) || null;
}

function upsertPlayer(input) {
  const store = getStore();
  const now = new Date().toISOString();
  const name = sanitizeName(input.displayName);
  if (input.id && store.players.has(input.id)) {
    const existing = store.players.get(input.id);
    existing.displayName = name;
    if (input.avatarEmoji) existing.avatarEmoji = input.avatarEmoji;
    existing.updatedAt = now;
    store.players.set(existing.id, existing);
    queuePersist(store);
    return existing;
  }
  const id = (input.id && String(input.id).trim()) || crypto.randomUUID();
  const player = {
    id,
    displayName: name,
    avatarEmoji: input.avatarEmoji || "👾",
    createdAt: now,
    updatedAt: now,
    lastPlayedAt: now,
    stats: emptyStats(),
  };
  store.players.set(id, player);
  queuePersist(store);
  return player;
}

function updatePlayerProfile(id, patch) {
  const store = getStore();
  const player = store.players.get(id);
  if (!player) return null;
  if (patch.displayName) player.displayName = sanitizeName(patch.displayName);
  if (patch.avatarEmoji) player.avatarEmoji = String(patch.avatarEmoji).slice(0, 4);
  player.updatedAt = new Date().toISOString();
  store.players.set(id, player);
  queuePersist(store);
  return player;
}

function sortValue(p, sort) {
  const s = p.stats;
  switch (sort) {
    case "totalScore": return s.totalScore;
    case "highestLevel": return s.highestLevel;
    case "totalStars": return s.totalStars;
    case "wins": return s.wins;
    case "maxCombo": return s.maxCombo;
    default: return s.highScore;
  }
}

function getLeaderboard(sort = "highScore", limit = 50) {
  const players = listPlayers().slice().sort((a, b) => {
    const d = sortValue(b, sort) - sortValue(a, sort);
    return d !== 0 ? d : b.stats.totalScore - a.stats.totalScore;
  });
  return players.slice(0, Math.min(100, Math.max(1, limit))).map((p, i) => ({
    rank: i + 1,
    playerId: p.id,
    displayName: p.displayName,
    avatarEmoji: p.avatarEmoji,
    highScore: p.stats.highScore,
    totalScore: p.stats.totalScore,
    highestLevel: p.stats.highestLevel,
    totalStars: p.stats.totalStars,
    wins: p.stats.wins,
    gamesPlayed: p.stats.gamesPlayed,
    winRate: winRate(p.stats),
    maxCombo: p.stats.maxCombo,
    lastPlayedAt: p.lastPlayedAt,
  }));
}

function submitScore(input) {
  const store = getStore();
  const now = new Date().toISOString();
  let player = store.players.get(input.playerId);
  if (!player) {
    player = upsertPlayer({ id: input.playerId, displayName: input.displayName || "Snack Star" });
  } else if (input.displayName) {
    player.displayName = sanitizeName(input.displayName);
  }
  const level = clampInt(input.level, 1, 999);
  const score = clampInt(input.score, 0, 10000000);
  const stars = clampInt(input.stars, 0, 3);
  const maxCombo = clampInt(input.maxCombo, 0, 99);
  const movesLeft = clampInt(input.movesLeft, 0, 999);
  const s = player.stats;
  s.gamesPlayed += 1;
  s.levelsPlayed += 1;
  s.totalScore += score;
  s.highScore = Math.max(s.highScore, score);
  s.bestSingleLevelScore = Math.max(s.bestSingleLevelScore, score);
  s.maxCombo = Math.max(s.maxCombo, maxCombo);
  s.highestLevel = Math.max(s.highestLevel, level);
  if (input.won) {
    s.wins += 1;
    s.levelsCompleted += 1;
    s.totalStars += stars;
    s.currentWinStreak += 1;
    s.bestWinStreak = Math.max(s.bestWinStreak, s.currentWinStreak);
  } else {
    s.losses += 1;
    s.currentWinStreak = 0;
  }
  player.lastPlayedAt = now;
  player.updatedAt = now;
  store.players.set(player.id, player);
  const event = {
    id: crypto.randomUUID(),
    playerId: player.id,
    displayName: player.displayName,
    level, score, stars,
    won: !!input.won,
    movesLeft, maxCombo,
    createdAt: now,
  };
  store.scores.unshift(event);
  if (store.scores.length > 500) store.scores.length = 500;
  queuePersist(store);
  const board = getLeaderboard("highScore", 200);
  const rank = (board.find((e) => e.playerId === player.id) || {}).rank || board.length + 1;
  return { player, event, rank };
}

function getGlobalStats() {
  const players = listPlayers();
  if (!players.length) {
    return {
      totalPlayers: 0, totalGamesPlayed: 0, totalWins: 0, totalScoreAllTime: 0,
      averageHighScore: 0, topScore: 0, topPlayerName: null, levelsCompleted: 0,
    };
  }
  let totalGames = 0, totalWins = 0, totalScore = 0, totalHigh = 0, levelsCompleted = 0;
  let topScore = 0, topPlayerName = null;
  for (const p of players) {
    totalGames += p.stats.gamesPlayed;
    totalWins += p.stats.wins;
    totalScore += p.stats.totalScore;
    totalHigh += p.stats.highScore;
    levelsCompleted += p.stats.levelsCompleted;
    if (p.stats.highScore > topScore) {
      topScore = p.stats.highScore;
      topPlayerName = p.displayName;
    }
  }
  return {
    totalPlayers: players.length,
    totalGamesPlayed: totalGames,
    totalWins,
    totalScoreAllTime: totalScore,
    averageHighScore: Math.round(totalHigh / players.length),
    topScore,
    topPlayerName,
    levelsCompleted,
  };
}

function recentScores(limit = 20) {
  return getStore().scores.slice(0, Math.min(100, Math.max(1, limit)));
}

function durabilityInfo() {
  return {
    redis: redisConfigured(),
    tmpMirror: true,
    note: redisConfigured()
      ? "Persisting to Upstash Redis"
      : "In-memory + /tmp mirror. Set UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN for multi-instance durability.",
  };
}

let persistTimer = null;
function queuePersist(store) {
  writeTmp(snapshotFromStore(store));
  if (persistTimer) clearTimeout(persistTimer);
  persistTimer = setTimeout(() => {
    persist(store).catch(() => {});
  }, 50);
}

export {
  emptyStats,
  winRate,
  listPlayers,
  getPlayer,
  upsertPlayer,
  updatePlayerProfile,
  getLeaderboard,
  submitScore,
  getGlobalStats,
  recentScores,
  ensureHydrated,
  durabilityInfo,
};
