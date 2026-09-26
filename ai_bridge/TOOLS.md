# X-Core AI Bridge Tool Contract

Each MCP tool maps to the corresponding REST operation.

- read_file -> /v1/files/read
- write_file -> /v1/files/write
- create_file -> /v1/files/create
- delete_file -> /v1/files/delete
- rename_file -> /v1/files/rename
- list_files -> /v1/files/list
- search_code -> /v1/code/search
- list_projects -> /v1/project/list
- create_project -> /v1/project/create
- open_project -> /v1/project/open
- delete_project -> /v1/project/delete
- build_project -> /v1/build
- install_dependency -> /v1/dependencies/install
- remove_dependency -> /v1/dependencies/remove
- git_status -> /v1/git/status
- git_diff -> /v1/git/diff
- git_commit -> /v1/git/commit
- git_pull -> /v1/git/pull
- git_push -> /v1/git/push
- run_command -> /v1/terminal/run

The bridge intentionally keeps this tool list separate from the existing AI provider logic.
