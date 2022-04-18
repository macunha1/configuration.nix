let imports = ../../imports.dhall

let GithubActions = imports.GithubActions

in  GithubActions.Step::{
    , id = Some "git_import_gpg"
    , name = Some "Git | Import GPG key to sign commits"
    , uses = Some "crazy-max/ghaction-import-gpg@v4"
    , `with` = Some
        ( toMap
            { gpg_private_key = "\${{ secrets.GH_ACTIONS_GPG_PRIVATE_KEY }}"
            , passphrase = "\${{ secrets.GH_ACTIONS_GPG_PASSPHRASE }}"
            , git_user_signingkey = "true"
            , git_commit_gpgsign = "true"
            }
        )
    }
