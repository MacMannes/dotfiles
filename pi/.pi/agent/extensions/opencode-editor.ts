/**
 * Opencode-style editor: panel background box with a colored left accent stripe.
 *
 *   ▎                                                               
 *   ▎  > type here                                                  
 *   ▎                                                               
 */

import { CustomEditor, type ExtensionAPI } from "@mariozechner/pi-coding-agent";
import type { AssistantMessage } from "@mariozechner/pi-ai";
import { visibleWidth, truncateToWidth } from "@mariozechner/pi-tui";

export default function (pi: ExtensionAPI) {
    pi.on("session_start", (_event, ctx) => {
        class OpencodeEditor extends CustomEditor {
            render(width: number): string[] {
                const innerWidth = width - 1;
                const lines = super.render(innerWidth);
                const thm = ctx.ui.theme;

                // Extract the raw ANSI background-start code from the theme so we
                // can re-apply it after any \e[0m reset that appears mid-line
                // (the cursor line typically contains one, causing a transparent tail).
                const sentinel = "\x01";
                const wrapped = thm.bg("userMessageBg", sentinel);
                const idx = wrapped.indexOf(sentinel);
                const bgCode = idx >= 0 ? wrapped.slice(0, idx) : "";

                const applyBg = (line: string): string => {
                    const contentWidth = visibleWidth(line);
                    const padding = " ".repeat(Math.max(0, innerWidth - contentWidth));
                    // Re-apply bg after every SGR reset so the cursor highlight
                    // doesn't leave a transparent tail on the typing line.
                    const patched = (line + padding).replace(/\x1b\[0?m/g, (m) => m + bgCode);
                    return bgCode + patched;
                };

                return lines.map((line, i) => {
                    const stripe = thm.fg("accent", "▎");

                    // Top and bottom borders → blank background lines (no ─ characters)
                    if (i === 0 || i === lines.length - 1) {
                        return stripe + thm.bg("userMessageBg", " ".repeat(innerWidth));
                    }

                    return stripe + applyBg(line);
                });
            }
        }

        ctx.ui.setEditorComponent((tui, theme, kb) => new OpencodeEditor(tui, theme, kb));

        ctx.ui.setFooter((tui, theme, footerData) => {
            const dispose = () => {};
            return {
                invalidate() {},
                dispose,
                render(width: number): string[] {
                    const thm = ctx.ui.theme;
                    const model = ctx.model?.id ?? "no model";
                    const thinking = pi.getThinkingLevel();
                    const cwd = ctx.cwd;
                    const cwdLabel = cwd.split("/").filter(Boolean).pop() ?? cwd;

                    let input = 0, output = 0, cost = 0;
                    for (const e of ctx.sessionManager.getBranch()) {
                        if (e.type === "message" && e.message.role === "assistant") {
                            const m = e.message as AssistantMessage;
                            input += m.usage.input;
                            output += m.usage.output;
                            cost += m.usage.cost.total;
                        }
                    }

                    const usage = ctx.getContextUsage();
                    const pct = usage?.percent != null ? `${Math.round(usage.percent)}%` : null;
                    const fmt = (n: number) => n < 1000 ? `${n}` : `${(n / 1000).toFixed(1)}k`;

                    const parts: string[] = [
                        thm.fg("accent", model),
                        thm.fg("muted", thinking),
                        thm.fg("dim", cwdLabel),
                        thm.fg("dim", `↑${fmt(input)} ↓${fmt(output)}`),
                        ...(pct ? [thm.fg("dim", `ctx ${pct}`)] : []),
                        thm.fg("dim", `$${cost.toFixed(3)}`),
                    ];

                    // Append any statuses registered via ctx.ui.setStatus()
                    // Values are passed through as-is so callers can apply their own colors.
                    // Skip "account" — the pi-account-switcher plugin sets that with an emoji;
                    // account-status.ts writes the same info under "account-display" with a
                    // Nerd Font icon and proper colors instead.
                    for (const [key, value] of footerData.getExtensionStatuses()) {
                        if (key === "account") continue;
                        parts.push(value);
                    }

                    const line = " " + parts.join(thm.fg("dim", " · "));
                    return [truncateToWidth(line, width)];
                },
            };
        });
    });
}
