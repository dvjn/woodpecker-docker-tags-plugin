---
name: Docker Tags
description: Plugin to generate tags for building docker images from Git reference and CI events.

author: dvjn
tags: [docker]
containerImage: ghcr.io/dvjn/woodpecker-docker-tags-plugin
containerImageUrl: https://github.com/dvjn/woodpecker-docker-tags-plugin/pkgs/container/woodpecker-docker-tags-plugin
url: https://github.com/dvjn/woodpecker-docker-tags-plugin
---

Woodpecker CI plugin to generate tags for building docker images from Git reference and CI events.

## Settings

| Name      | Default | Description                       |
| --------- | ------- | --------------------------------- |
| tags      | _none_  | Configuration for generating tags |
| tags_file | .tags   | File to save generated tags       |

## Example

```yaml
steps:
  - name: generate_docker_tags
    image: ghcr.io/dvjn/woodpecker-docker-tags-plugin
    settings:
      tags: |
        edge
        pr
        semver --format {{major}}
        semver --format {{major}}.{{minor}}
        semver --format {{version}}
        cron --format nightly-%Y%m%d
        sha
```

## `tag` input

This is the main input for this plugin. This is a multiline string. Each line
represents a different tag to be applied. Each line is in the form of a cli
command.

All the available commands are:

- [branch](#branch)
- [cron](#cron)
- [edge](#edge)
- [pr](#pr)
- [raw](#raw)
- [semver](#semver)
- [sha](#sha)
- [tag](#tag)

### `branch`

Processes the branch name with an optional prefix and use it as a tag value.

| Option           | Default | Description                       |
| ---------------- | ------- | --------------------------------- |
| `-p`, `--prefix` | _empty_ | Adds a prefix to the branch name. |

**Examples:**

| Command         | Branch                | Output                   |
| --------------- | --------------------- | ------------------------ |
| `branch`        | `feature/add-logging` | `feature-add-logging`    |
| `branch -p br-` | `feature/add-logging` | `br-feature-add-logging` |

### `cron`

Works for cron events and uses the specified date format to generate the tag
name. This uses GNU coreutils date utility to parse the date. You can find the
reference for using the format
[here](https://www.gnu.org/software/coreutils/manual/html_node/Date-format-specifiers.html).

| Option           | Default  | Description                |
| ---------------- | -------- | -------------------------- |
| `-f`, `--format` | `%Y%m%d` | Specifies the date format. |

**Examples:**

| Command                    | Date         | Output               |
| -------------------------- | ------------ | -------------------- |
| `cron`                     | `2024-06-02` | `20240602`           |
| `cron -f nightly-%Y-%m-%d` | `2024-06-02` | `nightly-2024-06-02` |

### `edge`

Let's you mark a branch as the edge/latest branch.

| Option           | Default              | Description                      |
| ---------------- | -------------------- | -------------------------------- |
| `-v`, `--value`  | `edge`               | Specifies the value for the tag. |
| `-b`, `--branch` | _repository default_ | Specifies the branch name.       |

**Examples:**

| Command              | Branch | Output   |
| -------------------- | ------ | -------- |
| `edge`               | `main` | `edge`   |
| `edge -v latest`     | `main` | `latest` |
| `edge -b dev -v dev` | `dev`  | `dev`    |

### `pr`

Processes the pull request name with an optional prefix and use it as a tag value.

| Option           | Default | Description                             |
| ---------------- | ------- | --------------------------------------- |
| `-p`, `--prefix` | `pr-`   | Adds a prefix to the pull request name. |

**Examples:**

| Command       | Pull Request ID | Output     |
| ------------- | --------------- | ---------- |
| `pr`          | `123`           | `pr-123`   |
| `pr -p pull-` | `123`           | `pull-123` |

### `semver`

Parses the git tag name semver format uses it to generate the tag value.

| Option           | Default       | Description                       |
| ---------------- | ------------- | --------------------------------- |
| `-f`, `--format` | `{{version}}` | Specifies the format for the tag. |
| `-v`, `--value`  | _commit tag_  | Specifies the value for the tag.  |

`format` argument supports the following expressions:

- `{{raw}}`: the actual tag
- `{{version}}`: cleaned version
- `{{major}}`: major version identifier
- `{{minor}}`: minor version identifier
- `{{patch}}`: patch version identifier

**Examples:**

| Command                          | Tag          | Output      |
| -------------------------------- | ------------ | ----------- |
| `semver`                         | `v1.2.3`     | `1.2.3`     |
| `semver -f {{raw}}`              | `v1.2.3`     | `v1.2.3`    |
| `semver -f {{version}}`          | `v1.2.3`     | `1.2.3`     |
| `semver -f ver-{{major}}`        | `v1.2.3`     | `ver-1`     |
| `semver -f v{{major}}.{{minor}}` | `v1.2.3`     | `v1.2`      |
| `semver -f {{patch}}`            | `v1.2.3`     | `3`         |
| `semver -f {{version}}`          | `v1.2.3-rc4` | `1.2.3-rc4` |
| `semver -f {{major}}.{{minor}}`  | `v1.2.3-rc4` | `1.2`       |
| `semver -f {{patch}}`            | `v1.2.3-rc4` | `3`         |

### `raw`

Outputs any custom tag.

| Option          | Default | Description                      |
| --------------- | ------- | -------------------------------- |
| `-v`, `--value` | _empty_ | Specifies the value for the tag. |

**Examples:**

| Command       | Output |
| ------------- | ------ |
| `raw -v abcd` | `abcd` |

### `sha`

Uses the commit SHA as tag output.

| Option           | Default | Description                    |
| ---------------- | ------- | ------------------------------ |
| `-l`, `--long`   | `false` | Use the full 40 character SHA. |
| `-p`, `--prefix` | `sha-`  | Adds a prefix to the SHA.      |

**Examples:**

| Command          | Output                                         |
| ---------------- | ---------------------------------------------- |
| `sha`            | `sha-abcdef12`                                 |
| `sha -l`         | `sha-abcdef1234567890abcdef1234567890abcdef12` |
| `sha -p commit-` | `commit-abcdef12`                              |

### `tag`

Uses git tag for the output tags.

**Examples:**

| Command | Tag      | Output   |
| ------- | -------- | -------- |
| `tag`   | `v1.0.0` | `v1.0.0` |
