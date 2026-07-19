import { randomUUID } from "crypto";
import {
  emptyStats,
  type GlobalStats,
  type LeaderboardEntry,
  type LeaderboardSort,
  type Player,
  type ScoreEvent,
  winRate,
} from "./types";

/**
 * Durable-enough game store for serverless.
 * Uses globalThis so warm instances keep data, and seeds demo rivals
 * so the leaderboard is never empty on cold start.
 *
 * For multi-region durability, swap the Map for Redis/Postgres later —
 * the API surface stays the same.
 */

const GLOBAL_KEY = "__snack_swap_store_v1__";

interface StoreData {
  players: Map<string, Player>;
  scores: ScoreEvent[];
  seeded: boolean;
}

function getStore(): StoreData {
  const g = globalThis as typeof globalThis & { [GLOBAL_KEY]?: StoreData };
  if (!g[GLOBAL_KEY]) {
    g[GLOBAL_KEY] = {
      players: new Map(),
      scores: [],
      seeded: false,
    };
  }
  const store = g[GLOBAL_KEY]!;
  if (!store.seeded) {
    seedDemoPlayers(store);
    store.seeded = true;
  }
  return store;
}

const DEMO_PLAYERS: Array<{
  id: string;
  displayName: string;
  avatarEmoji: string;
  stats: Partial<ReturnType<typeof emptyStats>>;
}> = [
  {
    id: "bot-cookie-queen",
    displayName: "CookieQueen",
    avatarEmoji: "🍪",
    stats: {
      highScore: 8420,
      totalScore: 45200,
      levelsCompleted: 28,
      levelsPlayed: 34,
      highestLevel: 28,
      totalStars: 72,
      maxCombo: 9,
      wins: 28,
      losses: 6,
      gamesPlayed: 34,
      bestSingleLevelScore: 8420,
      currentWinStreak: 4,
      bestWinStreak: 11,
    },
  },
  {
    id: "bot-popcorn-pro",
    displayName: "PopcornPro",
    avatarEmoji: "🍿",
    stats: {
      highScore: 7150,
      totalScore: 38100,
      levelsCompleted: 22,
      levelsPlayed: 30,
      highestLevel: 24,
      totalStars: 55,
      maxCombo: 7,
      wins: 22,
      losses: 8,
      gamesPlayed: 30,
      bestSingleLevelScore: 7150,
      currentWinStreak: 2,
      bestWinStreak: 8,
    },
  },
  {
    id: "bot-candy-crusher",
    displayName: "CandyCrusher",
    avatarEmoji: "🍬",
    stats: {
      highScore: 9680,
      totalScore: 61200,
      levelsCompleted: 30,
      levelsPlayed: 38,
      highestLevel: 30,
      totalStars: 84,
      maxCombo: 12,
      wins: 30,
      losses: 8,
      gamesPlayed: 38,
      bestSingleLevelScore: 9680,
      currentWinStreak: 6,
      bestWinStreak: 14,
    },
  },
  {
    id: "bot-donut-dash",
    displayName: "DonutDash",
    avatarEmoji: "🍩",
    stats: {
      highScore: 5340,
      totalScore: 22100,
      levelsCompleted: 15,
      levelsPlayed: 22,
      highestLevel: 16,
      totalStars: 33,
      maxCombo: 6,
      wins: 15,
      losses: 7,
      gamesPlayed: 22,
      bestSingleLevelScore: 5340,
      currentWinStreak: 1,
      bestWinStreak: 5,
    },
  },
  {
    id: "bot-lolli-legend",
    displayName: "LolliLegend",
    avatarEmoji: "🍭",
    stats: {
      highScore: 6890,
      totalScore: 30500,
      levelsCompleted: 19,
      levelsPlayed: 25,
      highestLevel: 20,
      totalStars: 48,
      maxCombo: 8,
      wins: 19,
      losses: 6,
      gamesPlayed: 25,
      bestSingleLevelScore: 6890,
      currentWinStreak: 3,
      bestWinStreak: 7,
    },
  },
  {
    id: "bot-cupcake-champ",
    displayName: "CupcakeChamp",
    avatarEmoji: "🧁",
    stats: {
      highScore: 4120,
      totalScore: 15800,
      levelsCompleted: 11,
      levelsPlayed: 18,
      highestLevel: 12,
      totalStars: 24,
      maxCombo: 5,
      wins: 11,
      losses: 7,
      gamesPlayed: 18,
      bestSingleLevelScore: 4120,
      currentWinStreak: 0,
      bestWinStreak: 4,
    },
  },
  {
    id: "bot-munch-master",
    displayName: "MunchMaster",
    avatarEmoji: "👾",
    stats: {
      highScore: 10250,
      totalScore: 78400,
      levelsCompleted: 30,
      levelsPlayed: 42,
      highestLevel: 30,
      totalStars: 90,
      maxCombo: 14,
      wins: 36,
      losses: 6,
      gamesPlayed: 42,
      bestSingleLevelScore: 10250,
      currentWinStreak: 9,
      bestWinStreak: 15,
    },
  },
  {
    id: "bot-snack-ninja",
    displayName: "SnackNinja",
    avatarEmoji: "🥷",
    stats: {
      highScore: 5900,
      totalScore: 27400,
      levelsCompleted: 17,
      levelsPlayed: 24,
      highestLevel: 18,
      totalStars: 40,
      maxCombo: 7,
      wins: 17,
      losses: 7,
      gamesPlayed: 24,
      bestSingleLevelScore: 5900,
      currentWinStreak: 2,
      bestWinStreak: 6,
    },
  },
];

