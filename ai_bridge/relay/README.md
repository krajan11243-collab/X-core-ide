# Optional Remote Relay

This directory documents the deployment boundary for remote AI access.

A phone-local HTTP server cannot be made universally reachable by changing its IP alone. A remote AI needs a reachable HTTPS endpoint. Deploy a relay/reverse proxy that terminates HTTPS and forwards authenticated MCP/REST requests to the X-Core device over a private network.

Required properties:

- HTTPS only
- Bearer/API-key authentication or stronger identity
- No unauthenticated public forwarding
- Preserve POST body and MCP headers
- Preserve `MCP-Protocol-Version` and `Mcp-Session-Id`
- Support streaming responses if enabled by the client
- Restrict origin/host routing to the X-Core bridge

The app itself remains unchanged when the public endpoint is placed in front of the same `/mcp` and `/v1` routes.
