<h1 align="center">configuration.nix -> NixOS config as code</h1>

<table align="center">
<tr>

<td>
<b>Shell:</b> ZSH + Antigen<br>
<b>DM:</b> LightDM<br>
<b>WM:</b> AwesomeWM<br>
<b>Terminal:</b> Alacritty<br>
<b>Launcher:</b> Rofi<br>
<b>Browser:</b> Chromium
</td>

<td>
<i>Know thyself,</i><br>
<i>Know thy environment.</i><br>

<i>A thousand configurations,</i><br>
<i>A thousand wins</i>
<br><br>
<b> - Sun Tzsh, The Art of Code</b>
</td>

</tr>
</table>

## Quick start: Installing

```sh
git clone https://github.com/macunha1/configuration.nix ${HOME}/.config/nixos/dotfiles
cd $_
make install
```

### Management

+ `make` = `nixos-rebuild --flake configuration.nix#${HOST} test`
+ `make switch` = `nixos-rebuild --flake configuration.nix#${HOST} switch`

### Credits

Heavily based and inspired on the incredible work from
[hlissner](https://github.com/hlissner) at
[hlissner/dotfiles](https://github.com/hlissner/dotfiles).
