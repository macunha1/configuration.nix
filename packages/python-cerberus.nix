{ config, lib, pkgs, stdenv, fetchFromGitHub, pytestCheckHook, version ? "1.3.4"
  # NOTE: Hash corresponding to version 0.2.1, if the default version changes it
  # will be necessary to either pass this value or change the default.
, hash ? "sha256-1DX1FOg04/3AlB9qKdCGuAsupRsoESruYlS9EE7kKnQ=", ... }:

let pname = "Cerberus";
in pkgs.python3Packages.buildPythonPackage rec {
  inherit pname;

  name = "${pname}-${version}";

  src = pkgs.python3Packages.fetchPypi { inherit version pname hash; };

  checkInputs = [ pytestCheckHook ];

  preCheck = ''
    export TESTDIR=$(mktemp -d)
    cp -R ./cerberus/tests $TESTDIR
    pushd $TESTDIR
  '';

  postCheck = ''
    popd
  '';

  pythonImportsCheck = [ "cerberus" ];

  meta = {
    homepage = "http://python-cerberus.org/";
    description = ''
      Lightweight, extensible schema and data validation tool for Python
      dictionaries
    '';

    license = lib.licenses.mit;
  };
}
