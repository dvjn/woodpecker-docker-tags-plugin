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

- [`branch`](#branch)
- [`cron`](#cron)
- [`edge`](#edge)
- [`pr`](#pr)
- [`raw`](#raw)
- [`semver`](#semver)
- [`sha`](#sha)
- [`tag`](#tag)

---

### `branch`

Generates tags from branch names for push events.

```yaml
tags: |
  # minimal
  branch
  # with custom prefix
  branch -p branch-
```

**Options:**

| Option           | Default | Description                       |
| ---------------- | ------- | --------------------------------- |
| `-p`, `--prefix` | _empty_ | Adds a prefix to the branch name. |

**Examples:**

| Command         | Branch                | Output                   |
| --------------- | --------------------- | ------------------------ |
| `branch`        | `feature/add-logging` | `feature-add-logging`    |
| `branch -p br-` | `feature/add-logging` | `br-feature-add-logging` |

---

### `cron`

Generates datetime based tags on cron events.

```yaml
tags: |
  # minimal
  cron
  # with custom format
  cron -f %Y-%m-%d
```

**Options:**

| Option           | Default  | Description                                                                                                                                                                              |
| ---------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-f`, `--format` | `%Y%m%d` | The tag format. This supports GNU/date format.<br>You can find the reference for the format [here](https://www.gnu.org/software/coreutils/manual/html_node/Date-format-specifiers.html). |

**Examples:**

| Command                    | Output               |
| -------------------------- | -------------------- |
| `cron`                     | `20240602`           |
| `cron -f nightly-%Y-%m-%d` | `nightly-2024-06-02` |

---

### `edge`

Generates edge tags for the default branch. The `edge` tag reflects the last
commit of the active branch on your Git repository.

```yaml
tags: |
  # minimal
  edge
  # with custom tag value of "next"
  edge -v next
  # using branch other than the repository default branch
  edge -b dev
```

**Options:**

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

---

### `pr`

Generates tag on pull_request event, based on the pull request's id.

```yaml
tags: |
  # minimal
  pr
  # using custom prefix for tags
  pr -p pull-
```

**Options:**

| Option           | Default | Description                             |
| ---------------- | ------- | --------------------------------------- |
| `-p`, `--prefix` | `pr-`   | Adds a prefix to the pull request name. |

**Examples:**

| Command       | Pull Request ID | Output     |
| ------------- | --------------- | ---------- |
| `pr`          | `123`           | `pr-123`   |
| `pr -p pull-` | `123`           | `pull-123` |

---

### `semver`

Generates tags based on semver versions parsed from pushed git tags.

```yaml
tags: |
  # minimal
  smever
  # generate major version tag
  semver -f {{major}}
  # generate major minor version tag
  semver -f {{major}}.{{minor}}
```

**Options:**

| Option           | Default       | Description                       |
| ---------------- | ------------- | --------------------------------- |
| `-f`, `--format` | `{{version}}` | Specifies the format for the tag. |
| `-v`, `--value`  | _commit tag_  | Specifies the value for the tag.  |

The `format` argument supports the following expressions:

- `{{raw}}`: the actual tag
- `{{version}}`: the cleaned up version
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

---

### `raw`

Generates a raw preconfigured tag on any event.

```yaml
tags: |
  # minimal
  raw -v last-built
```

| Option          | Default | Description                      |
| --------------- | ------- | -------------------------------- |
| `-v`, `--value` | _empty_ | Specifies the value for the tag. |

**Examples:**

| Command       | Output |
| ------------- | ------ |
| `raw -v abcd` | `abcd` |

---

### `sha`

Generates tag using the commit SHA.

```yaml
tags: |
  # minimal
  sha
  # generates tag with full sha
  sha -l
  # use custom prefix for sha tag
  sha -p commit-
```

**Options:**

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

---

### `tag`

Generates tag from pushed git tag.

```yaml
tags: |
  # minimal
  tag
```

**Examples:**

| Command | Tag      | Output   |
| ------- | -------- | -------- |
| `tag`   | `v1.0.0` | `v1.0.0` |
