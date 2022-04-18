let imports = ../../imports.dhall

let GithubActions = imports.GithubActions

in  GithubActions.Step::{
    , id = None Text
    , name = Some "SSH | Load deploy key to SSH Agent"
    , uses = Some "webfactory/ssh-agent@v0.5.4"
    , `with` = Some
        (toMap { ssh-private-key = "\${{ secrets.GIT_REPO_SSH_KEY }}" })
    }
