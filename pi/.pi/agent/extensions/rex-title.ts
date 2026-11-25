/**
 * Rex Beta ignores OSC terminal titles for its tab names, so when running
 * inside Rex (TERM_PROGRAM=rex) mirror pi's title into the Rex window label
 * with `rex window rename`.
 */

import { execFile } from "node:child_process";
import path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const insideRex = process.env.TERM_PROGRAM === "rex" && Boolean(process.env.REX_BLOCK);

function run(args: string[]): Promise<string> {
	return new Promise((resolve) => {
		execFile("rex", args, { timeout: 5000 }, (error, stdout) => resolve(error ? "" : stdout));
	});
}

async function findWindowId(): Promise<string> {
	const output = await run(["block", "inspect", process.env.REX_BLOCK!, "--json"]);
	try {
		return JSON.parse(output).block.window_id ?? "";
	} catch {
		return "";
	}
}

export default function (pi: ExtensionAPI) {
	if (!insideRex) return;

	let windowId: Promise<string> | undefined;
	let lastTitle = "";

	function buildTitle(prefix = ""): string {
		const directory = path.basename(process.cwd());
		return `${prefix}${directory}`;
	}

	async function rename(title: string) {
		if (title === lastTitle) return;
		lastTitle = title;
		windowId ??= findWindowId();
		const id = await windowId;
		if (!id) return;
		await run(["window", "rename", id, title]);
	}

	pi.on("session_start", async () => {
		await rename(buildTitle());
	});

	pi.on("agent_start", async () => {
		await rename(buildTitle("⏳ "));
	});

	pi.on("agent_settled", async () => {
		await rename(buildTitle());
	});
}
