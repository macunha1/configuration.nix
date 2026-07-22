SHELL := /bin/sh

DOTFILES := $(CURDIR)
SYSTEM := $(shell uname -s)
DEFAULT_CONFIG_USER := $(shell id -un)
DEFAULT_NIXOS_HOST := nixosmos

# Public, fork-friendly knobs.
# Override these when your flake output names differ from your local account.
ifneq ($(origin USER),undefined)
CONFIG_USER ?= $(USER)
else
CONFIG_USER ?= $(DEFAULT_CONFIG_USER)
endif

ifneq ($(origin HOST),undefined)
NIXOS_HOST ?= $(HOST)
else
NIXOS_HOST ?= $(DEFAULT_NIXOS_HOST)
endif

HOME_CONFIG ?= $(CONFIG_USER)

# Backwards-compatible aliases for existing invocations.
USER ?= $(CONFIG_USER)
HOST ?= $(NIXOS_HOST)

# When running a NixOS ISO, use /mnt as the root path.
# Ref: https://nixos.org/manual/nixos/stable/#sec-installation-installing
MOUNT_PATH ?= /

NIX := nix
NIX_FLAGS := --no-warn-dirty
NIX_SHELL := nix-shell
NIXOS_INSTALL := nixos-install
NIXOS_REBUILD := nixos-rebuild
NIX_CONFIG_QUIET := warn-dirty = false
ACTIVATE_APP := $(DOTFILES)\#activate

NIXOS_FLAKE := $(DOTFILES)\#$(NIXOS_HOST)
NIXOS_CONFIG := nixosConfigurations.$(NIXOS_HOST)
NIXOS_SYSTEM_BUILD := config.system.build.toplevel
NIXOS_TOPLEVEL := $(DOTFILES)\#$(NIXOS_CONFIG).$(NIXOS_SYSTEM_BUILD)

.DEFAULT_GOAL := help

help:
	@printf '%s\n' \
		'Usage: make <target> [CONFIG_USER=user] [NIXOS_HOST=host]'
	@printf '%s\n' \
		'                    [HOME_CONFIG=name]'
	@printf '%s\n' ''
	@printf '%s\n' 'Install targets:'
	@printf '%s\n' \
		'  install         Detect OS and install the matching configuration'
	@printf '%s\n' \
		'  activate        Activate the matching NixOS/Home Manager config'
	@printf '%s\n' \
		'  install-nixos   Build and install the NixOS system configuration'
	@printf '%s\n' \
		'  install-darwin  Switch the standalone Home Manager config'
	@printf '%s\n' ''
	@printf '%s\n' 'NixOS targets:'
	@printf '%s\n' '  build           Build nixosConfigurations.$(NIXOS_HOST)'
	@printf '%s\n' '  switch          Switch nixosConfigurations.$(NIXOS_HOST)'
	@printf '%s\n' '  rollback        Roll back nixosConfigurations.$(NIXOS_HOST)'
	@printf '%s\n' \
		'  vm              Build a VM for nixosConfigurations.$(NIXOS_HOST)'
	@printf '%s\n' ''
	@printf '%s\n' 'Maintenance targets:'
	@printf '%s\n' '  update          Update flake inputs'
	@printf '%s\n' '  check           Run flake checks'
	@printf '%s\n' '  upgrade         Update inputs and switch'
	@printf '%s\n' '  gc              Collect old NixOS generations and garbage'
	@printf '%s\n' '  clean           Remove ./result'

update:
	@$(NIX_SHELL) --run "nix flake update $(NIX_FLAGS)"

check:
	@$(NIX_SHELL) --run "nix flake check $(NIX_FLAGS)"

build:
	@CONFIG_USER=$(CONFIG_USER) USER=$(CONFIG_USER) \
		$(NIX_SHELL) --run \
			"nix build $(NIX_FLAGS) --impure $(NIXOS_TOPLEVEL)"

install:
	@case "$(SYSTEM)" in \
		Darwin) $(MAKE) activate ;; \
		Linux) $(MAKE) install-nixos ;; \
		*) printf 'Unsupported OS: %s\n' "$(SYSTEM)" >&2; exit 1 ;; \
	esac

activate:
	@NIX_CONFIG='$(NIX_CONFIG_QUIET)' \
		FLAKE="$(DOTFILES)" \
		CONFIG_USER="$(CONFIG_USER)" \
		USER="$(CONFIG_USER)" \
		HOME_CONFIG="$(HOME_CONFIG)" \
		NIXOS_HOST="$(NIXOS_HOST)" \
		HOST="$(NIXOS_HOST)" \
		$(NIX) run $(NIX_FLAGS) "$(ACTIVATE_APP)"

install-nixos: build
	@CONFIG_USER=$(CONFIG_USER) USER=$(CONFIG_USER) \
		$(NIXOS_INSTALL) --root "$(MOUNT_PATH)" --system ./result

install-darwin: activate

switch: activate

upgrade: update switch

rollback:
	@NIX_CONFIG='$(NIX_CONFIG_QUIET)' \
		$(NIXOS_REBUILD) --flake "$(NIXOS_FLAKE)" --rollback --fast switch

gc:
	@sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +1
	@nix-collect-garbage -d

vm:
	@NIX_CONFIG='$(NIX_CONFIG_QUIET)' \
		$(NIXOS_REBUILD) --flake "$(NIXOS_FLAKE)" vm

clean:
	@unlink result

# Convenience aliases
i: install
s: switch
u: upgrade

.PHONY: help update check build install activate install-nixos install-darwin switch
.PHONY: upgrade rollback gc vm clean i s u
