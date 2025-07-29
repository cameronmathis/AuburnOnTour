import { promises as fs } from 'fs';
import { PlayersService as PlayersServiceInterface } from '../../interfaces/PlayersService.interface';

export class CsvPlayersService implements PlayersServiceInterface {
    constructor(private readonly filePath: string) {}

    async getAuburnPlayers(): Promise<string[]> {
        try {
            const content: string = await fs.readFile(this.filePath, 'utf-8');
            return content
                .split(',')
                .map((player: string) => player.trim())
                .filter((player: string) => player.length > 0);
        } catch (error) {
            console.error('Error reading players file:', error);
            return [];
        }
    }
}
