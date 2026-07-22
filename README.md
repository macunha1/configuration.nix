# configuration.nix

NixOS Configuration as Code for a fully modularized fleet setup. Pick and fit
together the desired pieces, then enable or disable modules on demand for a
clean environment.

The flake is intentionally small at the top level: `flake-parts` owns
system-indexed outputs, while host and module helpers keep the NixOS and Darwin
interfaces close without hiding real platform differences.

## What This Manages

- Desktop stack: Ly display manager, AwesomeWM, Alacritty, Tmux, Rofi, Chromium
- Shell stack: ZSH, Git, GnuPG, Pass, FZF, Direnv, ASDF
- Development tools: Python, Go, Rust, Node, Java, Elixir, Lua, Ruby, Android,
  Flutter, C/C++
- Cloud and infra tools: Kubernetes, Helm, Terraform, AWS, GCP, Ansible, Vagrant
- Local packages and overlays under `packages/` and `overlays/`

## Layout

```text
flake.nix              flake-parts entry point and public outputs
default.nix            shared NixOS base module
hosts/                 machine-specific NixOS and Home Manager entries
modules/               feature modules, disabled by default unless selected
lib/                   repo helpers for host discovery, XDG paths, platform targets
packages/              custom packages exposed as flake packages and pkgs.my
config/                static config files linked by modules
tests/                 NixOS test helpers
```

## Flake Outputs

Common outputs:

```sh
nix flake show
```

NixOS systems:

```sh
nix build .#nixosConfigurations.<name>.config.system.build.toplevel --impure
```

macOS Home Manager:

```sh
nix eval .#homeConfigurations.<name>.activationPackage.drvPath --impure
```

Development shell:

```sh
nix develop
```

Unified local activation:

```sh
nix run .#activate
```

## Usage

Show available Make targets:

```sh
make
```

Build a NixOS host:

```sh
make build NIXOS_HOST=<name>
```

Switch a NixOS host:

```sh
make switch NIXOS_HOST=<name>
```

Activate the local configuration for the current OS:

```sh
make activate
```

Install a NixOS host from an installer environment:

```sh
make install-nixos NIXOS_HOST=<name> MOUNT_PATH=/mnt
```

Switch the macOS Home Manager profile:

```sh
make install-darwin HOME_CONFIG=<name>
```

The generic install target detects the current OS:

```sh
make install
```

## Module Conventions

Modules should keep shared knowledge in local attrsets and use the repo helpers
instead of repeating Linux/Darwin branches.

Use `xdgPaths` from `lib/paths.nix` for paths:

```nix
xdg = (lib.my or (import ../../lib/paths.nix { inherit lib; })).xdgPaths {
  inherit config isDarwin;
};

toolEnvVars = {
  TOOL_CONFIG = xdg.shell.config "tool/config";
  TOOL_CACHE = xdg.shell.cache "tool/cache";
  TOOL_DATA = xdg.shell.data "tool";
};
```

Use `platformPackages`, `platformEnv`, and `platformPath` from `lib/modules.nix`
when only the target option differs:

```nix
(platformPackages {
  inherit isDarwin;
  packages = toolPackages;
})

(platformEnv {
  inherit config isDarwin;
  inherit shellExports;
  envVars = toolEnvVars;
  darwinTarget = "zsh";
})
```

Keep platform branches when behavior is genuinely platform-specific, such as
Linux-only packages, Home Manager file targets, services, hardware support, or
different VM backends.

## Validation

Run formatting on touched Nix files:

```sh
nixfmt path/to/file.nix
```

Check whitespace:

```sh
git diff --check
```

Evaluate representative outputs:

```sh
nix eval .#nixosConfigurations.<name>.config.system.build.toplevel.drvPath --impure
nix eval .#homeConfigurations.<name>.activationPackage.drvPath --impure
```

Inspect generated macOS ZSH env when touching shell rendering:

```sh
nix eval --raw '.#homeConfigurations.<name>.config.xdg.configFile."zsh/env.zsh".text' --impure
```

## Credits

This repository started from patterns inspired by
[hlissner/dotfiles](https://github.com/hlissner/dotfiles),
[flake-parts](https://github.com/hercules-ci/flake-parts), and the broader
NixOS community. The current shape is optimized for this repo's NixOS plus
standalone Home Manager workflow.
