
export ARTIFACTORY_CMD="jfrog rt"

configure_jfrog_client() {
  local endpoint=$1
  local username=$2
  local password=$3

  $ARTIFACTORY_CMD c --url $endpoint --user $username --password $password --interactive=false
}

create_artifact_path() {
  local file_pattern=$1
  local repository=$2
  local folder=$3 # Needs to be last as it may not be provided

  if [ -n "${folder}" ]; then
    echo "${repository}/${folder}/${file_pattern}"
  else
    echo "${repository}/${file_pattern}"
  fi
}

# Using jq regex so we can support groups
applyRegex_version() {
  local regex=$1
  local file=$2

  jq -n "{
  version: $(echo $file | jq -R .)
  }" | jq --arg v "$regex" '.version | capture($v)' | jq -r '.version'
}

get_current_version() {
  local regex=$1
  local folder_contents=$2

  echo "$folder_contents" | jq --arg v "$regex" '[.[].path | capture($v)]' | jq 'sort_by(.version | split(".") | map(tonumber))' | jq '[.[length-1] | {version: .version}]'
}

# Return all versions
get_all_versions() {
  local regex=$1
  local folder_contents=$2

  echo "$folder_contents" | jq --arg v "$regex" '[.[].path | capture($v)]' | jq 'sort_by(.version | split(".") | map(tonumber))' | jq '[.[] | {version: .version}]'
}

get_files() {
  local regex="(?<path>$1)"
  local folder_contents=$2

  echo "$folder_contents" | jq --arg v "$regex" '[.[].path | capture($v)]' | jq 'sort_by(.version  | split(".") | map(tonumber))' | jq '[.[] | {path: .path, version: .version}]'
}

artifactory_get_folder_contents() {
  $ARTIFACTORY_CMD s "$1"
}

# retrieve current from artifactory
# e.g url=http://your-host-goes-here:8081/artifactory/api/storage/your-path-goes-here
#     regex=ecd-front-(?<version>.*).tar.gz
artifactory_current_version() {
  local search_pattern=$1
  local regex=$2

  local folder_contents=$(artifactory_get_folder_contents "$search_pattern")

  get_current_version "$regex" "$folder_contents"

}


# Return all versions
artifactory_versions() {
  local search_pattern=$1
  local regex=$2

  local folder_contents=$(artifactory_get_folder_contents "$search_pattern")

  get_all_versions "$regex" "$folder_contents"

}

# return uri and version of all files
artifactory_files() {
  local search_pattern=$1
  local regex=$2

  local folder_contents=$(artifactory_get_folder_contents "$search_pattern")

  get_files "$regex" "$folder_contents"
}

in_file_with_version() {
  local search_pattern=$1
  local regex="(?<path>$2)"
  local version=$3

  result=$(artifactory_files "$search_pattern" "$regex")
  echo $result | jq --arg v "$version" '[foreach .[] as $item ([]; $item ; if $item.version == $v then $item else empty end)]'

}

# return the list of versions from provided version
check_version() {
  local search_pattern=$1
  local regex=$2
  local version=$3

  result=$(artifactory_versions "$search_pattern" "$regex")
  echo $result | jq --arg v "$version" '[foreach .[] as $item ([]; $item ; if $item.version >= $v then $item else empty end)]'

}
