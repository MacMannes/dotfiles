/**
 * Sets the terminal default background color via OSC 11 on session start,
 * and restores it when the session ends.
 *
 * This fills any unpainted areas (chat messages, whitespace between blocks)
 * with a solid color instead of showing through terminal transparency.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const BG_COLOR = "#0a0a0a";

// OSC 11 sets the terminal default background color.
// OSC 111 resets it back to the terminal's own default.
const set = `\x1b]11;${BG_COLOR}\x1b\\`;
const reset = `\x1b]111;\x1b\\`;

export default function (pi: ExtensionAPI) {
    pi.on("session_start", () => {
        process.stdout.write(set);
    });

    pi.on("session_shutdown", () => {
        process.stdout.write(reset);
    });
}
