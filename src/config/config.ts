import dotenv from 'dotenv';
import { z } from 'zod';

const result = dotenv.config();
if (result.error) {
    throw new Error('Failed to load environment variables');
}

const nonEmptyString = z.string().min(1, 'Field cannot be empty');

const productionSchema = z.object({
    NODE_ENV: z.literal('production'),
    LOG_LEVEL: z.enum(['error', 'warn', 'info']).default('info'),
});

const developmentSchema = z.object({
    NODE_ENV: z.literal('development'),
    LOG_LEVEL: z.enum(['error', 'warn', 'info', 'debug']).default('debug'),
});

const baseConfigSchema = z.object({
    GOOGLE_CLOUD_PROJECT_ID: nonEmptyString,
    TWITTER_API_KEY: nonEmptyString,
    TWITTER_API_SECRET: nonEmptyString,
    TWITTER_ACCESS_TOKEN: z.string().regex(/^\d+-[A-Za-z0-9]+$/, 'Invalid Twitter access token format'),
    TWITTER_ACCESS_SECRET: nonEmptyString,
});

const configSchema = z.discriminatedUnion('NODE_ENV', [
    productionSchema.merge(baseConfigSchema),
    developmentSchema.merge(baseConfigSchema),
]);

export type Config = z.infer<typeof configSchema>;

export function getConfig(): Config {
    try {
        const config = configSchema.parse({
            ...process.env,
        });

        return config;
    } catch (error) {
        if (error instanceof z.ZodError) {
            const errors = error.issues.map((e: z.ZodIssue) => {
                const path = e.path.join('.');
                return `${path}: ${e.message}`;
            });
            throw new Error(`Configuration validation failed:\n${errors.join('\n')}`);
        }
        throw new Error('Unexpected configuration error');
    }
}

export const config = getConfig();
