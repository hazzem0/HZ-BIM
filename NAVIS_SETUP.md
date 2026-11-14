# HZ-BIM Navisworks — Setup (ADDITIVE, Revit untouched)

Revit connection is unchanged (port 8080 + `service.json`).
Navisworks Manage runs in parallel (port **8091** + `service-navis.json`).

## 1. Install Navisworks plugin

Navisworks is NOT like Revit: Revit loads add-ins from `%APPDATA%` (no admin), but Navisworks
only loads a .NET plugin from a subfolder of its own install folder under Program Files,
and the subfolder name must equal the assembly name:

```
C:\Program Files\Autodesk\Navisworks Manage <year>\Plugins\HzBimNavisPlugin\HzBimNavisPlugin.dll
```

Writing there needs admin rights. The installer (`installer/setup.iss`) handles it with ONE UAC
prompt for all years. Each Manage year needs its own DLL (API is strong-named per year):

```
dotnet build navis-mcp-plugin/HzBimNavisPlugin/HzBimNavisPlugin.csproj -c Release -p:NavisYear=2024
→ navis-mcp-plugin/HzBimNavisPlugin/bin/N2024/Release/net48/HzBimNavisPlugin.dll
```

Then open Navisworks Manage → HZ-BIM tab → **Start HZ-BIM** (should read HZ-BIM ON).

## 2. Claude MCP (Claude Desktop)

File: `%APPDATA%\Claude\claude_desktop_config.json` — copy from
`revit-mcp-server/mcp-config.claude.json`. Restart Claude Desktop.
`HZ-BIM` = all tools (Revit, and Navisworks too). `HZ-BIM-Navis` (`HZBIM_SCOPE=navis`) = only the
`navis_*` and Revit↔Navis bridge tools, so a client with both entries doesn't list the Revit tools twice.

## 3. ChatGPT MCP (ChatGPT Desktop ≥ 2025 MCP support)

Settings → Apps → Add MCP Server → paste contents of
`revit-mcp-server/mcp-config.chatgpt.json`. Same `build/index.js` binary
serves both targets; `navis_*` tools appear automatically.

## 4. Integrated chat + API key (in-Navisworks)

Same providers as Revit: `gemini / openai / deepseek / perplexity /
openrouter / groq / cerebras / ollama` (`navis-mcp-plugin/.../AI/NavisAISettings.cs`).
Paste the SAME key as Revit into HZ-BIM → Settings in Navisworks.
Stored separately at `%AppData%\Autodesk\Navisworks\Addins\HzBim\navis-settings.json`
so Revit settings are never touched.

Server-side AI tools (same `GEMINI_API_KEY`): `navis_ai_chat`,
`navis_ai_analyze_clashes`, `navis_ai_generate_plugin_code`.

## 5. Verify

- `navis_connection_status` → `{ target: navisworks, host, port, source }`
- `navis_get_model_info` with Manage open → model info
- Without Manage running → clear "service is probably not running" error (Revit tools unaffected)

## 6. Typical federated flow (Claude / ChatGPT)

`export_to_nwc` (Revit) → `navis_append_file` → `navis_run_clash_test` →
`navis_get_clash_results` → `navis_ai_analyze_clashes`
