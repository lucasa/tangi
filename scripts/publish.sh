#!/bin/bash

if [[ -z $(git status -uno --porcelain) ]]; then
  VERSION="$(npm view tangi version)";
  read -p "Enter the new version number: (currently ${VERSION}) " BUMP;
  VERSION="$(npm version $BUMP --no-git-tag-version)";
  node_modules/.bin/conventional-changelog -p angular -i CHANGELOG.md -s;
  vi CHANGELOG.md;
  git diff package.json CHANGELOG.md;
  read -p "Look good? (y/n) " CONDITION;

  if [ "$CONDITION" == "y" ]; then
    git add package.json CHANGELOG.md;
    git commit -m "chore(publish): ${VERSION}";
    git tag "${VERSION}" -m "See https://github.com/pricingmonkey/tangi/blob/master/CHANGELOG.md#${BUMP}";
    git push origin master;
    git push origin "${VERSION}";
    read -p "Which dist-tag? (latest) " DIST_TAG;
    DIST_TAG=${DIST_TAG:-latest}

    if [[ "$BUMP" =~ - ]] && [ "$DIST_TAG" == "latest" ]; then
      read -p "Using dist-tag 'latest' for a pre-release. ARE YOU SURE? (y/n) " CONDITION;

      if [ "$CONDITION" == "n" ] || [ "$CONDITION" == "" ]; then
        echo "Cancelled publish by your request!";
        exit 1;
      fi
    fi

    read -p "Enter 2FA auth token: " AUTH;
    yarn publish --tag $DIST_TAG --otp $AUTH;
  else
    git checkout -f package.json CHANGELOG.md;
    echo "Cancelled publish by your request!";
    exit 1;
  fi

else
  echo "You cannot publish with uncommited changes";
  exit 1;
fi
