---
name: ado-branch
description: Create a git branch from an Azure Boards work item ID. Use whenever the user asks to create or start a branch for a user story, bug, or AB# ID.
---

# Create Git Branch from Azure Boards Work Item

When the user asks to create a branch for a work item (e.g., `AB#12345` or `12345`), follow these steps:

1. **Fetch work item details.**
   - Call the Azure DevOps MCP `work-items` tool (via codemode, server `mcp__azure_devops`) with `project: "RCREIZ"` (work items always live in RCREIZ, not the project from the git remote) to retrieve the work item's **Type** (`User Story`, `Bug`, etc.) and **Title**.

2. **Format the branch name.**
   - Map the work item type to a prefix:
     - `User Story` / `Feature` -> `feature/`
     - `Bug` -> `bugfix/`
     - `Task` / `Chore` -> `chore/`
   - Strip any bracketed prefix/tags from the title (e.g. `[autosuggest]`); they only name the related API and must not appear in the branch name.
   - Convert the work item title into a lowercase, hyphen-separated slug (remove special characters, max ~40 characters).
   - Format strictly as: `<prefix><id>-<slug>`
     *Example:* `feature/12345-add-sso-login`

3. **Confirm and create.**
   - Check that the working directory is clean (`git status`) and verify the base branch (`main` or `develop`).
   - Use a **single** `ask_user_question` call with defaults the user can accept or change. Put the recommended option first in each question:
     - Branch name: proposed name (Recommended), plus an alternative if useful (user can type a custom name via "Other").
     - Base branch: detected base (Recommended: `main` or `develop`), other candidate as alternative.
     - Pull base first: "Yes, pull first (Recommended)", "No".
   - If the working directory is dirty or the base branch is ambiguous, call this out explicitly in the question.
   - After the answers, if pulling: `git checkout <base> && git pull`. Then run `git checkout -b <branch-name>`.
