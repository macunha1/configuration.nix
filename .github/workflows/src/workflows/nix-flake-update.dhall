let imports = ../imports.dhall

let GithubActions = imports.GithubActions

let Cachix/installNix = ../steps/nix/cachix-install.dhall

let SSH/agent = ../steps/ssh/agent.dhall

let Git/signAndPushCommit = ../steps/git/sign-and-push-commit.dhall

let GPG/importKey = ../steps/gpg/import-key.dhall

let setup =
      [ GithubActions.steps.actions/checkout
      , Cachix/installNix
      ,     GithubActions.steps.run { run = "make update" }
        //  { name = Some "Nix | Flake Update (latest versions to flake.lock)" }
      , SSH/agent
      , GPG/importKey
      , Git/signAndPushCommit
      ]

in  GithubActions.Workflow::{
    , name = "Nix Flake Update"
    , on = GithubActions.On::{
      , workflow_dispatch = Some GithubActions.WorkflowDispatch::{=}
      , schedule = Some [ GithubActions.Schedule::{ cron = "0 0 * * Sat" } ]
      }
    , jobs = toMap
        { flake-update = GithubActions.Job::{
          , runs-on = GithubActions.types.RunsOn.self-hosted
          , steps = setup
          }
        }
    }
