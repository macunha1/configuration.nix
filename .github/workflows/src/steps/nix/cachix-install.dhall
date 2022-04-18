let imports = ../../imports.dhall

let GithubActions = imports.GithubActions

let Map = imports.Map

let Cachix/substituters =
      imports.Text/concatSep
        " "
        [ "https://nrdxp.cachix.org", "https://nix-community.cachix.org" ]

let Cachix/trustedPubkeys =
      imports.Text/concatSep
        " "
        [ "nrdxp.cachix.org-1:Fc5PSqY2Jm1TrWfm88l6cvGWwz3s93c6IOifQWnhNW4="
        , "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ]

let Nix/extraConfigs =
      toMap
        { extra_nix_config =
            ''
            experimental-features = "nix-command flakes"
            substituters = "${Cachix/substituters}"
            trusted-public-keys = "${Cachix/trustedPubkeys}"
            ''
        }

in    GithubActions.steps.cachix/install-nix
    ⫽ { uses = Some "cachix/install-nix-action@v15"
      , `with` = Some Nix/extraConfigs
      }
