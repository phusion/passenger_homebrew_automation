# Phusion Passenger Homebrew packaging automation

We want to continuously test our Homebrew formulas in a CI environment. We want to know, for each Passenger commit:

 - **(Goal 1)** Whether the Homebrew formula still works.
 - **(Goal 2)** Which Homebrew formula was tested against that commit.

There is also another goal:

 - **(Goal 3)** On every Passenger release, we want to automatically submit modify the open source Homebrew formula and submit a pull request to [homebrew-core](https://github.com/Homebrew/homebrew-core).

This repository contains tools for achieving the above goals. These tools are used in Passenger's CI infrastructure.

> **Are you at the right place?**
>
> * Looking to contribute modifications to our open source Homebrew formula? Then `brew edit passenger` and submit a pull request to [homebrew-core](https://github.com/Homebrew/homebrew-core).
> * Looking to contribute modifications to our Passenger Enterprise Homebrew formula? Then contribtue to [our Passenger Enterprise tap](https://github.com/phusion/homebrew-passenger).
> * If you're looking to modify Phusion's Homebrew formula testing infrastructure, then this is the right place.

**Table of contents**

<!-- TOC depthFrom:2 -->

- [How it works](#how-it-works)
    - [Git submodule](#git-submodule)
    - [Repo contains a copy of the formula](#repo-contains-a-copy-of-the-formula)
    - [Passenger Enterprise](#passenger-enterprise)
    - [Simplified CI flow overview](#simplified-ci-flow-overview)

<!-- /TOC -->

## How it works

### Git submodule

This repo is a Git submodule of the Passenger repo, under `packaging/homebrew`.

### Repo contains a copy of the formula

This repo contains a copy of the open source formula. On each commit to Passenger open source this formula is tested (by the `test-formula` script). This script `brew install`s the formula and runs a test suite afterwards.

There are two reasons why we have a copy:

 1. To satisfy goal 2. The copy here, plus the use of Git submodules, allows us to effectively lock down each Passenger commit to a specific version of the formula.
 2. To have a place to store formula changes that are only applicable to unreleased versions of Passenger. These formula changes should not yet be submitted to homebrew-core.

However, OSS formula also lives in [homebrew-core](https://github.com/Homebrew/homebrew-core), which anyone can contribute to. At the same time, the pull request that we generate during release time, is based on our local copy. So the copy in this repo must be kept up-to-date with the one in homebrew-core.

This is why, on every Passenger commit and during release, the `verify-oss-formula-uptodate` script checks whether the copy in homebrew-core is newer. If so, the script raises an error and a maintainer will have to manually update the local copy with the one in homebrew-core.

### Passenger Enterprise

This repo contains no copy of the Enterprise formula. That one is stored in [our Passenger Enterprise tap](https://github.com/phusion/homebrew-passenger). That tap is *also* imported as a Git submodule into the Passenger Enterprise repo, under `packaging/homebrew-enterprise`.

The scripts in the current repo (e.g. `test-formula`) automatically detect whether they're being invoked for Passenger open source or Passenger Enterprise. When Passenger Enterprise is detected, they will use `packaging/homebrew-enterprise/Formula/passenger-enterprise.rb` instead of `packaging/homebrew/Formula/passenger.rb`.

### Simplified CI flow overview

On every commit, the Passenger repo's Jenkinsfile is invoked. The 'Homebrew packaging unit tests' test in the Jenkinsfile runs two commands:

    ./dev/ci/setup-host homebrew-packaging
       |
       +-- eventually calls ./dev/ci/tests/homebrew-packaging/setup

    ./dev/ci/run-tests-natively homebrew-packaging
       |
       +-- eventually calls ./dev/ci/tests/homebrew-packaging/run
             |
             +-- Create source tarball
             |
             +-- (If OSS) Check whether OSS formula is up-to-date
             |     |
             |     +-- ./packaging/homebrew/verify-oss-formula-uptodate
             |
             +-- Create a temporary copy of the formula with the SHA and filename adjusted to the source tarball
             |     |
             |     +-- ./packaging/homebrew/modify-formula
             |
             +-- Test temporary copy of the formula
                   |
                   +-- ./packaging/homebrew/test-formula
                         |
                         +-- Reset Homebrew taps
                         |
                         +-- Uninstall existing formulas
                         |
                         +-- `brew install` Passenger formula
                         |
                         +-- `brew install` Nginx formula
                         |
                         +-- rake test:integration:native_packaging
                             See test/integration_tests/native_packaging_spec.rb
