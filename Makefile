USER := macunha1
HOST := cosmos

TMPDIR := /tmp
DOTFILES := $(PWD)
COMMAND  := test

all:
	@sudo nixos-rebuild --flake "$(DOTFILES)#$(HOST)" --fast $(COMMAND)

install: update
	nix-shell -p nixUnstable \
		--command "USER=$(USER) nix build \
		$(DOTFILES)#nixosConfigurations.$(HOST).config.system.build.toplevel \
		--store '$(PREFIX)/' --impure"

	@USER=$(USER) nixos-install --root "$(PREFIX)/" --system ./result

update:
	@nix flake update

build:
	TMPDIR=$(TMPDIR) nixos-rebuild --flake "$(DOTFILES)#$(HOST)" --fast build

switch:
	TMPDIR=$(TMPDIR) sudo -E bash \
		-c  'nixos-rebuild --flake "$(DOTFILES)#$(HOST)" --fast switch'

upgrade: update switch

rollback:
	sudo nixos-rebuild --flake "$(DOTFILES)#$(HOST)" --rollback --fast switch

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
up: upgrade
u: update


.PHONY: config
