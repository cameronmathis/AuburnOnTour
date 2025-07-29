export interface TwitterService {
    sendTweet(tweet: string): Promise<void>;
}
