USER := macunha1
HOST := cosmos

DOTFILES := $(HOME)/.config/nixos/dotfiles
COMMAND  := test

all:
	@sudo nixos-rebuild --flake "$(DOTFILES)#$(HOST)" --fast $(COMMAND)

install: update
	@USER=$(USER) nixos-install --root "$(PREFIX)/" --flake \
        "$(DOTFILES)#$(HOST)"

update:
	@nix flake update --recreate-lock-file

switch:
	@sudo nixos-rebuild --flake "$(DOTFILES)#$(HOST)" --fast switch

upgrade: update switch

rollback:
	@nixos-rebuild --flake "$(DOTFILES)#$(HOST)" --rollback --fast switch

gc:
	@nix-collect-garbage -d

vm:
	@nixos-rebuild --flake "$(DOTFILES)#$(HOST)" vm

clean:
	@unlink result

# Parts
# config: $(DOTFILES)

# Convenience aliases
i: install
s: switch
up: upgrade
u: update


.PHONY: config
