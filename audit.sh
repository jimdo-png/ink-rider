#!/bin/sh
# INK RIDER — pre-publish security audit.
#
# Greps a built HTML file for anything that would break the security posture:
# network calls, dynamic code execution, external resources, cookies, or
# credentials. Also checks the required Content-Security-Policy tag is present.
#
#   ./audit.sh [file]        (defaults to index.html)
#
# Exit 0 = PASS, exit 1 = FAIL. INFO findings never fail the run.
# Portable POSIX sh + BSD/GNU grep. No network access, reads one file.

set -u

FILE="${1:-index.html}"

if [ ! -f "$FILE" ]; then
  printf 'FAIL: no such file: %s\n' "$FILE" >&2
  exit 1
fi

FAILS=0
INFOS=0

# Word-ish boundary that works on both BSD and GNU grep -E.
B='(^|[^A-Za-z0-9_$.])'

# fail <label> <extended-regex> [max-lines-to-show]
fail_on() {
  label="$1"; pat="$2"
  hits=$(grep -nE -e "$pat" "$FILE" 2>/dev/null | head -5)
  if [ -n "$hits" ]; then
    n=$(grep -cE -e "$pat" "$FILE" 2>/dev/null)
    printf '  [FAIL] %-28s %s match(es)\n' "$label" "$n"
    printf '%s\n' "$hits" | cut -c1-160 | sed 's/^/           /'
    FAILS=$((FAILS + 1))
  else
    printf '  [ ok ] %-28s clean\n' "$label"
  fi
}

# report_on <label> <extended-regex> — never fails the run
report_on() {
  label="$1"; pat="$2"
  n=$(grep -cE -e "$pat" "$FILE" 2>/dev/null)
  if [ "$n" -gt 0 ]; then
    printf '  [INFO] %-28s %s match(es) — expected, not a failure\n' "$label" "$n"
    INFOS=$((INFOS + 1))
  else
    printf '  [ ok ] %-28s none\n' "$label"
  fi
}

printf '\n=== INK RIDER security audit ===\n'
printf 'file: %s (%s bytes)\n' "$FILE" "$(wc -c < "$FILE" | tr -d ' ')"

printf '\n-- Content-Security-Policy --\n'
if grep -qE '<meta[^>]+http-equiv=["'"'"']?[Cc]ontent-[Ss]ecurity-[Pp]olicy' "$FILE"; then
  printf '  [ ok ] %-28s present\n' 'CSP meta tag'
  for d in "default-src 'none'" "base-uri 'none'" "form-action 'none'" \
           "frame-ancestors 'none'"; do
    if grep -qF "$d" "$FILE"; then
      printf '  [ ok ] %-28s present\n' "$d"
    else
      printf '  [FAIL] %-28s MISSING from CSP\n' "$d"
      FAILS=$((FAILS + 1))
    fi
  done
  # connect-src must NOT be granted; default-src 'none' has to stay in charge.
  if grep -qE 'connect-src' "$FILE"; then
    printf '  [FAIL] %-28s CSP grants network access\n' 'connect-src'
    FAILS=$((FAILS + 1))
  else
    printf '  [ ok ] %-28s not granted (no network)\n' 'connect-src'
  fi
else
  printf '  [FAIL] %-28s MISSING — build must not ship\n' 'CSP meta tag'
  FAILS=$((FAILS + 1))
fi

printf '\n-- Network calls (must be none) --\n'
fail_on 'fetch('           "${B}fetch[[:space:]]*\("
fail_on 'XMLHttpRequest'   'XMLHttpRequest'
fail_on 'WebSocket'        'WebSocket'
fail_on 'sendBeacon'       'sendBeacon'
fail_on 'EventSource'      'EventSource'

printf '\n-- Dynamic code execution (must be none) --\n'
fail_on 'eval('            "${B}eval[[:space:]]*\("
fail_on 'new Function'     'new[[:space:]]+Function'
fail_on 'import('          "${B}import[[:space:]]*\("
fail_on 'setTimeout("str") ' 'set(Timeout|Interval)[[:space:]]*\([[:space:]]*["'"'"']'

printf '\n-- External resources (must be none) --\n'
# w3.org namespace URIs are XML declarations, never fetched — allowlisted.
URLS=$(grep -oE 'https?://[^"'"'"' )>]+' "$FILE" 2>/dev/null \
        | grep -vE '^https?://(www\.)?w3\.org/' \
        | grep -vE '^https?://jimdo-png\.github\.io/ink-rider' \
        | sort -u)
if [ -n "$URLS" ]; then
  printf '  [FAIL] %-28s\n' 'absolute http(s) URL'
  printf '%s\n' "$URLS" | head -10 | sed 's/^/           /'
  FAILS=$((FAILS + 1))
else
  printf '  [ ok ] %-28s none (bar w3.org namespaces)\n' 'absolute http(s) URL'
fi
fail_on '<script src='     '<script[^>]+src[[:space:]]*='
fail_on 'protocol-rel //'  '(src|href)[[:space:]]*=[[:space:]]*["'"'"']//'
fail_on '@import'          '@import'
# <link> is only acceptable pointing at a data: URI (inline favicon).
BADLINK=$(grep -oE '<link[^>]+href[[:space:]]*=[[:space:]]*["'"'"'][^"'"'"']*' "$FILE" 2>/dev/null \
           | grep -vE 'href[[:space:]]*=[[:space:]]*["'"'"']data:')
if [ -n "$BADLINK" ]; then
  printf '  [FAIL] %-28s non-data: href\n' '<link href='
  printf '%s\n' "$BADLINK" | head -5 | cut -c1-160 | sed 's/^/           /'
  FAILS=$((FAILS + 1))
else
  printf '  [ ok ] %-28s none or data: only\n' '<link href='
fi

printf '\n-- Tracking / credentials (must be none) --\n'
fail_on 'document.cookie'  'document\.cookie'
fail_on 'GitHub token'     'gh[pousr]_[A-Za-z0-9]{16,}'
fail_on 'OpenAI-style key' "${B}sk-[A-Za-z0-9_-]{16,}"
fail_on 'AWS access key'   'AKIA[0-9A-Z]{12,}'
fail_on 'private key block' '\-\-\-\-\-BEGIN'
fail_on 'email address'    '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
fail_on 'local user path'  '/Users/[A-Za-z0-9._-]+'

printf '\n-- Expected behaviour (reported, never fails) --\n'
report_on 'localStorage.setItem' 'localStorage\.setItem'
report_on 'localStorage.getItem' 'localStorage\.getItem'

printf '\n===============================\n'
if [ "$FAILS" -eq 0 ]; then
  printf 'PASS — %s is clean. %s informational note(s).\n' "$FILE" "$INFOS"
  printf 'Safe to commit and publish.\n\n'
  exit 0
else
  printf 'FAIL — %s finding(s) in %s. DO NOT PUBLISH.\n' "$FAILS" "$FILE"
  printf 'Fix the [FAIL] lines above and re-run.\n\n'
  exit 1
fi
