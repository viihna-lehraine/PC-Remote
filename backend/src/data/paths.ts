// File: backend/src/data/paths.ts

const configDir_Absolute = '/home/viihna/Projects/pc-remote/backend/config';

const appModeEnv_Absolute = `${configDir_Absolute}/env/appMode.env`;

const devEnvDir_Absolute = `${configDir_Absolute}/env/dev`;
const devDEnvDir_Absolute = `${configDir_Absolute}/env/devd`;
const prodEnvDir_Absolute = `${configDir_Absolute}/env/prod`;

const devEnvMain_Absolute = `${devEnvDir_Absolute}/main.dev.env`;
const devEnvFlag_Absolute = `${devEnvDir_Absolute}/flags.dev.env`;

const devDEnvMain_Absolute = `${devDEnvDir_Absolute}/main.devd.env`;
const devDEnvFlags_Absolute = `${devDEnvDir_Absolute}/flags.devd.env`;

const prodEnvMain_Absolute = `${prodEnvDir_Absolute}/main.prod.env`;
const prodEnvFlag_Absolute = `${prodEnvDir_Absolute}/flags.prod.env`;

export const absolutePaths = {
	appModeEnv: appModeEnv_Absolute,
	devEnv: {
		main: devEnvMain_Absolute,
		flags: devEnvFlag_Absolute
	},
	devDEnv: {
		main: devDEnvMain_Absolute,
		flags: devDEnvFlags_Absolute
	},
	prodEnv: {
		main: prodEnvMain_Absolute,
		flags: prodEnvFlag_Absolute
	}
};
