export class RateLimiter {
    private timestamps: number[] = [];
    private readonly windowMs: number;
    private readonly maxRequests: number;

    constructor(windowMs: number, maxRequests: number) {
        this.windowMs = windowMs;
        this.maxRequests = maxRequests;
    }

    async checkLimit(): Promise<boolean> {
        const now = Date.now();
        this.timestamps = this.timestamps.filter(t => now - t < this.windowMs);

        if (this.timestamps.length >= this.maxRequests) {
            return false;
        }

        this.timestamps.push(now);
        return true;
    }

    async waitForSlot(): Promise<void> {
        while (!(await this.checkLimit())) {
            await new Promise(resolve => setTimeout(resolve, 1000));
        }
    }
}
