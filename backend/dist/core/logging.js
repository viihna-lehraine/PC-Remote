// File: backend/src/core/logging.ts
export function patchConsole(log) {
    console.log = (...args) => log.info(args.join(' '));
    console.warn = (...args) => log.warn(args.join(' '));
    console.error = (...args) => log.error(args.join(' '));
    console.debug = (...args) => log.debug(args.join(' '));
}
//# sourceMappingURL=logging.js.map