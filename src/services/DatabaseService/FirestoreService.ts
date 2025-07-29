import { CollectionReference, DocumentData, Firestore } from '@google-cloud/firestore';

import { DatabaseCollection, DatabaseService } from '../../interfaces/DatabaseService.interface';

class FirestoreCollection<T extends DocumentData> implements DatabaseCollection<T> {
    private collection: CollectionReference<T>;

    constructor(db: Firestore, collectionName: string) {
        this.collection = db.collection(collectionName) as CollectionReference<T>;
    }

    async get(id: string): Promise<T | null> {
        const doc = await this.collection.doc(id).get();
        const data = doc.exists ? doc.data() : null;
        return data ?? null;
    }

    async set(id: string, data: T): Promise<void> {
        await this.collection.doc(id).set(data);
    }

    async getAll(): Promise<T[]> {
        const snapshot = await this.collection.get();
        return snapshot.docs.map(doc => doc.data());
    }
}

export class FirestoreService implements DatabaseService {
    private db: Firestore;

    constructor(projectId: string) {
        this.db = new Firestore({
            projectId: projectId,
        });
    }

    collection<T extends DocumentData>(name: string): DatabaseCollection<T> {
        return new FirestoreCollection<T>(this.db, name);
    }
}
