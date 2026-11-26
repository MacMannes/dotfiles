---
name: ado-story
description: Create an Azure Boards User Story interactively. Use whenever the user asks to create, draft, or add a new user story, ticket, or backlog item.
---

# Interactive Azure Boards User Story Creation

Before calling any Azure DevOps MCP write tool to create a work item, follow these steps strictly:

1. **Gather board context first.**
   - **Azure DevOps project**: always `RCREIZ` (NOT the project from the git remote URL, which is e.g. `NSAPP` and has no `User Story` type, so creation fails with a vague "Work item was not created"). Pass `project: "RCREIZ"` to every MCP call.
   - Use the MCP `core` and `work` tools (via codemode, server `mcp__azure_devops`) to check teams, current sprint/iteration paths and area paths so you can offer valid defaults. Known defaults: area path `RCREIZ\NSAPP`; iteration paths look like `RCREIZ\2026\26.4\26.4.5`.
   - Check if the user already provided a rough feature idea or bug/task context in the conversation.
   - Determine the repo name (used in the title prefix) from the directory name of the git root (`basename "$(git rev-parse --show-toplevel)"`), e.g. `autosuggest-api` or `reisinfo`. If not in a git repo, use the current directory name.
   - The **Component** field reference name is `Custom.Component` (default value `Backend`).

2. **Ask the user before creating.**
   Draft a clean proposal based on what the user already shared, then use a **single** `ask_user_question` call to confirm or fill in missing details. Put the recommended option first in each question (each question needs at least 2 options; `ask_user_question` allows at most 4 questions per call, so combine related items, such as title and description, into one question and ask optional items like story points, priority and parent in a single question or skip them) and show the drafted title and description in the question text so the user can review them; the user can type changes via "Other":
   - **Title**: `[<project-dir-name>] <short, action-oriented summary>`, e.g. `[autosuggest-api] Add missing bus-stop types in subTitle`. The bracketed prefix is always the project directory name.
   - **Component**: "Backend (Recommended)" by default, plus other allowed values as alternatives.
   - **Description** (a short, plain description of what needs to be done and why; do not use the "As a [role], I want..." format)
   - **Area Path** (suggest the team's default area path)
   - **Current iteration**: "Yes, current iteration (Recommended)" / "No, leave in backlog". Look up the current sprint path via the MCP `work` tool and name it in the question.
   - **Assign to me**: "Yes, assign to @me (Recommended)" / "No, leave unassigned". Resolve @me to the authenticated user's unique name (e.g. `System.AssignedTo` = `andre.mathlener@nslogin.nl`).
   - **Story Points / Effort & Priority** (optional: "Leave blank (Recommended)" / "Estimate now")
   - **Parent Feature / Epic ID** (optional: "None (Recommended)" / "Link a Feature"; offer to search existing Features via the MCP if they want to link)

3. **Create & Verify.**
   - Only after the user confirms, use the Azure DevOps MCP `wit_work_item_write` tool (action `create`, project `RCREIZ`, via codemode) to create the **User Story** (`System.WorkItemType = "User Story"`), with the title (including the `[<repo-dir-name>]` prefix), `Custom.Component` (default `Backend`), the confirmed area path, the iteration path (only if the current iteration was chosen) and `System.AssignedTo` (only if assignment to @me was chosen). Use `format: "Markdown"` for the description.
   - If creation fails with "Work item was not created", first verify the project is `RCREIZ`.
   - If a Parent ID was provided, link it as a parent relation.
   - Return the created **Work Item ID (`AB#<id>`)** and direct URL (`https://dev.azure.com/ns-topaas/RCREIZ/_workitems/edit/<id>`) so it can be used immediately in git branches (`ado-branch`) or PRs (`ado-pr`).
