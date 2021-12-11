{ config, lib, pkgs, callPackage, fetchFromGitHub, ... }:

let
  pname = "molecule";
  version = "3.5.2";

  ansible-compat = callPackage ./ansible-compat.nix {
    version = "0.5.0";
    hash = "sha256-BzD7uzJxDRn0JEpMq62cazO0uS3fcq7jU0hOF1Q0BfU=";
  };

  python-selinux = callPackage ./python-selinux.nix {
    version = "0.2.1";
    hash = "sha256-1DX1FOg04/3AlB9qKdCGuAsupRsoESruYlS9EE7kKnQ=";
  };

  cerberus = callPackage ./python-cerberus.nix {
    version = "1.3.2";
    hash = "sha256-MC5mlPIG3YXLY/E/1QJbMattOMmcUMbXafj6Cw8plYk=";
  };
in pkgs.python3Packages.buildPythonPackage rec {
  inherit pname version;

  name = "${pname}-${version}";

  src = pkgs.python3Packages.fetchPypi {
    inherit version pname;

    hash = "sha256-yCrwmeXAmY1+sWo79l7VpO3Zfjgk+5OM4BvwZKRs4Mo=";
  };

  nativeBuildInputs = with pkgs.python3Packages; [
    pkgs.git

    setuptools
    setuptools-scm
    setuptools-scm-git-archive
  ];

  propagatedBuildInputs = with pkgs.python3Packages; [
    libselinux
    click
    click-help-colors
    jinja2
    packaging
    pyyaml
    pluggy
    paramiko
    subprocess-tee
    rich
    enrich
    cookiecutter
    distro

    ansible-compat
    python-selinux
    cerberus
  ];

  meta = with lib; {
    description =
      "Molecule aids in the development and testing of Ansible roles";
    homepage = "https://github.com/ansible-community/molecule";
    license = licenses.mit;
  };

}
