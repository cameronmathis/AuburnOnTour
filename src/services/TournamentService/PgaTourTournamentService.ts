import fetch, { Response } from 'node-fetch';
import {
    Leaderboard,
    TournamentService as TournamentServiceInterface,
} from '../../interfaces/TournamentService.interface';

export interface TournamentDetails {
    tournament_id: number;
    is_active: boolean;
}

export interface TournamentSchedule {
    schedule: TournamentDetails[];
}

export class TournamentService implements TournamentServiceInterface {
    private readonly baseUrl: string = 'https://statdata.pgatour.com/r';

    async getCurrentTournament(): Promise<string | null> {
        const res: Response = await fetch(`${this.baseUrl}/current/schedule.json`);
        const data: TournamentSchedule = (await res.json()) as TournamentSchedule;
        const active: Array<TournamentDetails> = data.schedule.filter(t => t.is_active);
        return active.length > 0 ? active[0].tournament_id.toString() : null;
    }

    async getLeaderboard(tournamentId: string): Promise<Leaderboard> {
        const url: string = `${this.baseUrl}/${tournamentId}/2025/leaderboard-v2.json`;
        const res: Response = await fetch(url);
        return res.json() as Promise<Leaderboard>;
    }
}
