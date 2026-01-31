#!/usr/bin/env bash

set -euo pipefail

# Set defaults for CI variables that may be unset depending on event type
CI_COMMIT_BRANCH="${CI_COMMIT_BRANCH:-}"
CI_COMMIT_TAG="${CI_COMMIT_TAG:-}"
CI_COMMIT_PULL_REQUEST="${CI_COMMIT_PULL_REQUEST:-}"
CI_REPO_DEFAULT_BRANCH="${CI_REPO_DEFAULT_BRANCH:-}"
CI_PIPELINE_EVENT="${CI_PIPELINE_EVENT:-}"
CI_COMMIT_SHA="${CI_COMMIT_SHA:-}"

commands="${PLUGIN_TAGS}"
tags_file="${PLUGIN_TAGS_FILE:-.tags}"

sanitize_and_write_tag() {
  local lowercased_tag sanitized_tag truncated_tag final_tag

  lowercased_tag="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  sanitized_tag="${lowercased_tag//[^a-zA-Z0-9\-\_\.]/-}"
  truncated_tag="${sanitized_tag:0:128}"

  # Strip leading dashes and dots (invalid in Docker tags)
  final_tag="${truncated_tag#"${truncated_tag%%[^-\.]*}"}"

  # Skip empty tags
  [[ -z "$final_tag" ]] && return

  echo "$final_tag" >>"$tags_file"
}

handle_branch() {
  local prefix=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -p | --prefix)
      prefix="$2"
      shift
      ;;
    *)
      echo "Invalid option '$1'." >&2
      exit 1
      ;;
    esac
    shift
  done

  sanitize_and_write_tag "$prefix$CI_COMMIT_BRANCH"
}

handle_cron() {
  [[ "$CI_PIPELINE_EVENT" != "cron" ]] && return

  local format="%Y%m%d"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -f | --format)
      format="$2"
      shift
      ;;
    *)
      echo "Invalid option '$1'." >&2
      exit 1
      ;;
    esac
    shift
  done

  sanitize_and_write_tag "$(date +"$format")"
}

handle_edge() {
  [[ "$CI_PIPELINE_EVENT" != "push" ]] && return

  local value="edge"
  local branch="$CI_REPO_DEFAULT_BRANCH"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -v | --value)
      value="$2"
      shift
      ;;
    -b | --branch)
      branch="$2"
      shift
      ;;
    *)
      echo "Invalid option '$1'." >&2
      exit 1
      ;;
    esac
    shift
  done

  [[ "$CI_COMMIT_BRANCH" != "$branch" ]] && return

  sanitize_and_write_tag "$value"
}

handle_pr() {
  [[ "$CI_PIPELINE_EVENT" != "pull_request" ]] && return

  local prefix="pr-"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -p | --prefix)
      prefix="$2"
      shift
      ;;
    *)
      echo "Invalid option '$1'." >&2
      exit 1
      ;;
    esac
    shift
  done

  sanitize_and_write_tag "$prefix$CI_COMMIT_PULL_REQUEST"
}

handle_raw() {
  local value=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -v | --value)
      value="$2"
      shift
      ;;
    *)
      echo "Invalid option '$1'." >&2
      exit 1
      ;;
    esac
    shift
  done

  [[ -z "$value" ]] && {
    echo "Error: --value is required." >&2
    exit 1
  }

  sanitize_and_write_tag "$value"
}

# Reference: https://gist.github.com/bitmvr/9ed42e1cc2aac799b123de9fdc59b016
parse_semver() {
  VERSION="${1#[vV]}"
  VERSION_MAJOR="${VERSION%%.*}"
  VERSION_MINOR_PATCH="${VERSION#*.}"
  VERSION_MINOR="${VERSION_MINOR_PATCH%%.*}"
  VERSION_PATCH_PRE_RELEASE="${VERSION_MINOR_PATCH#*.}"
  VERSION_PATCH="${VERSION_PATCH_PRE_RELEASE%%[-+]*}"
  VERSION_PRE_RELEASE=""

  if [[ "$VERSION" == *-* ]]; then
    VERSION_PRE_RELEASE="${VERSION#*-}"
    VERSION_PRE_RELEASE="${VERSION_PRE_RELEASE%%+*}"
  fi

  export VERSION VERSION_MAJOR VERSION_MINOR VERSION_PATCH VERSION_PRE_RELEASE
}

write_semver_tag() {
  local format="$1"
  local value="$2"

  # Skip partial formats for pre-release versions to avoid overwriting stable tags
  if [[ -n "$VERSION_PRE_RELEASE" && "$format" != *"{{version}}"* && "$format" != *"{{raw}}"* ]]; then
    return
  fi

  local output="$format"
  output="${output//\{\{raw\}\}/${value}}"
  output="${output//\{\{version\}\}/${VERSION}}"
  output="${output//\{\{major\}\}/${VERSION_MAJOR}}"
  output="${output//\{\{minor\}\}/${VERSION_MINOR}}"
  output="${output//\{\{patch\}\}/${VERSION_PATCH}}"
  sanitize_and_write_tag "$output"
}

handle_semver() {
  [[ "$CI_PIPELINE_EVENT" != "tag" ]] && return

  local format="{{version}}"
  local value="$CI_COMMIT_TAG"
  local auto=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -a | --auto)
      auto=true
      ;;
    -f | --format)
      format="$2"
      shift
      ;;
    -v | --value)
      value="$2"
      shift
      ;;
    *)
      echo "Invalid option '$1'." >&2
      exit 1
      ;;
    esac
    shift
  done

  if [[ "$auto" == true && "$format" != "{{version}}" ]]; then
    echo "Error: --auto cannot be combined with --format." >&2
    exit 1
  fi

  parse_semver "$value"

  if [[ "$auto" == true ]]; then
    write_semver_tag "{{major}}" "$value"
    write_semver_tag "{{major}}.{{minor}}" "$value"
    write_semver_tag "{{major}}.{{minor}}.{{patch}}" "$value"
    write_semver_tag "{{version}}" "$value"
  else
    write_semver_tag "$format" "$value"
  fi
}

handle_sha() {
  local length=8
  local prefix=sha-

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -l | --long)
      length=40
      ;;
    -p | --prefix)
      prefix="$2"
      shift
      ;;
    *)
      echo "Invalid option '$1'." >&2
      exit 1
      ;;
    esac
    shift
  done

  sanitize_and_write_tag "$prefix${CI_COMMIT_SHA:0:$length}"
}

handle_tag() {
  [[ "$CI_PIPELINE_EVENT" != "tag" ]] && return

  sanitize_and_write_tag "$CI_COMMIT_TAG"
}

handle_command() {
  [[ -z "$1" ]] && return

  # shellcheck disable=SC2086
  set -- $1

  local type="$1"
  shift

  case "$type" in
  branch) handle_branch "$@" ;;
  cron) handle_cron "$@" ;;
  edge) handle_edge "$@" ;;
  pr) handle_pr "$@" ;;
  raw) handle_raw "$@" ;;
  semver) handle_semver "$@" ;;
  sha) handle_sha "$@" ;;
  tag) handle_tag "$@" ;;
  \#) ;;
  *)
    echo "Invalid type '$type'." >&2
    exit 1
    ;;
  esac
}

remove_duplicate_tags() {
  [[ ! -f "$tags_file" ]] && return
  awk '!seen[$0]++' "$tags_file" >/tmp/.tags
  mv /tmp/.tags "$tags_file"
}

main() {
  while IFS= read -r command; do
    (
      handle_command "$command"
    )
  done <<<"$commands"

  remove_duplicate_tags
}

main
