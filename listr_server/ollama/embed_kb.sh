#!/usr/bin/env bash
# Parses ./kb.md into KB entries and embeds each one via the Ollama
# /api/embeddings endpoint, writing the results (entry fields + vector)
# to ./kb_embeddings.json for the app to load and search at runtime.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KB_FILE="${1:-$SCRIPT_DIR/kb.md}"
OUT_FILE="${2:-$SCRIPT_DIR/kb_embeddings.json}"
OLLAMA_URL="http://localhost:11434"
EMBED_MODEL="nomic-embed-text"

if [[ ! -f "$KB_FILE" ]]; then
  echo "Error: KB file '$KB_FILE' not found." >&2
  exit 1
fi

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/}"
  printf '%s' "$s"
}

# Turn each "## " block in kb.md into one tab-free record, fields separated
# by 0x1F (unit separator) and repeatable "- Params:" lines joined by 0x1E
# (record separator) so bash can split on them without colliding with prose.
records=$(awk -v US="$(printf '\x1f')" -v PSEP="$(printf '\x1e')" '
  BEGIN { RS="" }
  {
    endpoint=""; method=""; description=""; examples=""; params=""
    n = split($0, lines, "\n")
    for (i = 1; i <= n; i++) {
      line = lines[i]
      if (line ~ /^##[ \t]+/) {
        sub(/^##[ \t]+/, "", line); endpoint = line
      } else if (line ~ /^-[ \t]*Method:[ \t]*/) {
        sub(/^-[ \t]*Method:[ \t]*/, "", line); method = line
      } else if (line ~ /^-[ \t]*Description:[ \t]*/) {
        sub(/^-[ \t]*Description:[ \t]*/, "", line); description = line
      } else if (line ~ /^-[ \t]*Examples:[ \t]*/) {
        sub(/^-[ \t]*Examples:[ \t]*/, "", line); examples = line
      } else if (line ~ /^-[ \t]*Params:[ \t]*/) {
        sub(/^-[ \t]*Params:[ \t]*/, "", line)
        params = (params == "" ? line : params PSEP line)
      }
    }
    if (endpoint != "") {
      print endpoint US method US description US examples US params
    }
  }
' "$KB_FILE")

if [[ -z "$records" ]]; then
  echo "Error: no KB entries found in '$KB_FILE'." >&2
  exit 1
fi

entry_count=$(printf '%s\n' "$records" | wc -l)
echo "Embedding $entry_count KB entry/entries using $EMBED_MODEL..."

entries_json=()

while IFS=$'\x1f' read -r endpoint method description examples_raw params_raw; do
  # Build the array of example query strings and the comma-joined text used
  # for the embedding prompt (mirrors build_embed_text in test_lama.py).
  example_items=()
  IFS=';' read -ra raw_examples <<< "$examples_raw"
  for ex in "${raw_examples[@]}"; do
    ex="$(trim "$ex")"
    [[ -z "$ex" ]] && continue
    example_items+=("$ex")
  done

  examples_joined=""
  examples_json=""
  for ex in "${example_items[@]}"; do
    examples_joined+="${examples_joined:+, }$ex"
    examples_json+="${examples_json:+,}\"$(json_escape "$ex")\""
  done

  embed_text="$method $endpoint
$description
Example queries: $examples_joined"

  # Build the parameters JSON object from any "- Params:" lines.
  params_json=""
  if [[ -n "$params_raw" ]]; then
    IFS=$'\x1e' read -ra param_lines <<< "$params_raw"
    for pline in "${param_lines[@]}"; do
      if [[ $pline =~ ^([^\(]+)\(([^,]+),[[:space:]]*([^,]+),[[:space:]]*([^\)]+)\):[[:space:]]*(.*)$ ]]; then
        pname="$(trim "${BASH_REMATCH[1]}")"
        ptype="$(trim "${BASH_REMATCH[2]}")"
        preq="$(trim "${BASH_REMATCH[3]}")"
        pin="$(trim "${BASH_REMATCH[4]}")"
        pdesc="$(trim "${BASH_REMATCH[5]}")"
        [[ "$preq" == "required" ]] && preq_bool=true || preq_bool=false
        param_obj="\"$(json_escape "$pname")\":{\"type\":\"$(json_escape "$ptype")\",\"required\":$preq_bool,\"in\":\"$(json_escape "$pin")\",\"description\":\"$(json_escape "$pdesc")\"}"
        params_json+="${params_json:+,}$param_obj"
      fi
    done
  fi

  response=$(curl -sf "$OLLAMA_URL/api/embeddings" \
    -d "{\"model\":\"$EMBED_MODEL\",\"prompt\":\"$(json_escape "$embed_text")\"}")

  embedding=$(printf '%s' "$response" | sed -n 's/.*"embedding":\[\([^]]*\)\].*/\1/p')
  if [[ -z "$embedding" ]]; then
    echo "Error: failed to embed '$method $endpoint' — response: $response" >&2
    exit 1
  fi

  entry_json="{\"endpoint\":\"$(json_escape "$endpoint")\",\"method\":\"$(json_escape "$method")\",\"description\":\"$(json_escape "$description")\",\"example_queries\":[$examples_json],\"parameters\":{$params_json},\"embedding\":[$embedding]}"
  entries_json+=("$entry_json")

  echo "  * $method $endpoint"
done <<< "$records"

joined_entries=$(IFS=,; echo "${entries_json[*]}")
printf '[%s]' "$joined_entries" > "$OUT_FILE"

echo
echo "Wrote $entry_count embedded KB entry/entries to $OUT_FILE"
