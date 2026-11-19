---
name: ado-story
description: Create an Azure Boards User Story interactively. Use whenever the user asks to create, draft, or add a new user story, ticket, or backlog item.
---

# Interactive Azure Boards User Story Creation

Before calling any Azure DevOps MCP write tool to create a work item, follow these steps strictly:

1. **Gather board context first.**
   - Use the Azure DevOps MCP `core` and `work` tools (via codemode, server `mcp__azure_devops`) to check available projects, teams, current sprint/iteration paths, and area paths so you can offer valid defaults.
   - Check if the user already provided a rough feature idea or bug/task context in the conversation.
   - Determine the project name from the directory name of the git root (`basename "$(git rev-parse --show-toplevel)"`), e.g. `autosuggest-api` or `reisinfo`. If not in a git repo, use the current directory name.
   - Look up the work item field for **Component** (e.g. via the MCP work item type/field tools) to get its reference name and allowed values.

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
   - Only after the user confirms, use the Azure DevOps MCP `wit_work_item` tool (via codemode) to create the **User Story** (`System.WorkItemType = "User Story"`), with the title (including the `[<project-dir-name>]` prefix) and the confirmed Component (default `Backend`), the confirmed area path, the iteration path (only if the current iteration was chosen) and `System.AssignedTo` (only if assignment to @me was chosen).
   - If a Parent ID was provided, link it as a parent relation.
   - Return the created **Work Item ID (`AB#<id>`)** and direct URL (`https://dev.azure.com/<org>/<project>/_workitems/edit/<id>`) so it can be used immediately in git branches (`ado-branch`) or PRs (`ado-pr`).
