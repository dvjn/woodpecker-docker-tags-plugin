#!/usr/bin/env bats

setup() {
  export PLUGIN_TAGS_FILE="${BATS_TEST_TMPDIR}/.tags"
  rm -f "$PLUGIN_TAGS_FILE"

  # Clear all CI variables
  unset CI_COMMIT_BRANCH CI_COMMIT_TAG CI_COMMIT_PULL_REQUEST
  unset CI_REPO_DEFAULT_BRANCH CI_PIPELINE_EVENT CI_COMMIT_SHA
}

teardown() {
  rm -f "$PLUGIN_TAGS_FILE"
}

# Helper to read the tags file
tags() {
  cat "$PLUGIN_TAGS_FILE" 2>/dev/null || echo ""
}

# =============================================================================
# Bug fix tests: unbound variables
# =============================================================================

@test "branch command on tag event does not crash (unbound CI_COMMIT_BRANCH)" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_SHA=abc123
  export PLUGIN_TAGS="branch"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
}

@test "edge command on tag event does not crash (unbound CI_REPO_DEFAULT_BRANCH)" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_SHA=abc123
  export PLUGIN_TAGS="edge"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
}

@test "pr command on tag event does not crash (unbound CI_COMMIT_PULL_REQUEST)" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_SHA=abc123
  export PLUGIN_TAGS="pr"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
}

# =============================================================================
# Bug fix tests: empty prefix creates invalid tag
# =============================================================================

@test "sha with empty prefix produces valid tag without leading dashes" {
  export CI_COMMIT_SHA=abc12345678
  export PLUGIN_TAGS='sha -p ""'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "abc12345" ]
}

@test "tag starting with dashes gets stripped" {
  export CI_COMMIT_SHA=abc12345678
  export PLUGIN_TAGS='sha -p "--"'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "abc12345" ]
}

@test "tag starting with dots gets stripped" {
  export CI_COMMIT_SHA=abc12345678
  export PLUGIN_TAGS='sha -p "..."'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "abc12345" ]
}

@test "tag starting with mixed dashes and dots gets stripped" {
  export CI_COMMIT_SHA=abc12345678
  export PLUGIN_TAGS='sha -p "-.-"'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "abc12345" ]
}

@test "empty tag is not written" {
  export CI_COMMIT_BRANCH=""
  export CI_PIPELINE_EVENT=push
  export PLUGIN_TAGS="branch"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "" ]
}

# =============================================================================
# sha command tests
# =============================================================================

@test "sha with default prefix" {
  export CI_COMMIT_SHA=abc123456789abcdef
  export PLUGIN_TAGS="sha"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "sha-abc12345" ]
}

@test "sha with custom prefix" {
  export CI_COMMIT_SHA=abc123456789abcdef
  export PLUGIN_TAGS='sha -p commit-'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "commit-abc12345" ]
}

@test "sha with long flag" {
  export CI_COMMIT_SHA=abc123456789abcdef0123456789abcdef012345
  export PLUGIN_TAGS="sha --long"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "sha-abc123456789abcdef0123456789abcdef012345" ]
}

# =============================================================================
# branch command tests
# =============================================================================

@test "branch with no prefix" {
  export CI_COMMIT_BRANCH="feature/test-branch"
  export PLUGIN_TAGS="branch"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "feature-test-branch" ]
}

@test "branch with custom prefix" {
  export CI_COMMIT_BRANCH="main"
  export PLUGIN_TAGS='branch -p branch-'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "branch-main" ]
}

# =============================================================================
# tag command tests
# =============================================================================

@test "tag command on tag event" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_TAG="v1.0.0"
  export PLUGIN_TAGS="tag"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "v1.0.0" ]
}

@test "tag command on non-tag event produces no output" {
  export CI_PIPELINE_EVENT=push
  export CI_COMMIT_TAG="v1.0.0"
  export PLUGIN_TAGS="tag"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "" ]
}

# =============================================================================
# edge command tests
# =============================================================================

@test "edge on push to default branch" {
  export CI_PIPELINE_EVENT=push
  export CI_COMMIT_BRANCH=main
  export CI_REPO_DEFAULT_BRANCH=main
  export PLUGIN_TAGS="edge"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "edge" ]
}

@test "edge on push to non-default branch produces no output" {
  export CI_PIPELINE_EVENT=push
  export CI_COMMIT_BRANCH=feature
  export CI_REPO_DEFAULT_BRANCH=main
  export PLUGIN_TAGS="edge"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "" ]
}

@test "edge with custom value" {
  export CI_PIPELINE_EVENT=push
  export CI_COMMIT_BRANCH=main
  export CI_REPO_DEFAULT_BRANCH=main
  export PLUGIN_TAGS='edge -v latest'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "latest" ]
}

@test "edge with custom branch" {
  export CI_PIPELINE_EVENT=push
  export CI_COMMIT_BRANCH=develop
  export CI_REPO_DEFAULT_BRANCH=main
  export PLUGIN_TAGS='edge -b develop'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "edge" ]
}

# =============================================================================
# pr command tests
# =============================================================================

@test "pr command on pull_request event" {
  export CI_PIPELINE_EVENT=pull_request
  export CI_COMMIT_PULL_REQUEST=42
  export PLUGIN_TAGS="pr"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "pr-42" ]
}

@test "pr command with custom prefix" {
  export CI_PIPELINE_EVENT=pull_request
  export CI_COMMIT_PULL_REQUEST=42
  export PLUGIN_TAGS='pr -p pull-'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "pull-42" ]
}

@test "pr command on non-pull_request event produces no output" {
  export CI_PIPELINE_EVENT=push
  export CI_COMMIT_PULL_REQUEST=42
  export PLUGIN_TAGS="pr"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "" ]
}

