export interface TranslationService {
    translate(key: string, params?: Record<string, string | number>): string;
    getAvailableLanguages(): string[];
    setLanguage(language: string): void;
}
