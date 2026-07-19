import { getGlobalStats, getLeaderboard } from "../lib/store.js";
export const dynamic = "force-dynamic";
export default function Page() {
  const g = getGlobalStats();
  const board = getLeaderboard("highScore", 25);
  return (
    <main style={{maxWidth:900,margin:"0 auto",padding:32}}>
      <h1 style={{background:"linear-gradient(90deg,#ffd666,#ff9a4d,#ff6bab)",WebkitBackgroundClip:"text",color:"transparent"}}>Snack Swap Adventure</h1>
      <p style={{opacity:0.75}}>Live leaderboard and player stats API</p>
      <div style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:12,margin:"20px 0"}}>
        {[["Players",g.totalPlayers],["Games",g.totalGamesPlayed],["Top Score",g.topScore],["Champion",g.topPlayerName||"-"]].map(([l,v])=>(
          <div key={l} style={{background:"rgba(255,255,255,0.08)",borderRadius:16,padding:16}}>
            <div style={{fontSize:12,opacity:0.7}}>{l}</div>
            <div style={{fontSize:22,fontWeight:800}}>{String(v)}</div>
          </div>
        ))}
      </div>
      <section style={{background:"rgba(255,255,255,0.08)",borderRadius:16,padding:18}}>
        <h2>Leaderboard</h2>
        <table style={{width:"100%",borderCollapse:"collapse"}}>
          <thead><tr style={{opacity:0.7,textAlign:"left"}}><th>#</th><th>Player</th><th>High</th><th>Total</th><th>Level</th><th>Wins</th></tr></thead>
          <tbody>
            {board.map(e=>(
              <tr key={e.playerId} style={{borderTop:"1px solid rgba(255,255,255,0.08)"}}>
                <td style={{padding:8,color:"#ffd666",fontWeight:800}}>{e.rank}</td>
                <td style={{padding:8}}>{e.avatarEmoji} {e.displayName}</td>
                <td style={{padding:8}}>{e.highScore}</td>
                <td style={{padding:8}}>{e.totalScore}</td>
                <td style={{padding:8}}>{e.highestLevel}</td>
                <td style={{padding:8}}>{e.wins} ({e.winRate}%)</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
      <pre style={{marginTop:20,opacity:0.8,fontSize:12,background:"rgba(0,0,0,0.25)",padding:16,borderRadius:12}}>{`GET  /api/health
GET  /api/leaderboard?sort=highScore&limit=50
GET  /api/players
POST /api/players
GET  /api/players/:id
PATCH /api/players/:id
POST /api/scores
GET  /api/stats/global
GET  /api/stats/:playerId`}</pre>
    </main>
  );
}
