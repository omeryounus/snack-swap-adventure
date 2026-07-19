export interface PlayerStats {
  highScore: number;
  totalScore: number;
  levelsCompleted: number;
  levelsPlayed: number;
  highestLevel: number;
  totalStars: number;
  maxCombo: number;
  wins: number;
  losses: number;
  gamesPlayed: number;
  bestSingleLevelScore: number;
  currentWinStreak: number;
  bestWinStreak: number;
}

export interface Player {
  id: string;
  displayName: string;
  avatarEmoji: string;
  createdAt: string;
  updatedAt: string;
  lastPlayedAt: string;
  stats: PlayerStats;
}

export interface ScoreEvent {
  id: string;
  playerId: string;
  displayName: string;
  level: number;
  score: number;
  stars: number;
  won: boolean;
  movesLeft: number;
  maxCombo: number;
  createdAt: string;
}

export interface LeaderboardEntry {
  rank: number;
  playerId: string;
  displayName: string;
  avatarEmoji: string;
  highScore: number;
  totalScore: number;
  highestLevel: number;
  totalStars: number;
  wins: number;
  gamesPlayed: number;
  winRate: number;
  maxCombo: number;
  lastPlayedAt: string;
}

export interface GlobalStats {
  totalPlayers: number;
  totalGamesPlayed: number;
  totalWins: number;
  totalScoreAllTime: number;
  averageHighScore: number;
  topScore: number;
  topPlayerName: string | null;
  levelsCompleted: number;
}

export type LeaderboardSort =
  | "highScore"
  | "totalScore"
  | "highestLevel"
  | "totalStars"
  | "wins"
  | "maxCombo";

export function emptyStats(): PlayerStats {
  return {
    highScore: 0,
    totalScore: 0,
    levelsCompleted: 0,
    levelsPlayed: 0,
    highestLevel: 0,
    totalStars: 0,
    maxCombo: 0,
    wins: 0,
    losses: 0,
    gamesPlayed: 0,
    bestSingleLevelScore: 0,
    currentWinStreak: 0,
    bestWinStreak: 0,
  };
}

export function winRate(stats: PlayerStats): number {
  if (stats.gamesPlayed <= 0) return 0;
  return Math.round((stats.wins / stats.gamesPlayed) * 1000) / 10;
}
