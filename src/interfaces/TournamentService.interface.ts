export interface Round {
    round_number: number;
    round_status: string;
}

export interface PlayerDetails {
    player_bio: {
        first_name: string;
        last_name: string;
        player_id: string;
    };
    rounds: Round[];
    today: string;
    current_position: string;
}

export interface Leaderboard {
    leaderboard: {
        tournament_name: string;
        players: PlayerDetails[];
    };
}

export interface TournamentService {
    getCurrentTournament(): Promise<string | null>;
    getLeaderboard(tournamentId: string): Promise<Leaderboard>;
}
