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
    hash = "sha256-1DX1FOg04/3AlB9qKdCGuAsupRsoESruYlS9EE7kKnQ=";
  };
in pkgs.python3Packages.buildPythonPackage rec {
  inherit pname version;

  name = "${pname}-${version}";

  src = pkgs.python3Packages.fetchPypi {
    inherit version pname;

    hash = "sha256-yCrwmeXAmY1+sWo79l7VpO3Zfjgk+5OM4BvwZKRs4Mo=";
  };

  #   fetchFromGitHub {
  #   owner = "ansible-community";
  #   repo = "molecule";

  #   rev = version;
  #   hash = "sha256-R9mSQBU1HN8KxUf/lAyZD28sKN/R0CF1bDARtC6N07Y=";
  # };

  postPatch = ''
    substituteInPlace setup.cfg \
      --replace "; sys_platform==\"linux2\"" ""

    substituteInPlace setup.cfg \
      --replace "; sys_platform==\"linux\"" ""

    substituteInPlace constraints.txt \
      --replace "; sys_platform == \"linux\"" ""
  '';

  nativeBuildInputs = with pkgs; [
    git

    python3Packages.setuptools
    python3Packages.setuptools-scm
    python3Packages.setuptools-scm-git-archive
  ];

  buildInputs = with pkgs; [
    python3Packages.libselinux
    python3Packages.click-help-colors
    python3Packages.jinja2
    python3Packages.pyyaml
    python3Packages.pluggy
    python3Packages.paramiko
    python3Packages.subprocess-tee
    python3Packages.rich
    python3Packages.enrich

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
