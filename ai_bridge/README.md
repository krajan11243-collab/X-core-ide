# X-Core AI Bridge

The AI Bridge is an additive control layer inside X-Core IDE. It does not replace the existing AI providers, local inference, editor, workspace, project wizard, terminal, build, or Git logic.

## Runtime flow

AI client -> MCP/REST -> X-Core AI Bridge -> authentication -> permission check -> existing X-Core services.

## User settings

Settings -> AI Bridge

The screen exposes:
- Bridge on/off
- LAN access
- port
- REST endpoint
- MCP endpoint
- API key
- full project access
- individual permissions
- connection test

## Control surface

Projects: list/create/open/delete.
Files: list/read/create/write/delete/rename.
Code: recursive search.
Dependencies: install/remove through the project's package manager.
Build: start an existing X-Core build.
Git: status/diff/commit/pull/push.
Terminal: execute a project command.

## Compatibility

REST is available for custom API clients. MCP is available for clients that support MCP tools. External AI clients still need their own support for custom tools, MCP, or API integrations.

## Security model

The Bridge is loopback-only by default. LAN access is opt-in. Every protected request requires the generated bearer key. Project/file paths are restricted to the active X-Core workspace. Permissions can be granted individually or through Full Project Access.
