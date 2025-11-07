# Git Latest Updates

An Azure Functions (PowerShell) HTTP-triggered endpoint that aggregates `.md` (Markdown) file diffs from all commits in a GitHub repository since a given ISO8601 date. It powers an MCP (Model Context Protocol) server integration so you can ask your AI assistant inside VS Code for "latest markdown changes" without manually browsing GitHub.

## Aim of the Project
- Provide a lightweight, serverless way to fetch and consolidate only Markdown changes across recent commits.
- Expose a single POST endpoint you can call (or wrap via MCP) to summarize evolving documentation or notes.
- Enable secure invocation using a GitHub Personal Access Token (PAT) and a Functions host key.

## Azure Function Overview
### Trigger & Binding
Defined in `get-latest-updates/function.json`:
- HTTP trigger (`post` only), auth level `function` (requires a function key).
- Output binding returns plain text.

### Request Shape
Query parameters (required):
- `repo`: GitHub repository in `owner/name` form, e.g. `weslbo/git-latest-updates`.
- `date`: ISO8601 timestamp or date (e.g. `2025-11-01T00:00:00Z`). GitHub accepts date/time; providing midnight UTC is typical.

Headers (required):
- `git-token`: Your GitHub PAT (needs `repo` scope for private repos; no extra scopes required for public repos).

Authentication (Functions key):
- Supply the Azure Functions key either via the standard `x-functions-key` header or by using the `?code=...` query string when calling the deployed endpoint.

### Execution Flow (`get-latest-updates/run.ps1`)
1. Validates presence of `repo` and `date` query params and `git-token` header.
2. Calls GitHub `/commits?since=DATE` to list commits since the timestamp.
3. For each commit: fetch commit details; filter changed files to those ending in `.md`.
4. If markdown files changed, re-fetch the commit using the `Accept: application/vnd.github.v3.diff` media type to get the unified diff.
5. Aggregates diffs (separated by `---`) into one text payload.
6. Returns `200 OK` with `text/plain` body of concatenated diffs. (Commits without markdown changes are skipped.)

### Local Development
Prerequisites:
- Node.js (only if you plan to experiment with MCP locally, not required just to run the function).
- Azure Functions Core Tools (v4) installed.
- PowerShell 7.4 runtime (configured in `local.settings.json`).

Steps:
1. Populate `AzureWebJobsStorage` in `local.settings.json` (Use Azurite or a real storage account—empty string will block some features but basic HTTP trigger may still start).
2. Start from VS Code: Run the task `func: host start` (background) or press `F5` if the Functions extension is installed.
3. Invoke locally: `curl -X POST "http://localhost:7071/api/get-latest-updates?repo=OWNER/REPO&date=YYYY-MM-DDTHH:MM:SSZ" -H "git-token: $GIT_TOKEN" -H "x-functions-key: <your local key if required>"`

### Deployment via VS Code
1. Install VS Code Azure Functions extension & sign in to Azure.
2. Open the workspace root (`git-latest-updates`).
3. Use Command Palette: `Azure Functions: Deploy to Function App` (or create a new Function App first: runtime = PowerShell, version = 7.4).
4. After deployment, retrieve the function key: In Azure Portal -> Function App -> Functions -> `get-latest-updates` -> `Function Keys`.
5. Store the key locally (e.g., as `X_FUNCTIONS_KEY`) for MCP usage and/or include `?code=FUNCTION_KEY` in requests.
6. Test deployed endpoint:
```bash
curl -X POST "https://<your-app>.azurewebsites.net/api/get-latest-updates?repo=weslbo/git-latest-updates&date=2025-11-01T00:00:00Z" \
  -H "git-token: $GIT_TOKEN" \
  -H "x-functions-key: $X_FUNCTIONS_KEY"
```

## MCP Configuration (`.vscode/mcp.json`)
The MCP file makes the function callable as a structured tool within compatible VS Code AI integrations.

Key parts:
- `servers.github-diff`: Defines a local command-based MCP server.
- Uses `npx @ivotoby/openapi-mcp-server` to spin up a generic OpenAPI-driven MCP server wrapper.
- `--api-base-url`: Points to the deployed Azure Functions base URL (`https://git-latest-updates.azurewebsites.net/api`).
- `--spec-inline`: Inline OpenAPI 3 spec (mirrors `spec.json`) defining a single path `/get-latest-updates` with a POST operation and its query parameters.
- `--headers`: Declares dynamic headers with template substitution: `x-functions-key:${X_FUNCTIONS_KEY}` and `git-token:${GIT_TOKEN}`.
- `env`: Maps environment variables that must be available in your VS Code session so the MCP server can inject them into headers.

Environment variables required:
- `X_FUNCTIONS_KEY`: Azure Function key for auth (function-level or host key).
- `GIT_TOKEN`: GitHub PAT for API access.

This setup lets an AI model call the tool without exposing raw secrets in the spec.

## Sample Prompts (VS Code / MCP)
Use these prompts in your AI chat once the MCP server is active:
1. "Use the `github-diff` tool to fetch markdown changes in `weslbo/git-latest-updates` since 2025-11-01 and summarize them."
2. "Call `github-diff` for repo `OWNER/REPO` since `2025-10-15T00:00:00Z` and list changed markdown filenames."
3. "Fetch diffs for `my-org/docs-repo` since last Monday; highlight additions only."
4. "Invoke `github-diff` and then condense the returned unified diff into bullet points of documentation changes."
5. "Compare markdown changes in `OWNER/REPO` over the past 3 days; summarize per file."

## Direct Usage (cURL)
```bash
export GIT_TOKEN=ghp_yourtoken
export SINCE="2025-11-01T00:00:00Z"
export REPO="weslbo/git-latest-updates"
export X_FUNCTIONS_KEY=your_functions_key

curl -X POST "https://git-latest-updates.azurewebsites.net/api/get-latest-updates?repo=$REPO&date=$SINCE" \
  -H "git-token: $GIT_TOKEN" \
  -H "x-functions-key: $X_FUNCTIONS_KEY" \
  -o diffs.txt
```

## Quickstart Checklist
1. Get GitHub PAT -> set `GIT_TOKEN`.
2. Deploy (or run locally) the Azure Function.
3. Retrieve function key -> set `X_FUNCTIONS_KEY`.
4. Confirm endpoint works with `curl`.
5. Ensure `.vscode/mcp.json` present and environment variables exported.
6. Start AI session in VS Code and issue sample prompt.

## Security Notes
- Limit PAT scopes; use separate token for this integration if possible.
- Rotate `X_FUNCTIONS_KEY` when needed (Azure Portal).
- Avoid logging secrets: current script only logs minimal status.

## Future Enhancements
- Support pagination for large commit sets.
- Add optional file extension filter parameter.
- Provide JSON response variant with structured per-file diffs.

---
Feel free to open issues or PRs for enhancements.
