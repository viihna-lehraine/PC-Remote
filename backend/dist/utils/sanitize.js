// File: backend/src/utils/sanitize.ts
import sanitizeHtml from 'sanitize-html';
function html(userInput) {
    return sanitizeHtml(userInput);
}
export const sanitize = {
    html
};
//# sourceMappingURL=sanitize.js.map