# packages/terraform-bin.nix -- https://www.terraform.io/
#
# Binary Terraform package pinned to the latest stable upstream release.
# This avoids building Terraform from source and keeps macOS/Linux installs
# aligned with the release binaries HashiCorp publishes.

{
  lib,
  stdenv,
  fetchurl,
  unzip,
}:

let
  version = "1.15.8";

  platform =
    {
      x86_64-linux = {
        name = "linux_amd64";
        hash = "sha256-0lzntpAgE62QXbPS6rC+TNkFiH/oi4GmFxuNVQPDHz0=";
      };
      aarch64-linux = {
        name = "linux_arm64";
        hash = "sha256-iJHp3O3J47iVC8avnU2K8fTPreMGL1O53EA6ifbOjJw=";
      };
      x86_64-darwin = {
        name = "darwin_amd64";
        hash = "sha256-4ugS54N3EVm/dY/U5V1tybsI9j4q8sY9ISchgHoCxdw=";
      };
      aarch64-darwin = {
        name = "darwin_arm64";
        hash = "sha256-8hARDFaYuU2AOnpjzbAlG1RVwVCEFHiAjiu7ND+V7Wg=";
      };
    }
    .${stdenv.hostPlatform.system}
      or (throw "Unsupported Terraform platform: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "terraform-bin";
  inherit version;

  src = fetchurl {
    url = "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_${platform.name}.zip";
    inherit (platform) hash;
  };

  dontUnpack = true;
  nativeBuildInputs = [ unzip ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"

    terraform_member=""
    while IFS= read -r name; do
        case "$name" in
        terraform|*/terraform)
            terraform_member=$name
            break
            ;;
        esac
    done <<EOF
    $(unzip -Z1 "$src")
    EOF

    if [ -z "$terraform_member" ]; then
        echo "terraform binary not found in archive" >&2
        exit 1
    fi

    unzip -p "$src" "$terraform_member" > "$out/bin/terraform"
    chmod 755 "$out/bin/terraform"

    runHook postInstall
  '';

  meta = {
    description = "Tool for building, changing, and versioning infrastructure";
    homepage = "https://www.terraform.io/";
    license = lib.licenses.bsl11;
    mainProgram = "terraform";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}
