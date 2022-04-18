let imports = ../../imports.dhall

let GithubActions = imports.GithubActions

in  GithubActions.steps.run { run = ./sign-commit.sh as Text }
