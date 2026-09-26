# X-Core AI Bridge — Universal Connector

X-Core exposes a permission-gated project-control bridge for AI clients.

## Discovery

- `GET /.well-known/xcore-bridge.json`
- `GET /v1/discovery`
- MCP endpoint: `POST /mcp`
- REST tools: `GET /v1/tools`

## Transport

MCP is exposed over HTTP using the Streamable HTTP pattern. The bridge accepts the established initialize handshake and also answers the modern `server/discover` probe. Older clients can continue using `initialize`, while newer clients can negotiate protocol capabilities.

## Authentication

Protected endpoints require:

``
Authorization: Bearer <X-CORE-API-KEY>
```

Never publish the API key in source control or public documentation. Regenerate it if it has been exposed.

## Connection modes

### Local

Use `http://127.0.0.1:<port>/mcp` when the AI client runs on the same device/process environment.

### LAN

Enable LAN mode in X-Core. The bridge binds to IPv4 interfaces and exposes the device IP. The AI client must be on a network that can route to the device.

### Tailscale / private mesh

Use the device's mesh IP or DNS name when the AI client can reach the same private mesh. The bridge itself does not depend on one fixed IP address.

### Public/remote

A private phone IP cannot be reached directly from an unrelated cloud AI. For a truly remote deployment, put the bridge behind an authenticated HTTPS reverse proxy or a relay that forwards requests to the phone. X-Core's protocol/discovery layer is designed so the same MCP endpoint can be used after such a transport is added.

## Recommended client behavior

1. Fetch discovery metadata.
2. Use the advertised MCP endpoint.
3. Authenticate with Bearer API key.
4. Prefer modern MCP discovery when supported.
5. Fall back to the established initialize handshake.
6. Call `tools/list`.
7. Use only tools allowed by X-Core permissions.

The bridge reuses X-Core's existing project, workspace, runtime, build, terminal and Git services; it does not replace the existing AI chat/provider implementation.
