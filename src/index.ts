import path from 'path';

import { AuburnGolfTracker } from './AuburnGolfTracker';
import { getConfig } from './config/config';
import { CacheService as CacheServiceInterface } from './interfaces/CacheService.interface';
import { DatabaseService as DatabaseServiceInterface } from './interfaces/DatabaseService.interface';
import { PlayersService as PlayersServiceInterface } from './interfaces/PlayersService.interface';
import { TournamentService as TournamentServiceInterface } from './interfaces/TournamentService.interface';
import { TranslationService as TranslationServiceInterface } from './interfaces/TranslationService.interface';
import { TwitterService as TwitterServiceInterface } from './interfaces/TwitterService.interface';
import { CacheService } from './services/CacheService';
import { FirestoreService } from './services/DatabaseService/FirestoreService';
import { CsvPlayersService as PlayersService } from './services/PlayersService/CsvPlayersService';
import { TournamentService } from './services/TournamentService/PgaTourTournamentService';
import { LocalTranslationService as TranslationService } from './services/TranslationService/LocalTranslationService';
import { TwitterService } from './services/TwitterService';
import { logger } from './utils/Logger';

export async function handler(req: any, res: any) {
    try {
        const result = await main();
        res.status(200).send(result);
    } catch (error) {
        res.status(500).send({
            error: error instanceof Error ? error.message : 'Internal server error',
        });
    }
}

async function main() {
    try {
        const databaseService: DatabaseServiceInterface = initializeDatabaseService();
        const { tournamentService, cacheService, twitterService, playerService, translationService } =
            initializeServices(databaseService);

        const tracker = new AuburnGolfTracker(
            tournamentService,
            cacheService,
            twitterService,
            playerService,
            translationService
        );

        try {
            await tracker.poll();
            return { success: true };
        } catch (error) {
            logger.error({
                message: 'Error during polling cycle',
                error: error instanceof Error ? error.message : String(error),
            });
            throw error;
        }
    } catch (error) {
        logger.error({
            message: 'Fatal error in main process',
            error: error instanceof Error ? error.message : String(error),
        });
        throw error;
    }
}

function initializeDatabaseService(): DatabaseServiceInterface {
    try {
        const { GOOGLE_CLOUD_PROJECT_ID } = getConfig();
        return new FirestoreService(GOOGLE_CLOUD_PROJECT_ID);
    } catch (error) {
        logger.error('Failed to initialize database service');
        throw error;
    }
}

function initializeServices(databaseService: DatabaseServiceInterface) {
    const tournamentService: TournamentServiceInterface = new TournamentService();
    const cacheService: CacheServiceInterface = new CacheService(databaseService);
    const twitterService: TwitterServiceInterface = new TwitterService();
    const translationService: TranslationServiceInterface = TranslationService.getInstance();
    const playerService: PlayersServiceInterface = new PlayersService(
        path.join(__dirname, 'data', 'auburn-players.csv')
    );

    return {
        tournamentService,
        cacheService,
        twitterService,
        playerService,
        translationService,
    };
}
