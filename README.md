<center>

<h1>configuration.nix -> NixOS config as code</h1>

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

</center>

## Quick start

# TODO

```sh
git clone https://github.com/macunha1/configuration.nix ${HOME}/.config/nixos/dotfiles
cd $_
make install
```

### Management

+ `make` = `nixos-rebuild test`
+ `make switch` = `nixos-rebuild switch`
+ `make upgrade` = `nix-channel --update && nixos-rebuild switch`
+ `make install` = `nixos-generate-config --root $PREFIX && nixos-install --root
  $PREFIX`
+ `make gc` = `nix-collect-garbage -d` (use sudo to clear system profile)

### Credits

Heavily based and inspired on the incredible work from
[hlissner](https://github.com/hlissner) at
[hlissner/dotfiles](https://github.com/hlissner/dotfiles).
