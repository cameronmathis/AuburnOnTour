import crypto from 'crypto';
import { CacheService as CacheServiceInterface } from '../interfaces/CacheService.interface';
import { DatabaseService } from '../interfaces/DatabaseService.interface';

interface TournamentHashData {
    hash: string;
}

interface TweetedRoundData {
    tweetedAt: string;
}

export class CacheService implements CacheServiceInterface {
    private readonly tournamentHashCollection;
    private readonly tweetedRoundsCollection;

    constructor(private readonly db: DatabaseService) {
        this.tournamentHashCollection = db.collection<TournamentHashData>('cache');
        this.tweetedRoundsCollection = db.collection<TweetedRoundData>('tweetedRounds');
    }

    async getTournamentHash(tournamentId: string): Promise<string | null> {
        const data = await this.tournamentHashCollection.get(tournamentId);
        return data?.hash ?? null;
    }

    async setTournamentHash(tournamentId: string, hash: string): Promise<void> {
        await this.tournamentHashCollection.set(tournamentId, { hash });
    }

    async hasTweeted(playerId: string, roundNumber: number): Promise<boolean> {
        const docId = `${playerId}-${roundNumber}`;
        const doc = await this.tweetedRoundsCollection.get(docId);
        return doc !== null;
    }

    async markTweeted(playerId: string, roundNumber: number): Promise<void> {
        const docId = `${playerId}-${roundNumber}`;
        await this.tweetedRoundsCollection.set(docId, {
            tweetedAt: new Date().toISOString(),
        });
    }

    hashLeaderboard(data: unknown): string {
        return crypto.createHash('sha256').update(JSON.stringify(data)).digest('hex');
    }
}
