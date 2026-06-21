#!/usr/bin/env bash

set -euo pipefail

repo="KimuSoft/muvel-public"
api_url="https://api.github.com/repos/$repo/releases/latest"

headers=(
  --header "Accept: application/vnd.github+json"
  --header "X-GitHub-Api-Version: 2022-11-28"
)

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  headers+=(--header "Authorization: Bearer $GITHUB_TOKEN")
fi

release="$(curl --fail --silent --show-error --location "${headers[@]}" "$api_url")"
tag="$(jq --exit-status --raw-output '.tag_name' <<<"$release")"
version="${tag#v}"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.-]+)?$ ]]; then
  echo "Unexpected release tag: $tag" >&2
  exit 1
fi

current_version="$(jq --raw-output '.version' sources.json)"
if [[ "$version" == "$current_version" ]]; then
  echo "Muvel $version is already current."
  exit 0
fi

asset_url() {
  local name="$1"
  local url

  url="$(jq --exit-status --raw-output \
    --arg name "$name" \
    '.assets[] | select(.name == $name) | .browser_download_url' \
    <<<"$release")"

  if [[ -z "$url" ]]; then
    echo "Release asset not found: $name" >&2
    exit 1
  fi

  printf '%s\n' "$url"
}

prefetch_hash() {
  nix store prefetch-file --json "$1" | jq --exit-status --raw-output '.hash'
}

linux_url="$(asset_url "Muvel_${version}_amd64.AppImage")"
darwin_aarch64_url="$(asset_url "Muvel_${version}_aarch64.dmg")"
darwin_x86_64_url="$(asset_url "Muvel_${version}_x64.dmg")"

linux_hash="$(prefetch_hash "$linux_url")"
darwin_aarch64_hash="$(prefetch_hash "$darwin_aarch64_url")"
darwin_x86_64_hash="$(prefetch_hash "$darwin_x86_64_url")"

jq --null-input \
  --arg version "$version" \
  --arg linux_url "$linux_url" \
  --arg linux_hash "$linux_hash" \
  --arg darwin_aarch64_url "$darwin_aarch64_url" \
  --arg darwin_aarch64_hash "$darwin_aarch64_hash" \
  --arg darwin_x86_64_url "$darwin_x86_64_url" \
  --arg darwin_x86_64_hash "$darwin_x86_64_hash" \
  '{
    version: $version,
    linux: {
      x86_64: { url: $linux_url, hash: $linux_hash }
    },
    darwin: {
      aarch64: { url: $darwin_aarch64_url, hash: $darwin_aarch64_hash },
      x86_64: { url: $darwin_x86_64_url, hash: $darwin_x86_64_hash }
    }
  }' >sources.json

echo "Updated Muvel $current_version -> $version."
