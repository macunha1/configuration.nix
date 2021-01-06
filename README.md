# configuration.nix -> NixOS config as code

|              |               |
|--------------+---------------|
| **Shell**    | ZSH + Antigen |
| **DM**       | LightDM       |
| **WM**       | AwesomeWM     |
| **Terminal** | Alacritty     |
| **Launcher** | Rofi          |
| **Browser**  | Chromium      |

> Know thyself
>
> Know thy environment
>
> A thousand configurations
>
> A thousand wins
>
> - Sun Tzsh, The Art of Code

## Quick start

```sh
# Assumes your partitions are set up and root is mounted on /mnt
git clone https://github.com/macunha1/configuration.nix /etc/dotfiles
make -C /etc/dotfiles install
```

Which is equivalent to:

```sh
USER=${USER:-macunha1}
HOST=${HOST:-cosmos}
NIXOS_VERSION=20.09
DOTFILES=/home/$USER/.dotfiles

git clone https://github.com/macunha1/.dotfiles /etc/dotfiles
ln -s /etc/dotfiles $DOTFILES
chown -R $USER:users $DOTFILES

# make install
nixos-install --root /mnt --flake /mnt/etc/dotfiles
```

### Management

+ `make` = `nixos-rebuild test`
+ `make switch` = `nixos-rebuild switch`
+ `make upgrade` = `nix-channel --update && nixos-rebuild switch`
+ `make install` = `nixos-generate-config --root $PREFIX && nixos-install --root
  $PREFIX`
+ `make gc` = `nix-collect-garbage -d` (use sudo to clear system profile)

### Credits

Initial configuration was heavily based on [hlissner/dotfiles](https://github.com/hlissner/dotfiles).
