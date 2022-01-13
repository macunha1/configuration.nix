{ config, lib, pkgs, stdenv, fetchFromGitHub, version ? "0.5.0"
  # NOTE: Hash corresponding to version 0.5.0, if the default version changes it
  # will be necessary to either pass this value or change the default.
, hash ? "sha256-BzD7uzJxDRn0JEpMq62cazO0uS3fcq7jU0hOF1Q0BfU=", ... }:

let pname = "ansible-compat";
in pkgs.python3Packages.buildPythonPackage rec {
  inherit pname;

  name = "${pname}-${version}";

  src = pkgs.python3Packages.fetchPypi { inherit version pname hash; };

  nativeBuildInputs = with pkgs.python3Packages; [
    setuptools
    setuptools-scm
    setuptools-scm-git-archive

    pytest
    pytest-mock
    flaky
  ];

  buildInputs = with pkgs.python3Packages; [ click pyyaml toml tomli ];

  meta = {
    description = ''
      A python package containing functions that help interacting with various
      versions of Ansible
    '';

    homepage = "https://github.com/ansible-community/ansible-compat";
    license = lib.licenses.mit;
  };

}