function seedDemoPlayers(store: StoreData) {
  const now = new Date().toISOString();
  for (const demo of DEMO_PLAYERS) {
    if (store.players.has(demo.id)) continue;
    store.players.set(demo.id, {
      id: demo.id,
      displayName: demo.displayName,
      avatarEmoji: demo.avatarEmoji,
      createdAt: now,
      updatedAt: now,
      lastPlayedAt: now,
      stats: { ...emptyStats(), ...demo.stats },
    });
  }
}

const AVATARS = ["👾", "🍪", "🍩", "🍬", "🍿", "🍭", "🧁", "⭐", "🌟", "🎮"];

function pickAvatar(name: string): string {
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = (hash + name.charCodeAt(i) * 17) % AVATARS.length;
  return AVATARS[hash];
}

export function listPlayers(): Player[] {
  return Array.from(getStore().players.values());
}

export function getPlayer(id: string): Player | null {
  return getStore().players.get(id) ?? null;
}

export function upsertPlayer(input: {
  id?: string;
  displayName: string;
  avatarEmoji?: string;
}): Player {
  const store = getStore();
  const now = new Date().toISOString();
  const name = sanitizeName(input.displayName);

  if (input.id && store.players.has(input.id)) {
    const existing = store.players.get(input.id)!;
    existing.displayName = name;
    if (input.avatarEmoji) existing.avatarEmoji = input.avatarEmoji;
    existing.updatedAt = now;
    store.players.set(existing.id, existing);
    return existing;
  }

  const id = input.id && input.id.trim().length > 0 ? input.id.trim() : randomUUID();
  const player: Player = {
    id,
    displayName: name,
    avatarEmoji: input.avatarEmoji || pickAvatar(name),
    createdAt: now,
    updatedAt: now,
    lastPlayedAt: now,
    stats: emptyStats(),
  };
  store.players.set(id, player);
  return player;
}

export function updatePlayerProfile(
  id: string,
  patch: { displayName?: string; avatarEmoji?: string }
): Player | null {
  const store = getStore();
  const player = store.players.get(id);
  if (!player) return null;
  if (patch.displayName) player.displayName = sanitizeName(patch.displayName);
  if (patch.avatarEmoji) player.avatarEmoji = patch.avatarEmoji.slice(0, 4);
  player.updatedAt = new Date().toISOString();
  store.players.set(id, player);
  return player;
}

export function submitScore(input: {
  playerId: string;
  displayName?: string;
  level: number;
  score: number;
  stars: number;
  won: boolean;
  movesLeft: number;
  maxCombo: number;
}): { player: Player; event: ScoreEvent; rank: number } {
  const store = getStore();
  const now = new Date().toISOString();

  let player = store.players.get(input.playerId);
  if (!player) {
    player = upsertPlayer({
      id: input.playerId,
      displayName: input.displayName || "Snack Star",
    });
  } else if (input.displayName) {
    player.displayName = sanitizeName(input.displayName);
  }

  const level = clampInt(input.level, 1, 999);
  const score = clampInt(input.score, 0, 10_000_000);
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

  const event: ScoreEvent = {
    id: randomUUID(),
    playerId: player.id,
    displayName: player.displayName,
    level,
    score,
    stars,
    won: input.won,
    movesLeft,
    maxCombo,
    createdAt: now,
  };
  store.scores.unshift(event);
  // Keep last 500 score events
  if (store.scores.length > 500) store.scores.length = 500;

  const board = getLeaderboard("highScore", 200);
  const rank = board.find((e) => e.playerId === player!.id)?.rank ?? board.length + 1;

  return { player, event, rank };
}

export function getLeaderboard(
  sort: LeaderboardSort = "highScore",
  limit = 50
): LeaderboardEntry[] {
  const players = listPlayers();
  const sorted = [...players].sort((a, b) => {
    const av = sortValue(a, sort);
    const bv = sortValue(b, sort);
    if (bv !== av) return bv - av;
    return b.stats.totalScore - a.stats.totalScore;
  });

  return sorted.slice(0, Math.min(100, Math.max(1, limit))).map((p, i) => ({
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

export function getGlobalStats(): GlobalStats {
  const players = listPlayers();
  if (players.length === 0) {
    return {
      totalPlayers: 0,
      totalGamesPlayed: 0,
      totalWins: 0,
      totalScoreAllTime: 0,
      averageHighScore: 0,
      topScore: 0,
      topPlayerName: null,
      levelsCompleted: 0,
    };
  }

  let totalGames = 0;
  let totalWins = 0;
  let totalScore = 0;
  let totalHigh = 0;
  let levelsCompleted = 0;
  let topScore = 0;
  let topPlayerName: string | null = null;

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

export function recentScores(limit = 20): ScoreEvent[] {
  return getStore().scores.slice(0, Math.min(100, Math.max(1, limit)));
}

function sortValue(p: Player, sort: LeaderboardSort): number {
  switch (sort) {
    case "highScore":
      return p.stats.highScore;
    case "totalScore":
      return p.stats.totalScore;
    case "highestLevel":
      return p.stats.highestLevel;
    case "totalStars":
      return p.stats.totalStars;
    case "wins":
      return p.stats.wins;
    case "maxCombo":
      return p.stats.maxCombo;
    default:
      return p.stats.highScore;
  }
}

function sanitizeName(name: string): string {
  const cleaned = name.replace(/[^\w\s\-'.]/g, "").trim().slice(0, 20);
  return cleaned.length > 0 ? cleaned : "Snack Star";
}

function clampInt(n: number, min: number, max: number): number {
  if (!Number.isFinite(n)) return min;
  return Math.max(min, Math.min(max, Math.floor(n)));
}
