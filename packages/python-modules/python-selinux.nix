{ config, lib, pkgs, stdenv, fetchFromGitHub, version ? "0.2.1"
  # NOTE: Hash corresponding to version 0.2.1, if the default version changes it
  # will be necessary to either pass this value or change the default.
, hash ? "sha256-1DX1FOg04/3AlB9qKdCGuAsupRsoESruYlS9EE7kKnQ=", ... }:

let pname = "selinux";
in pkgs.python3Packages.buildPythonPackage rec {
  inherit pname;

  name = "${pname}-${version}";

  src = pkgs.python3Packages.fetchPypi { inherit version pname hash; };

  nativeBuildInputs = with pkgs.python3Packages; [
    setuptools
    setuptools-scm
    setuptools-scm-git-archive
  ];

  buildInputs = with pkgs.python3Packages; [ distro paramiko ];

  meta = {
    description = "Pure-python selinux shim module for use in virtualenvs";

    homepage = "https://github.com/pycontribs/selinux";
    license = lib.licenses.mit;
  };

}