# =============================================================================
# cron command tests
# =============================================================================

@test "cron command on cron event" {
  export CI_PIPELINE_EVENT=cron
  export PLUGIN_TAGS="cron"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  # Check that a date-like tag was produced (8 digits)
  [[ "$(tags)" =~ ^[0-9]{8}$ ]]
}

@test "cron command on non-cron event produces no output" {
  export CI_PIPELINE_EVENT=push
  export PLUGIN_TAGS="cron"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "" ]
}

# =============================================================================
# semver command tests
# =============================================================================

@test "semver command extracts version" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_TAG="v1.2.3"
  export PLUGIN_TAGS="semver"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "1.2.3" ]
}

@test "semver with major format" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_TAG="v1.2.3"
  export PLUGIN_TAGS='semver -f {{major}}'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "1" ]
}

@test "semver with major.minor format" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_TAG="v1.2.3"
  export PLUGIN_TAGS='semver -f {{major}}.{{minor}}'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "1.2" ]
}

@test "semver pre-release with version format produces full version" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_TAG="v0.7.0-beta.0"
  export PLUGIN_TAGS='semver -f {{version}}'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "0.7.0-beta.0" ]
}

@test "semver pre-release default format produces full version" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_TAG="v0.7.0-beta.0"
  export PLUGIN_TAGS="semver"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "0.7.0-beta.0" ]
}

@test "semver pre-release with raw format produces raw tag" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_TAG="v0.7.0-beta.0"
  export PLUGIN_TAGS='semver -f {{raw}}'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "v0.7.0-beta.0" ]
}

@test "semver pre-release skips partial major format" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_TAG="v1.2.3-rc4"
  export PLUGIN_TAGS='semver -f {{major}}'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "" ]
}

@test "semver pre-release skips partial major.minor format" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_TAG="v1.2.3-rc4"
  export PLUGIN_TAGS='semver -f {{major}}.{{minor}}'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "" ]
}

@test "semver pre-release skips partial major.minor.patch format" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_TAG="v0.7.0-beta.0"
  export PLUGIN_TAGS='semver -f {{major}}.{{minor}}.{{patch}}'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "" ]
}

@test "semver pre-release multi-format produces only version tag" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_TAG="v1.2.3-rc4"
  export PLUGIN_TAGS=$'semver -f {{major}}\nsemver -f {{major}}.{{minor}}\nsemver -f {{major}}.{{minor}}.{{patch}}\nsemver -f {{version}}'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "1.2.3-rc4" ]
}

@test "semver auto produces major, minor, patch, and version tags" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_TAG="v1.2.3"
  export PLUGIN_TAGS="semver --auto"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags | sed -n '1p')" = "1" ]
  [ "$(tags | sed -n '2p')" = "1.2" ]
  [ "$(tags | sed -n '3p')" = "1.2.3" ]
}

@test "semver auto with short flag" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_TAG="v2.0.1"
  export PLUGIN_TAGS="semver -a"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags | sed -n '1p')" = "2" ]
  [ "$(tags | sed -n '2p')" = "2.0" ]
  [ "$(tags | sed -n '3p')" = "2.0.1" ]
}

@test "semver auto with pre-release produces only version tag" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_TAG="v1.2.3-beta.0"
  export PLUGIN_TAGS="semver --auto"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "1.2.3-beta.0" ]
}

@test "semver auto combined with format fails" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_TAG="v1.2.3"
  export PLUGIN_TAGS='semver --auto -f {{major}}'

  run ./entrypoint.sh

  [ "$status" -ne 0 ]
}

# =============================================================================
# raw command tests
# =============================================================================

@test "raw command writes value" {
  export PLUGIN_TAGS='raw -v my-tag'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "my-tag" ]
}

@test "raw command without value fails" {
  export PLUGIN_TAGS="raw"

  run ./entrypoint.sh

  [ "$status" -ne 0 ]
}

# =============================================================================
# sanitization tests
# =============================================================================

@test "uppercase is converted to lowercase" {
  export CI_COMMIT_BRANCH="Feature/TEST"
  export PLUGIN_TAGS="branch"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "feature-test" ]
}

@test "special characters are replaced with dashes" {
  export CI_COMMIT_BRANCH="feature@test#branch"
  export PLUGIN_TAGS="branch"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "feature-test-branch" ]
}

@test "tag is truncated to 128 characters" {
  # Create a 150-character branch name
  export CI_COMMIT_BRANCH="$(printf 'a%.0s' {1..150})"
  export PLUGIN_TAGS="branch"

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  result=$(tags)
  [ "${#result}" -eq 128 ]
}

# =============================================================================
# multiple commands tests
# =============================================================================

@test "multiple commands produce multiple tags" {
  export CI_PIPELINE_EVENT=tag
  export CI_COMMIT_TAG="v1.0.0"
  export CI_COMMIT_SHA=abc12345678
  export PLUGIN_TAGS=$'tag\nsha'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags | wc -l | tr -d ' ')" = "2" ]
  [ "$(tags | head -1)" = "v1.0.0" ]
  [ "$(tags | tail -1)" = "sha-abc12345" ]
}

@test "duplicate tags are removed" {
  export CI_COMMIT_SHA=abc12345678
  export PLUGIN_TAGS=$'sha\nsha'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags | wc -l | tr -d ' ')" = "1" ]
}

@test "comment lines are ignored" {
  export CI_COMMIT_SHA=abc12345678
  export PLUGIN_TAGS=$'# this is a comment\nsha'

  run ./entrypoint.sh

  [ "$status" -eq 0 ]
  [ "$(tags)" = "sha-abc12345" ]
}
