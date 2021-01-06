USER := macunha1
HOST := cosmos

NIXOS_VERSION := 20.09
DOTFILES      := $(HOME)/.config/nixos/dotfiles
COMMAND       := test

all:
	@nixos-rebuild --flake "$(DOTFILES)#$(HOST)" --fast $(COMMAND)

install: channels update config
	@USER=$(USER) nixos-install --root "$(PREFIX)/" --flake \
        "$(DOTFILES)#$(HOST)"

update:
	@nix flake update --recreate-lock-file "$(DOTFILES)#$(HOST)"

switch:
	@nixos-rebuild --flake "$(DOTFILES)#$(HOST)" switch

upgrade: update switch

rollback:
	@nixos-rebuild --flake "$(DOTFILES)#$(HOST)" --rollback switch

gc:
	@nix-collect-garbage -d

vm:
	@nixos-rebuild --flake "$(DOTFILES)#$(HOST)" vm

clean:
	@unlink result

# Parts
config: $(DOTFILES)

# Convenience aliases
i: install
s: switch
up: upgrade
u: update


.PHONY: config
