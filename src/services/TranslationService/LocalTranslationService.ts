import i18next from 'i18next';
import Backend from 'i18next-fs-backend';
import path from 'path';

import { TranslationService as TranslationServiceInterface } from '../../interfaces/TranslationService.interface';

export class LocalTranslationService implements TranslationServiceInterface {
    private static instance: TranslationServiceInterface;
    private readonly defaultLanguage = 'en';

    private constructor() {
        this.initializeI18n();
    }

    public static getInstance(): TranslationServiceInterface {
        if (!LocalTranslationService.instance) {
            LocalTranslationService.instance = new LocalTranslationService();
        }
        return LocalTranslationService.instance;
    }

    private async initializeI18n(): Promise<void> {
        await i18next.use(Backend).init({
            lng: this.defaultLanguage,
            fallbackLng: this.defaultLanguage,
            backend: {
                loadPath: path.join(__dirname, '../locales/{{lng}}/translation.json'),
            },
            interpolation: {
                escapeValue: false,
            },
        });
    }

    translate(key: string, params?: Record<string, string | number>): string {
        return i18next.t(key, params);
    }

    getAvailableLanguages(): string[] {
        return Object.keys(i18next.services.resourceStore.data);
    }

    setLanguage(language: string): void {
        i18next.changeLanguage(language);
    }
}
