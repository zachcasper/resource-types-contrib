#!/bin/bash
set -e

# Parse types.yaml to extract resource type names and definition file paths
# Produces tab-separated lines: tgz_name\tfile_path
entries=$(awk '
  /^[[:space:]]*#/ { next }
  /^[[:space:]]+[A-Za-z].*:[[:space:]]*$/ && !/definitionLocation/ {
    name = $0
    gsub(/^[[:space:]]+/, "", name)
    gsub(/:.*$/, "", name)
  }
  /definitionLocation:/ {
    path = $0
    sub(/.*definitionLocation:[[:space:]]*/, "", path)
    tgz = name
    sub(/.*\//, "", tgz)
    tgz = tolower(tgz)
    print tgz "\t" path
  }
' types.yaml)

echo Creating Resource Types
while IFS=$'\t' read -r tgz_name file_path; do
  rad bicep publish-extension --from-file "$file_path" --target "${tgz_name}.tgz"
done <<< "$entries"

echo Creating bicepconfig.json

# Build extensions entries
extensions=""
while IFS=$'\t' read -r tgz_name file_path; do
  entry="      \"${tgz_name}\": \"./${tgz_name}.tgz\""
  if [ -n "$extensions" ]; then
    extensions="${extensions},
${entry}"
  else
    extensions="$entry"
  fi
done <<< "$entries"

cat > bicepconfig.json << EOF
{
  "extensions": {
${extensions},
      "radius": "br:biceptypes.azurecr.io/radius:latest"
  }
}
EOF
