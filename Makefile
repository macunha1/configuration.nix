USER := macunha
HOST := nixosmos

# When running NixOS ISO, an alternative root path will be required to perform
# install since / will have the live image mounted. NixOS manual proposes /mnt
# as the temporary alternative mount point path.
# Ref: https://nixos.org/manual/nixos/stable/#sec-installation-installing
MOUNT_PATH := /

DOTFILES := $(PWD)
COMMAND  := test

update:
	@nix-shell --run "nix flake update"

check:
	@nix-shell --run "nix flake check"

build:
	@nix-shell --run "USER=$(USER) nix build --impure \
		$(DOTFILES)#nixosConfigurations.$(HOST).config.system.build.toplevel"

install: build
	@USER=$(USER) nixos-install --root "$(MOUNT_PATH)" --system ./result

switch:
	@nixos-rebuild --flake "$(DOTFILES)#$(HOST)" --fast switch

upgrade: update switch

rollback:
	@nixos-rebuild --flake "$(DOTFILES)#$(HOST)" --rollback --fast switch

gc:
	@sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +1
	@nix-collect-garbage -d

vm:
	@nixos-rebuild --flake "$(DOTFILES)#$(HOST)" vm

clean:
	@unlink result


# Convenience aliases
i: install
s: switch
u: upgrade


.PHONY: config
