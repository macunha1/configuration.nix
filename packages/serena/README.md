# Serena Nix package

This package builds Serena and its Python runtime from the upstream `uv.lock`.
It uses upstream's uv2nix packaging approach and Python 3.11, including its wheel
compatibility and platform dependencies. Starting Serena does not create a uv
environment or resolve Python dependencies.

The `serena` flake input pins the source revision and packaging dependencies.
Its nixpkgs input follows this repository's nixpkgs pin. The package is exported
as `packages.<system>.serena` and `pkgs.my.serena` on supported Darwin and Linux
systems.

## Build and validate

From the repository root:

```sh
nix build --impure "path:$PWD#serena"
nix flake check --impure "path:$PWD"
```

The package check tests immutable configuration, required registration failures,
the packaged MCP CLI, and real Zuban symbol, definition, reference, and rename
operations. Tests use temporary writable state. The flake also checks language
provider ownership and evaluates the configured hosts.

`tests/test_managed_servers.py` is wired to `checks.<system>.serena` through the
package's `tests.managed-servers`. `tests/module-integration.nix` is wired to
`checks.<system>.serena-modules` and evaluates the provider and consumer module
contracts on Darwin and NixOS. The flake supplies the host configurations to
that integration check; the standalone package does not depend on host policy.

The `path:` reference includes newly created package files without requiring
them to be staged in the worktree. Use an isolated staged snapshot when checking
a Git-backed flake before committing new files.

## Home Manager and NixOS integration

[`modules/agents/mcp/serena.nix`](../../modules/agents/mcp/serena.nix) selects
the runtime through `modules.agents.mcp.serena.package`. It generates immutable
YAML settings and JSON registration metadata, sets `SERENA_HOME` to the writable
`storageHome`, and launches the packaged CLI with the managed context.

Language and networking modules own their server packages, exact commands,
runtime tools, environment, settings, and feature gates. The Serena module
consumes their typed contributions; disabling Serena removes its launcher and
MCP contribution while leaving independently enabled providers installed.

The integration options are:

| Option | Purpose |
| --- | --- |
| `modules.agents.mcp.serena.enable` | Install the managed launcher and contribute it to enabled agents |
| `modules.agents.mcp.serena.package` | Select the Serena runtime implementation |
| `modules.agents.mcp.serena.source` | Override the source used by the default package; must include its matching `uv.lock` |
| `modules.agents.mcp.serena.storageHome` | Writable runtime data, caches, and logs |
| `modules.agents.mcp.serena.settings` | Declarative session settings; language-server selection remains provider-owned |

The package can also be selected explicitly with a source override:

```nix
modules.agents.mcp.serena.package = pkgs.my.serena.override {
  serenaSource = myPinnedSerenaSource;
};
```

The source and its lock file form one compatibility unit. Changing the revision
requires rerunning the package tests and host checks.

## Package-specific compatibility

The package contains a loader patch for `SERENA_CONFIG_FILE`. An explicit file
is read without permission changes or writes; a missing explicit file fails.
Project registration is session-local in this mode. Runtime state remains under
`SERENA_HOME`; authentication material must not be placed in public Nix store
settings. Upstream's default mutable configuration mode remains available when
the environment variable is absent.

The packaged SolidLSP extension reads `SERENA_LANGUAGE_SERVERS` and registers
the selected commands through upstream's entry-point interface. It preserves
native adapter behavior and supplies generic LSP initialization for selected
servers without a native adapter. All registrations are prepared before the
registry changes. Invalid required registrations stop startup instead of
allowing an unintended built-in implementation or installer to run.

The module supplies these environment variables and generated files. The package
does not embed a host's language selection or rewrite a global Serena config.
Run the managed launcher from the project to analyze; project-specific server
keys remain in `.serena/project.yml`.
