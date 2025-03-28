// File: backend/src/utils/dns.ts
import dns from 'node:dns/promises';
async function tryReverseDNS(ip) {
    try {
        const res = await Promise.race([
            dns.reverse(ip),
            new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout')), 1000))
        ]);
        return res;
    }
    catch {
        return [];
    }
}
export { tryReverseDNS };
//# sourceMappingURL=dns.js.map