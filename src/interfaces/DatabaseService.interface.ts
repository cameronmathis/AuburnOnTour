import { DocumentData } from '@google-cloud/firestore';

export interface DatabaseCollection<T extends DocumentData> {
    get(id: string): Promise<T | null>;
    set(id: string, data: T): Promise<void>;
    getAll(): Promise<T[]>;
}

export interface DatabaseService {
    collection<T extends DocumentData>(name: string): DatabaseCollection<T>;
}
