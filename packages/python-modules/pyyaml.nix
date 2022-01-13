{ lib, pkgs, python, fetchFromGitHub, version ? "6.0"
  # NOTE: Following hash corresponds to version 6.0, when updating the default
  # version remember to update the default hash as well.
, hash ? "sha256-wcII32mRgRRmAgojntyxBMQkjvxU2jylCgVzlHAj2Xc=", ... }:

let pname = "PyYAML";
in pkgs.python3Packages.buildPythonPackage rec {
  inherit pname;

  name = "${pname}-${version}";

  src = fetchFromGitHub {
    inherit hash;

    owner = "yaml";
    repo = "pyyaml";
    rev = version;
  };

  nativeBuildInputs = with pkgs.python3Packages; [ cython ];

  buildInputs = with pkgs; [ libyaml ];

  pythonImportsCheck = [ "yaml" ];

  meta = with lib; {
    description = "The next generation YAML parser and emitter for Python";
    homepage = "https://github.com/yaml/pyyaml";
    license = licenses.mit;
    maintainers = with maintainers; [ macunha1 ];
  };
}
