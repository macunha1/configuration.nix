SHELL := /bin/sh

DOTFILES := $(CURDIR)
SYSTEM := $(shell uname -s)
DEFAULT_CONFIG_USER := $(shell id -un)
DEFAULT_NIXOS_HOST := nixosmos

ifeq ($(SYSTEM),Linux)
ROOT_CMD := sudo -H -E
else
ROOT_CMD :=
endif

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

# Install into the live system by default.  Installer environments can point
# this at the mounted target filesystem with MOUNT_PATH=/mnt.
# Ref: https://nixos.org/manual/nixos/stable/#sec-installation-installing
MOUNT_PATH ?= /

NIX := nix
NIX_FLAGS := --no-warn-dirty
# Full host builds can compile several large Rust crates. Keep the machine usable.
BUILD_JOBS ?= 2
BUILD_CORES ?= 4
NIX_BUILD_FLAGS := --max-jobs $(BUILD_JOBS) --cores $(BUILD_CORES)
NIXOS_INSTALL := nixos-install
NIXOS_REBUILD := nixos-rebuild

define NIX_CONFIG
warn-dirty = false
flake-registry =
endef
export NIX_CONFIG

WORKTREE_FLAKE := path:$(DOTFILES)
CI_FLAKE := git+file://$(DOTFILES)

ACTIVATE_APP := $(WORKTREE_FLAKE)\#activate

NIXOS_FLAKE := $(WORKTREE_FLAKE)\#$(NIXOS_HOST)
NIXOS_INSTALL_FLAKE := $(WORKTREE_FLAKE)\#$(NIXOS_HOST)
NIXOS_CONFIG := nixosConfigurations.$(NIXOS_HOST)
NIXOS_SYSTEM_BUILD := config.system.build.toplevel
NIXOS_TOPLEVEL := $(WORKTREE_FLAKE)\#$(NIXOS_CONFIG).$(NIXOS_SYSTEM_BUILD)

.DEFAULT_GOAL := help

help:
	@printf '%s\n' \
		'Usage: make <target> [CONFIG_USER=user] [NIXOS_HOST=host]'
	@printf '%s\n' \
		'                    [HOME_CONFIG=name]'
	@printf '%s\n' '                    [BUILD_JOBS=2] [BUILD_CORES=4]'
	@printf '%s\n' ''
	@printf '%s\n' 'Install targets:'
	@printf '%s\n' \
		'  install         Detect OS and activate the matching configuration'
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
	@printf '%s\n' '  ci              Match Actions: check and build nixbox as runner'
	@printf '%s\n' '  upgrade         Update inputs and switch'
	@printf '%s\n' '  gc              Collect old NixOS generations and garbage'
	@printf '%s\n' '  clean           Remove ./result'

update:
	@$(NIX) flake update $(NIX_FLAGS)

check:
	@$(NIX) flake check $(NIX_FLAGS) $(NIX_BUILD_FLAGS) --no-update-lock-file $(WORKTREE_FLAKE)

# Keep the public CI configuration independent of local installation defaults.
# Explicit user/host overrides (including legacy aliases) still take precedence.
ci: CONFIG_USER = $(if $(filter command line,$(origin USER)),$(USER),runner)
ci: NIXOS_HOST = $(if $(filter command line,$(origin HOST)),$(HOST),nixbox)
ci:
	@printf 'CI source: %s\nCI host: %s\nCI user: %s\n' \
		"$(CI_FLAKE)" "$(NIXOS_HOST)" "$(CONFIG_USER)"
	@$(NIX) --version
	@printf 'CI lock hash: '
	@$(NIX) hash file --type sha256 "$(DOTFILES)/flake.lock"
	@printf 'CI host derivation: '
	@CONFIG_USER=$(CONFIG_USER) USER=$(CONFIG_USER) \
		$(NIX) eval $(NIX_FLAGS) --no-update-lock-file --impure --raw \
		"$(CI_FLAKE)#nixosConfigurations.$(NIXOS_HOST).$(NIXOS_SYSTEM_BUILD).drvPath"
	@printf '\n'
	@$(MAKE) CONFIG_USER=$(CONFIG_USER) NIXOS_HOST=$(NIXOS_HOST) \
		WORKTREE_FLAKE="$(CI_FLAKE)" check
	@$(MAKE) CONFIG_USER=$(CONFIG_USER) NIXOS_HOST=$(NIXOS_HOST) \
		WORKTREE_FLAKE="$(CI_FLAKE)" build

build:
	@CONFIG_USER=$(CONFIG_USER) USER=$(CONFIG_USER) \
		$(NIX) build $(NIX_FLAGS) $(NIX_BUILD_FLAGS) --no-update-lock-file --impure $(NIXOS_TOPLEVEL)

install:
	@case "$(SYSTEM)" in \
		Darwin) $(MAKE) activate ;; \
		Linux) $(MAKE) activate ;; \
		*) printf 'Unsupported OS: %s\n' "$(SYSTEM)" >&2; exit 1 ;; \
	esac

activate:
	@FLAKE="$(WORKTREE_FLAKE)" \
		CONFIG_USER="$(CONFIG_USER)" \
		USER="$(CONFIG_USER)" \
		HOME_CONFIG="$(HOME_CONFIG)" \
		NIXOS_HOST="$(NIXOS_HOST)" \
		HOST="$(NIXOS_HOST)" \
		$(ROOT_CMD) $(NIX) run $(NIX_FLAGS) "$(ACTIVATE_APP)"

install-nixos:
	@$(ROOT_CMD) env CONFIG_USER=$(CONFIG_USER) USER=$(CONFIG_USER) \
		$(NIXOS_INSTALL) --root "$(MOUNT_PATH)" --flake "$(NIXOS_INSTALL_FLAKE)" --impure

install-darwin: activate

switch: activate

upgrade: update switch

rollback:
	@$(NIXOS_REBUILD) --flake "$(NIXOS_FLAKE)" --rollback --fast switch

gc:
	@sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +1
	@nix-collect-garbage -d

vm:
	@$(NIXOS_REBUILD) --flake "$(NIXOS_FLAKE)" vm

clean:
	@unlink result

# Convenience aliases
i: install
s: switch
u: upgrade

.PHONY: help update check ci build install activate install-nixos install-darwin switch
.PHONY: upgrade rollback gc vm clean i s u
