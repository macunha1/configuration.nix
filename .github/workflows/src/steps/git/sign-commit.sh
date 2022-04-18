#!/usr/bin/env bash

# Check for changes or exit soon
[[ -n $(git status -s) ]] || exit 0

git config --local user.email "${{ steps.git_import_gpg.outputs.email }}"
git config --local user.name "${{ steps.git_import_gpg.outputs.name }}"
git config --local user.signingkey "${{ steps.git_import_gpg.outputs.keyid }}"
git config --local url.ssh://git@github.com/.insteadOf https://github.com/

GIT_BRANCH_NAME=autoupdate-$(date +'%Y%m%d')
git checkout -b ${GIT_BRANCH_NAME}

git add -A
git commit -S -m "chore(flake): [auto] Updating Flake Lock"
git push origin ${GIT_BRANCH_NAME}

# Clean up so next execution won't fail on checkout trying to pull
# through SSH
rm -f ${GITHUB_WORKSPACE}/.git/config
