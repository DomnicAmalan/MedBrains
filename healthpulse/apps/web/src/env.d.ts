/// <reference types="astro/client" />

interface ImportMetaEnv {
	readonly GHOST_URL: string;
	readonly GHOST_API_KEY: string;
	readonly SITE_URL: string;
	readonly PLAUSIBLE_DOMAIN?: string;
}

interface ImportMeta {
	readonly env: ImportMetaEnv;
}
