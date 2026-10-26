#!/bin/bash
# Assembles ram.guard.plg from the files in src/. All files are embedded in the
# .plg, so the plugin can be installed from that single file.
#
#   ./build.sh                    version = today's date
#   VERSION=2026.10.26.1 ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

VERSION=${VERSION:-$(date +%Y.%m.%d)}
AUTHOR=${AUTHOR:-factorjx}
# Where the .plg is published; Unraid checks it for updates. Set to empty for a local-only build.
PLUGIN_URL=${PLUGIN_URL-https://raw.githubusercontent.com/factorjx/unraid-ram-guard/main/ram.guard.plg}
OUT=ram.guard.plg

# inline SRC DEST [MODE]: a FILE element with SRC embedded as CDATA. The CDATA
# starts right after <INLINE> so that the file's first line stays first.
inline() {
  if grep -q ']]>' "$1"; then
    echo "$1 contains ']]>' and cannot be embedded" >&2
    exit 1
  fi
  printf '<FILE Name="%s"%s>\n<INLINE><![CDATA[' "$2" "${3:+ Mode=\"$3\"}"
  cat "$1"
  printf ']]></INLINE>\n</FILE>\n\n'
}

{
cat <<EOF
<?xml version='1.0' standalone='yes'?>
<!DOCTYPE PLUGIN [
<!ENTITY name      "ram.guard">
<!ENTITY author    "$AUTHOR">
<!ENTITY version   "$VERSION">
<!ENTITY launch    "Settings/RamGuard">
<!ENTITY plugdir   "/usr/local/emhttp/plugins/&name;">
<!ENTITY pluginURL "$PLUGIN_URL">
]>

<PLUGIN name="&name;" author="&author;" version="&version;" launch="&launch;"${PLUGIN_URL:+ pluginURL=\"&pluginURL;\"} icon="shield" min="6.9.0">

<CHANGES>
### 2026.10.26.2
- Fix: updates now replace the plugin files (the plugin manager does not overwrite existing files)

### 2026.10.26.1
- English plugin description and README

### 2026.10.26
- RAM monitoring: warning at 90%, the largest container is stopped at 95%
- Exclusions, spike protection, cooldown between stops, dry run mode
- ZFS ARC counted as free memory
</CHANGES>

<!-- Stop a running daemon and remove the old files: the plugin manager skips files that already exist -->
<FILE Run="/bin/bash">
<INLINE>
if [ -x &plugdir;/scripts/rc.ramguard ]; then &plugdir;/scripts/rc.ramguard stop; fi
rm -rf &plugdir;
mkdir -p &plugdir;/scripts &plugdir;/include
</INLINE>
</FILE>

EOF

inline src/default.cfg '&plugdir;/default.cfg'
inline src/README.md '&plugdir;/README.md'
inline src/RamGuard.page '&plugdir;/RamGuard.page'
inline src/include/status.php '&plugdir;/include/status.php'
inline src/scripts/ramguard '&plugdir;/scripts/ramguard' 0755
inline src/scripts/rc.ramguard '&plugdir;/scripts/rc.ramguard' 0755

cat <<'EOF'
<FILE Run="/bin/bash">
<INLINE>
&plugdir;/scripts/rc.ramguard start
echo "RAM Guard &version; установлен. Настройки: Settings, раздел RAM Guard"
</INLINE>
</FILE>

<FILE Run="/bin/bash" Method="remove">
<INLINE>
&plugdir;/scripts/rc.ramguard stop
rm -rf &plugdir; /tmp/&name; /boot/config/plugins/&name;
rm -f /var/log/&name;.log /var/log/&name;.log.1
echo "RAM Guard удалён"
</INLINE>
</FILE>

</PLUGIN>
EOF
} >"$OUT"

if command -v xmllint >/dev/null; then xmllint --noout "$OUT"; fi
echo "Built $OUT ($VERSION)"
