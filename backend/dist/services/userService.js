// File: services/userService.ts
import argon2 from 'argon2';
import { getDb } from '../db/client.js';
import { getPepper } from './vaultClient.js';
export async function hashPassword(password) {
    const pepper = await getPepper();
    return await argon2.hash(password + pepper, {
        type: argon2.argon2id,
        timeCost: 3,
        memoryCost: 2 ** 16,
        parallelism: 2
    });
}
export async function createUser(username, password, email) {
    const hashedPassword = await hashPassword(password);
    const db = getDb();
    await db.query(`INSERT INTO users (username, password_hash, email) VALUES ($1, $2, $3)`, [
        username,
        hashedPassword,
        email ?? null
    ]);
}
//# sourceMappingURL=userService.js.map