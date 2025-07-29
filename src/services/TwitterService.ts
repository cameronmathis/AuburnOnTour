import { TwitterApi } from 'twitter-api-v2';
import { TwitterService as TwitterServiceInterface } from '../interfaces/TwitterService.interface';

export class TwitterService implements TwitterServiceInterface {
    private readonly twitterClient: TwitterApi;

    constructor() {
        this.twitterClient = new TwitterApi({
            appKey: process.env.TWITTER_API_KEY!,
            appSecret: process.env.TWITTER_API_SECRET!,
            accessToken: process.env.TWITTER_ACCESS_TOKEN!,
            accessSecret: process.env.TWITTER_ACCESS_SECRET!,
        });
    }

    async sendTweet(tweet: string): Promise<void> {
        await this.twitterClient.v2.tweet(tweet);
        console.log(`Tweeted: ${tweet}`);
    }
}
