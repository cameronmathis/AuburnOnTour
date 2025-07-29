import { performance } from 'perf_hooks';

import { CacheService } from './interfaces/CacheService.interface';
import { PlayersService } from './interfaces/PlayersService.interface';
import { Leaderboard, PlayerDetails, Round, TournamentService } from './interfaces/TournamentService.interface';
import { TwitterService } from './interfaces/TwitterService.interface';
import { LocalTranslationService as TranslationService } from './services/TranslationService/LocalTranslationService';
import { logger } from './utils/Logger';
import { RateLimiter } from './utils/RateLimiter';

export class AuburnGolfTracker {
    private readonly twitterRateLimiter: RateLimiter;
    private readonly tournamentRateLimiter: RateLimiter;

    constructor(
        private readonly tournamentService: TournamentService,
        private readonly cacheService: CacheService,
        private readonly twitterService: TwitterService,
        private readonly playerService: PlayersService,
        private readonly translationService = TranslationService.getInstance()
    ) {
        this.twitterRateLimiter = new RateLimiter(15 * 60 * 1000, 15);
        this.tournamentRateLimiter = new RateLimiter(60 * 1000, 100);
    }

    async poll(): Promise<void> {
        const startTime = performance.now();
        try {
            await this.tournamentRateLimiter.waitForSlot();
            const tournamentId: string | null = await this.tournamentService.getCurrentTournament();
            if (!tournamentId) {
                logger.info('No active tournament.');
                return;
            }

            await this.tournamentRateLimiter.waitForSlot();
            const leaderboard: Leaderboard = await this.tournamentService.getLeaderboard(tournamentId);
            const leaderboardHash: string = this.cacheService.hashLeaderboard(leaderboard);
            const cachedHash: string | null = await this.cacheService.getTournamentHash(tournamentId);

            if (cachedHash === leaderboardHash) {
                logger.debug('Leaderboard unchanged. Skipping.');
                return;
            }

            const players: PlayerDetails[] = leaderboard.leaderboard.players;
            const tournamentName: string = leaderboard.leaderboard.tournament_name;
            const auburnPlayers: string[] = await this.playerService.getAuburnPlayers();

            await this.processPlayers(players, auburnPlayers, tournamentName);
            await this.cacheService.setTournamentHash(tournamentId, leaderboardHash);

            const endTime = performance.now();
            logger.info({
                message: 'Poll completed successfully',
                duration: endTime - startTime,
                playersProcessed: players.length,
                auburnPlayersFound: auburnPlayers.length,
            });
        } catch (error) {
            const endTime = performance.now();
            logger.error({
                message: 'Error during poll operation',
                error: error instanceof Error ? error.message : String(error),
                duration: endTime - startTime,
            });
            throw error;
        }
    }

    private async processPlayers(
        players: PlayerDetails[],
        auburnPlayers: string[],
        tournamentName: string
    ): Promise<void> {
        for (const p of players) {
            try {
                const name: string = `${p.player_bio.first_name} ${p.player_bio.last_name}`;
                if (auburnPlayers.includes(name)) {
                    await this.processAuburnPlayer(p, name, tournamentName);
                }
            } catch (error) {
                logger.error({
                    message: 'Error processing player',
                    player: p.player_bio.player_id,
                    error: error instanceof Error ? error.message : String(error),
                });
            }
        }
    }

    private async processAuburnPlayer(player: PlayerDetails, name: string, tournamentName: string): Promise<void> {
        const playerId: string = player.player_bio.player_id;
        const lastRound: Round = player.rounds[player.rounds.length - 1];

        if (lastRound?.round_status === 'complete') {
            try {
                if (!(await this.cacheService.hasTweeted(playerId, lastRound.round_number))) {
                    const tweet = this.translationService.translate('roundUpdate', {
                        playerName: name,
                        score: player.today,
                        position: player.current_position,
                        tournament: tournamentName,
                    });

                    await this.twitterRateLimiter.waitForSlot();
                    await this.twitterService.sendTweet(tweet);
                    await this.cacheService.markTweeted(playerId, lastRound.round_number);

                    logger.info({
                        message: 'Tweet sent successfully',
                        player: name,
                        round: lastRound.round_number,
                        tournament: tournamentName,
                    });
                }
            } catch (error) {
                logger.error({
                    message: 'Error sending tweet',
                    player: name,
                    round: lastRound.round_number,
                    error: error instanceof Error ? error.message : String(error),
                });
                throw error;
            }
        }
    }
}
