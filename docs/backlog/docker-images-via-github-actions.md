# Backlog: build the self-hosted Docker images in GitHub Actions

created: 2026-11-15

## What

Move the Docker image build out of the local release script into a GitHub
Actions workflow, the same way desktop and mobile already build in Actions.

Today `releases/release.sh` runs `cd dockerhub && make release VERSION=…`,
which builds `solyto/api-nginx`, `solyto/api-php` and `solyto/app` for
`linux/amd64,linux/arm64` with buildx on the release machine
(`dockerhub/Makefile`, target `new-release`). Instead:

- **Workflow in the dockerhub repo** (e.g. `.github/workflows/release.yml`),
  started by `release.sh` with
  `gh workflow run release.yml -R solyto/dockerhub -f version=$VERSION`,
  replacing the `make release` call.
- **Native runners per architecture:** a matrix with `ubuntu-24.04` (amd64)
  and `ubuntu-24.04-arm` (arm64). Each job checks out api/app at the release
  tag (what `fetch-api-src` / `fetch-app-src` do today), builds its
  architecture and pushes by digest.
- **Merge job:** combines both digests into one multi-arch tag
  (`docker buildx imagetools create`) for `:$VERSION` and `:latest`.
- **Layer cache** in GitHub's cache (`cache-from` / `cache-to: type=gha`,
  scoped per image and architecture).
- **Docker Hub README** (today `push-readme-api` / `push-readme-app` with
  `docker pushrm`): replace with a ready-made action, e.g.
  `peter-evans/dockerhub-description`.

`release.sh` keeps everything else (version bumps, tags, GitHub releases,
desktop, mobile): that part is fast and needs local git access to several
repos.

## Why

On an x86_64 machine, buildx builds arm64 under QEMU emulation, which is many
times slower than native. The 1.1.3 release log showed `docker-php-ext-install`
running over 300 s for arm64 (88 s for amd64), followed by `pecl install redis
imagick`. The release command blocks the machine for that whole time.

With native arm64 runners nothing is emulated, both architectures build in
parallel, and `release.sh` returns after a few seconds. A build error then
shows up in the Actions log instead of the terminal, like for desktop today.

## Prerequisites

- Docker Hub access token as repo secrets in the dockerhub repo, e.g.
  `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`.
- Read access to `solyto/api` and `solyto/app` from the workflow, if those
  repos are private (a deploy key or a fine-grained token as a secret).
- arm64 runners (`ubuntu-24.04-arm`) are free for public repos, and the
  dockerhub repo is public (confirmed 2026-11-15).

## Notes

- Do the Dockerfile fixes first (planned separately):
  - `dockerhub/api/api-php.Dockerfile`: move `COPY --from=composer:2` after
    `docker-php-ext-install` and `pecl`. The moving `composer:2` tag
    currently invalidates the cache for every later step, so the extensions
    are compiled again on every release.
  - `dockerhub/app/app.Dockerfile`: run the builder stage with
    `--platform=$BUILDPLATFORM`, so Vite builds once.
  
  Both help the local build and the workflow alike.
- Keep the local `make build-*-image` targets for testing images without
  pushing.
- Check: `make release VERSION=x.y.z` (or `release.sh`) finishes without
  building locally, the workflow pushes `:x.y.z` and `:latest` for both
  architectures (`docker buildx imagetools inspect solyto/api-php:x.y.z`
  lists amd64 and arm64), and a self-hosted stack on an arm64 machine starts
  with the new images.
