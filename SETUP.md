# HZ-BIM — Setup & GitHub Guide

## Quick Setup

### 1. Set API Key (Optional)
```bash
cd revit-mcp-server
copy .env.example .env
# Edit .env and add your key if you wish to use server-side AI features
```

### 2. Run Local Test
```bash
cd revit-mcp-server
npm run build
node build/tests/test-startup.js
```

### 3. Install Plugin to Revit
 Download **`HZ-BIM-Setup.exe`** from [GitHub Releases](https://github.com/hazzem0/HZ-BIM/releases) and run as Administrator.

Or build from source: compile `installer/setup.iss` with [Inno Setup](https://jrsoftware.org/isinfo.php).

### 4. Connect an AI Client

Claude setup is automatic, in three layers:

1. **Installer** — registers HZ-BIM in Claude Desktop, Claude Code, Cursor, Windsurf and VS Code (real JSON merge via `configure-claude.cjs`, repairs stale entries from previous installs). When the installer is elevated it passes `--all-users`, because the elevated process runs as whichever account answered the UAC prompt — configuring only that profile would miss the person actually installing. Profiles with no MCP client are left untouched.
2. **Revit plugin self-heal** — every time Revit starts, the plugin silently validates the Claude configs and repairs any entry whose paths no longer exist (e.g. the install folder moved). A `.hzbim-backup` copy is written before any change.
3. **"Connect Claude" ribbon button** — runs the same validate/repair on demand and reports per-client status.

You can also run the repair manually at any time:
```bash
node "C:\Program Files\HzBim\server\scripts\configure-claude.cjs"
# or from the repo (dev):
node revit-mcp-server/scripts/configure-claude.cjs
```

Run it **as the signed-in user, not elevated** — it configures the profile of whoever runs it. Useful flags: `--all-users` scans every profile on the machine, `--home <profile-dir>` targets one.

After any config change, fully restart Claude (File → Exit, then reopen). For other clients, use the configurations below.

#### Claude Desktop
**Config file**: `%APPDATA%\Claude\claude_desktop_config.json`
```json
{
  "mcpServers": {
    "HZ-BIM": {
      "command": "C:\\Program Files\\HzBim\\nodejs\\node.exe",
      "args": ["C:\\Program Files\\HzBim\\server\\build\\index.js"],
      "env": {}
    }
  }
}
```

#### Cursor IDE
**Config file**: `~/.cursor/mcp.json` or **Settings → Features → MCP → Add New MCP Server**
```json
{
  "mcpServers": {
    "HZ-BIM": {
      "command": "C:\\Program Files\\HzBim\\nodejs\\node.exe",
      "args": ["C:\\Program Files\\HzBim\\server\\build\\index.js"],
      "env": {}
    }
  }
}
```

#### Windsurf
**Config file**: `%USERPROFILE%\.codeium\windsurf\mcp_config.json`
```json
{
  "mcpServers": {
    "HZ-BIM": {
      "command": "C:\\Program Files\\HzBim\\nodejs\\node.exe",
      "args": ["C:\\Program Files\\HzBim\\server\\build\\index.js"],
      "env": {}
    }
  }
}
```

#### VS Code (Copilot / MCP Extension)
**Config file**: `.vscode/mcp.json` (workspace) or Command Palette → "MCP: Open User Configuration"
```json
{
  "servers": {
    "HZ-BIM": {
      "type": "stdio",
      "command": "C:\\Program Files\\HzBim\\nodejs\\node.exe",
      "args": ["C:\\Program Files\\HzBim\\server\\build\\index.js"]
    }
  }
}
```

#### Gemini CLI
**Config file**: `~/.gemini/settings.json`
```json
{
  "mcpServers": {
    "HZ-BIM": {
      "command": "C:\\Program Files\\HzBim\\nodejs\\node.exe",
      "args": ["C:\\Program Files\\HzBim\\server\\build\\index.js"]
    }
  }
}
```

#### Developer (from source)
```json
{
  "mcpServers": {
    "HZ-BIM": {
      "command": "node",
      "args": ["<repo-path>/revit-mcp-server/build/index.js"],
      "env": {}
    }
  }
}
```

---

## GitHub Repository Setup

Run these commands to create and push the repo:

```bash
# 1. Login to GitHub (one time)
gh auth login --web --git-protocol https

# 2. Push to existing repo
cd "path\to\HZ-BIM"   # wherever you cloned the repo
git push origin main

# 3. Create a new release
 gh release create v2.8.0 "HZ-BIM-Setup.exe" --title "HZ-BIM v2.8.0" --notes "First HZ-BIM release"
```

### After GitHub is set up:
Update `UpdateChecker.cs` with your GitHub username:
```csharp
private const string GITHUB_OWNER = "hazzem0";
private const string GITHUB_REPO = "HZ-BIM";
```

---

## Test Commands

```bash
# Smoke test (no Revit needed)
node build/tests/test-startup.js

# Socket integration test (Revit must be open with MCP started)
node build/tests/test-socket.js
```
