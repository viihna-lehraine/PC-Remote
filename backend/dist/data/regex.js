// File: backend/src/data/regex.ts
const css = /<link rel="stylesheet" href="\/assets\/([^"]+\.css)">/;
const email = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const js = /<script src="\/assets\/([^"]+\.js)">/;
const password = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$/;
const username = /^[a-zA-Z0-9._-]{3,30}$/;
export const regex = {
    css,
    email,
    js,
    password,
    username
};
//# sourceMappingURL=regex.js.map