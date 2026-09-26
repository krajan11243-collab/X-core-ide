# X-Core AI Bridge API

Base URL:
http://127.0.0.1:8765/v1

MCP:
http://127.0.0.1:8765/mcp

Authentication:
Authorization: Bearer <X-CORE-KEY>

## REST endpoints

GET /tools
POST /session/connect

POST /project/list
POST /project/create
POST /project/open
POST /project/delete

POST /files/list
POST /files/read
POST /files/create
POST /files/write
POST /files/delete
POST /files/rename

POST /code/search

POST /dependencies/install
POST /dependencies/remove

POST /build

POST /git/status
POST /git/diff
POST /git/commit
POST /git/pull
POST /git/push

POST /terminal/run

## Example

POST /files/read

{
  "path": "lib/main.dart"
}

Response:

{
  "success": true,
  "path": "...",
  "content": "..."
}

The API is implemented inside the X-Core application and delegates project operations to existing X-Core services.
