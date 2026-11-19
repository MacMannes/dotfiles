---
name: ado-pr
description: Create an Azure DevOps pull request interactively using Conventional Commits and linked user story IDs. Use whenever the user asks to create, open, or submit a PR.
---

# Interactive Azure DevOps PR Creation

Before calling any Azure DevOps MCP write tool to create a pull request, follow these steps strictly:

1. **Inspect local context first.**
   - Check the current git branch name, status, and recent commits (`git status`, `git log <target>..HEAD`).
   - Extract the user story / work item ID from the branch name or commit messages (e.g. `feature/1234-login` -> `1234`, `AB#1234` in a commit body).
   - Check whether a PR template exists (`.azuredevops/pull_request_template.md`, also try `.azure/` and `docs/`).
   - Parse `git remote -v` for the Azure DevOps organization, project and repository name (e.g. `https://dev.azure.com/<org>/<project>/_git/<repo>`).
   - If the branch is not pushed yet (or is behind its remote), note it; it must be pushed before the PR is created.
   - Fetch the work item (Azure DevOps MCP `wit_work_item`, action `get`, via codemode, server `mcp__azure_devops`) to get its Title and Type for the description.

2. **Ask the user before creating.**
   Use a **single** `ask_user_question` call with defaults the user can accept or change. Put the recommended option first in each question (each question needs at least 2 options):
   - **Work item ID**: detected ID (Recommended). If none was detected, ask for it or offer to search active work items via the MCP.
   - **Conventional Commit type**: inferred from the commits/branch prefix (`feature/` -> `feat`, `bugfix/` -> `fix`, `chore/` -> `chore`), plus alternatives (`refactor`, `docs`, `test`). **Do not use scopes** (write `feat: ...`, not `feat(auth): ...`).
   - **Target branch**: `main` or `develop` based on the repository (Recommended), other candidate as alternative.
   - **Draft status**: "Ready for review (Recommended)" / "Draft".
   - **Push first** (only if the branch is unpushed or ahead): "Yes, push (Recommended)" / "No".
   - Show the drafted title and description in the question text so the user can review them; the user can type changes via "Other".
   - Call out a dirty working directory or unpushed commits explicitly.

3. **Format strictly before creating.**
   - **PR Title:** `<type>: <short description> (#<story-id>)`
     - Strip bracketed prefixes/tags from the work item title (e.g. `[autosuggest]`); they only name the related API and must not appear in the title.
     - Write the description in lowercase imperative, based on the commits and work item title.
     - *Example:* `feat: add missing bus-stop types in subTitle (#1234)`
   - **PR Description:**
     - Include `AB#<story-id>` near the top (e.g. `Resolves AB#1234`) so Azure DevOps auto-links the work item. Always put a blank line directly under the `Resolves AB#<story-id>` line, before the rest of the description.
     - Follow the repo PR template if one exists; otherwise include only a short summary (what and why, from the commits). Do not add a list of changes or testing notes.
     - Hard-wrap nothing inside the description; keep it concise.

4. **Execute & Verify.**
   - If requested, run `git push -u origin <branch>` first.
   - After the user confirms, call the Azure DevOps MCP `repo_pull_request_write` (action `create`, via codemode) with the source branch, target branch, title, description, draft flag, and the work item ID so it is explicitly linked. If the create call does not link the work item, link it with `wit_work_item_link_write` (action `link_to_pull_request`).
   - Return the created PR URL (`https://dev.azure.com/<org>/<project>/_git/<repo>/pullrequest/<id>`).
