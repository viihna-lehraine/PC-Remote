// File: backend/src/data/regex.ts
const email = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const password = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$/;
const username = /^[a-zA-Z0-9._-]{3,30}$/;
export const regex = {
    email,
    password,
    username
};
//# sourceMappingURL=regex.js.map