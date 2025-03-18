// File: backend/src/utils/parse.ts

const parseBoolean = (value: string): boolean => {
	const lowerValue = value.toLowerCase();

	if (lowerValue === 'true' || lowerValue === 't') return true;
	if (lowerValue === 'false' || lowerValue === 'f') return false;
	throw new Error(`Invalid boolean: ${value}. Expected "true" or "false" (or "t"/"f").`);
};

const parseIntStrict = (value: string): number => {
	const parsed = parseInt(value, 10);
	if (isNaN(parsed)) {
		throw new Error(`Invalid number value: ${value}`);
	}
	return parsed;
};

const parseString = (value: string): string => value;

export { parseBoolean, parseIntStrict, parseString };
