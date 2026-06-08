/**
 * account-status.ts
 *
 * Shows the currently selected account-switcher account label in the status bar.
 * Reads ~/.pi/account-switcher/{accounts.json,state.json} directly so it works
 * independently of the account-switcher runtime's provider-resolution timing.
 *
 * NOTE: Does NOT register /account-current — that command is already provided
 * by the pi-account-switcher package.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { homedir } from "node:os";

const APP_DIR = join(homedir(), ".pi", "account-switcher");
const CONFIG_PATH = join(APP_DIR, "accounts.json");
const STATE_PATH = join(APP_DIR, "state.json");

interface AccountConfig {
	id: string;
	label: string;
	provider: string;
	piAuth?: { provider: string };
}

interface AccountsFile {
	accounts: AccountConfig[];
}

interface StateFile {
	selected: Record<string, string>; // provider -> accountId
}

async function readJson<T>(path: string): Promise<T | null> {
	try {
		return JSON.parse(await readFile(path, "utf8")) as T;
	} catch {
		return null;
	}
}

/** The effective provider key used in state.selected for a given account. */
function accountProvider(account: AccountConfig): string {
	return account.piAuth?.provider ?? account.provider;
}

async function getCurrentAccountLabel(modelProvider?: string): Promise<string | null> {
	const [config, state] = await Promise.all([
		readJson<AccountsFile>(CONFIG_PATH),
		readJson<StateFile>(STATE_PATH),
	]);
	if (!config || !state) return null;

	const selected = state.selected;
	const entries = Object.entries(selected);

	// 1. Direct match on current model provider
	if (modelProvider) {
		const accountId = selected[modelProvider];
		if (accountId) {
			const account = config.accounts.find((a) => a.id === accountId);
			if (account) return account.label;
		}
	}

	// 2. Only one selection in state — use it regardless of provider
	if (entries.length === 1) {
		const accountId = entries[0]![1];
		const account = config.accounts.find((a) => a.id === accountId);
		if (account) return account.label;
	}

	// 3. Multiple selections — match by piAuth.provider or account.provider
	if (modelProvider) {
		for (const [, accountId] of entries) {
			const account = config.accounts.find(
				(a) => a.id === accountId && accountProvider(a) === modelProvider,
			);
			if (account) return account.label;
		}
	}

	return null;
}

export default function (pi: ExtensionAPI) {
	async function refreshStatus(
		ctx: { ui: { setStatus(key: string, value: string | undefined): void }; model?: { provider?: string } | null },
		modelProvider?: string,
	) {
		const provider = modelProvider ?? ctx.model?.provider;
		const label = await getCurrentAccountLabel(provider);
		// Use the same key as the plugin ("account") so we don't add a second entry.
		const thm = ctx.ui.theme;
		ctx.ui.setStatus("account-display", label ? `${thm.fg("accent", "\uF007")} ${thm.fg("muted", label)}` : undefined);
	}

	pi.on("session_start", async (_event, ctx) => {
		await refreshStatus(ctx);
	});

	pi.on("model_select", async (event, ctx) => {
		await refreshStatus(ctx, event.model.provider);
	});
}
