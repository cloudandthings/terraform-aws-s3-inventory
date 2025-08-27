# Contributing

When contributing to this repository, please first discuss the change you wish to make via issue,
email, or any other method with the owners of this repository before making a change.

Please note we have a code of conduct, please follow it in all your interactions with the project.

## Development environment

We suggest using [VSCode](https://code.visualstudio.com/)

### With GitHub Codespaces

Simply open this project in GitHub Codespaces to continue.

### Locally, with Dev Containers

You can use [Visual Studio Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers) to build a local, isolated development environment.

You will need to have [Docker](https://www.docker.com/) installed.

Open this project in a VSCode Remote Container to get started.

### Locally, without Dev Containers

We recommend using [mise-en-place](https://mise.jdx.dev/).

Once installed and activated, `mise` will in turn install and configure the correct version of all required dev tools and set environment variables.

### Locally, without mise

As a last resort you can try to manually install/configure what is specified by the [mise.toml](/mise.toml) file, but this is not recommended.

#### Repository / workspace configuration

(Only applicable if developing without Dev Containers)

1. Create and develop in a Python virtual environment, with `python3 -m venv .venv && source .venv/bin/activate`
1. Install `requirements.txt` into the virtual environment, with `pip install -r requirements.txt`
1. Install pre-commit hooks specific to this repository, with `pre-commit install`.

### Reducing clutter

To improve focus while developing, you may want to configure VSCode to hide all files beginning with `.` from the Explorer view.
These files are typically related to low-level environment configuration.
To do so, you could add `"**/.*"` to the `files.exclude` setting.

## Pull Request Process

1. Update the code, examples and/or documentation where appropriate.
1. Ideally, follow [conventional commits](https://www.conventionalcommits.org/) for your commit messages.
1. Locally run pre-commit hooks `pre-commit run -a`
1. Locally run tests via `pytest`
1. Create pull request
1. Once all checks pass, notify a reviewer.

Once all outstanding comments and checklist items have been addressed, your contribution will be merged! Merged PRs will be included in the next release. The terraform-aws-vpc maintainers take care of updating the CHANGELOG as they merge.

## Checklists for contributions

- [ ] Add [semantics prefix](#semantic-pull-requests) to your PR or Commits (at least one of your commit groups)
- [ ] CI tests are passing
- [ ] README.md has been updated after any changes to variables and outputs. See https://github.com/cloudandthings/terraform-aws-clickops-notifer/#doc-generation
- [ ] Run pre-commit hooks `pre-commit run -a`

## Semantic Pull Requests

To generate changelog, Pull Requests or Commits must have semantic and must follow conventional specs below:

- `feat:` for new features
- `fix:` for bug fixes
- `improvement:` for enhancements
- `docs:` for documentation and examples
- `refactor:` for code refactoring
- `test:` for tests
- `ci:` for CI purpose
- `chore:` for chores stuff

The `chore` prefix skipped during changelog generation. It can be used for `chore: update changelog` commit message by example.
