import { error, json, options } from "@/lib/http";
import { getLeaderboard, getPlayer, updatePlayerProfile } from "@/lib/store";
import { winRate } from "@/lib/types";

type Params = { params: Promise<{ id: string }> };

export async function GET(_request: Request, { params }: Params) {
  const { id } = await params;
  const player = getPlayer(id);
  if (!player) return error("Player not found", 404);

  const board = getLeaderboard("highScore", 200);
  const rank = board.find((e) => e.playerId === id)?.rank ?? null;

  return json({
    player: {
      ...player,
      winRate: winRate(player.stats),
      averageScore:
        player.stats.gamesPlayed > 0
          ? Math.round(player.stats.totalScore / player.stats.gamesPlayed)
          : 0,
      rank,
    },
  });
}

export async function PATCH(request: Request, { params }: Params) {
  const { id } = await params;
  try {
    const body = await request.json();
    const player = updatePlayerProfile(id, {
      displayName: body.displayName ? String(body.displayName) : undefined,
      avatarEmoji: body.avatarEmoji ? String(body.avatarEmoji) : undefined,
    });
    if (!player) return error("Player not found", 404);
    return json({
      player: {
        ...player,
        winRate: winRate(player.stats),
      },
    });
  } catch {
    return error("Invalid JSON body");
  }
}

export async function OPTIONS() {
  return options();
}
