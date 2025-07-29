export interface CacheService {
    getTournamentHash(tournamentId: string): Promise<string | null>;
    setTournamentHash(tournamentId: string, hash: string): Promise<void>;
    hasTweeted(playerId: string, roundNumber: number): Promise<boolean>;
    markTweeted(playerId: string, roundNumber: number): Promise<void>;
    hashLeaderboard(data: unknown): string;
}
