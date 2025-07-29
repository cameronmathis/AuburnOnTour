import { DatabaseService } from '../../interfaces/DatabaseService.interface';
import { PlayersService as PlayersServiceInterface } from '../../interfaces/PlayersService.interface';

interface PlayerDocument {
    name: string;
}

export class RemotePlayersService implements PlayersServiceInterface {
    private readonly playersCollection;

    constructor(db: DatabaseService) {
        this.playersCollection = db.collection<PlayerDocument>('players');
    }

    async getAuburnPlayers(): Promise<string[]> {
        try {
            const players = await this.playersCollection.getAll();
            return players
                .map(player => player.name)
                .filter((name): name is string => typeof name === 'string' && name.length > 0);
        } catch (error: unknown) {
            console.error('Error fetching players from database:', error);
            return [];
        }
    }
}
