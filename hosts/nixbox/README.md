# Nixbox

Before applying NixOS updates to desktops/workstations a Vagrant box is created
as the sandbox for applying the updates. Once the updates are validated and
ready to serve, I apply them to desktops and workstations.

## Configuration

Vagrant doesn't provide an NixOS box image and even if it did, it would most
probably be an outdated image. To create the latest and greatest box the project
that inspired this host name is used:
[nix-community/nixbox](https://github.com/nix-community/nixbox).

To create a box using `nixbox` you must have Packet to create the image using a
NixOS ISO. Further [instructions are available here](https://lunar.computer/posts/vagrant-nixos/).

`Vagrantfile` implementation [reference available
here](https://github.com/macunha1/Vagrantfiles/blob/8a3af99/nixos/20.09/Vagrantfile)

``` ruby
vm_provider = ENV["VAGRANT_PROVIDER"] || "virtualbox"
vm_net_ipv4_address = ENV["VAGRANT_IPV4_ADDRESS"] || "192.168.50.4"

Vagrant.configure("2") do |config|
  # NOTE: Box generated with HashiCorp Packer using nixbox
  # Ref: https://github.com/nix-community/nixbox
  config.vm.box = "nixos/20.09"
  config.vm.network "private_network", ip: vm_net_ipv4_address

  config.vm.provider vm_provider do |v|
    v.memory = 1024*Integer(ENV["VAGRANT_RAM_GB"] || 1)
    v.cpus = Integer(ENV["VAGRANT_CPU_CORES"] || 1)

    v.storage :file, :size => '40G', :type => 'raw'
  end

  config.vm.provision "shell" do |s|
    ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
    s.inline = <<-SHELL
      VAGRANT_AUTH_KEYS=/home/vagrant/.ssh/authorized_keys
      [ ! -e $VAGRANT_AUTH_KEYS ] && touch $VAGRANT_AUTH_KEYS
      echo #{ssh_pub_key} >> $VAGRANT_AUTH_KEYS

      sudo nix-channel --add https://nixos.org/channels/nixos-unstable
      sudo nix-channel --add https://nixos.org/channels/nixpkgs-unstable
      sudo nix-channel --update

      sudo nix-env -i vim git
    SHELL
  end
end
```
