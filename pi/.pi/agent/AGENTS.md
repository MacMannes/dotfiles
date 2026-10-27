# Commit messages

- Do not use scopes in conventional commit messages, e.g. write `chore: ...`, not `chore(renovate): ...`.

# Output formatting

- Hard-wrap prose in responses at 100 columns. Do not wrap code, code blocks, or file contents.
- Be concise. Keep summaries short; don't narrate or show scripts/commands used for edits unless asked.
- Edit files with the edit tool (or write for new files). Don't use python/sed/shell scripts to modify files.

# Code design

- Always follow the 9 Rules of Object Calisthenics when writing or modifying code:
  1. One level of indentation per method.
  2. Don't use the `else` keyword.
  3. Wrap all primitives and strings.
  4. First-class collections (wrap collections in their own class).
  5. One dot per line (Law of Demeter).
  6. Don't abbreviate.
  7. Keep all entities small.
  8. No classes with more than two instance variables (only apply when really appropriate).
  9. No getters/setters/properties.

# Types

- Use Zod to define types (schemas) whenever input or output is JSON; derive TypeScript types with `z.infer`.
