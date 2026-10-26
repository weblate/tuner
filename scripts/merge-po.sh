#!/usr/bin/env bash

# Copyright © 2026 <https://github.com/technosf>
# SPDX-FileCopyrightText: © 2026 <https://github.com/technosf>
#
# SPDX-License-Identifier: GPL-3.0-or-later
#set -euo pipefail

# ================= CONFIG =================
APP_DIR="$(pwd)/po/application"
COUNTRY_DIR="$(pwd)/po/countries"
OUT_DIR="$(pwd)/po"
DEBUG="${DEBUG:-0}"
# =========================================

log() {
    echo "[update-po] $*"
}

debug() {
    if [[ "$DEBUG" == "1" ]]; then
        echo "[update-po][DEBUG] $*"
    fi
}

die() {
    echo "[update-po][ERROR] $*" >&2
    exit 1
}

clean_po_dir() {
    log "Cleaning $OUT_DIR (.po and LINGUAS)"
    rm -f "$OUT_DIR"/*.po "$OUT_DIR"/LINGUAS
}

# ---------- ARG PARSING ----------
CLEAN_ONLY=0

case "${1:-}" in
    --clean|-c)
        CLEAN_ONLY=1
        ;;
    "" )
        ;;
    * )
        die "Unknown argument: $1 (use --clean or -c)"
        ;;
esac

# ---------- Sanity ----------
mkdir -p "$OUT_DIR"

# ---------- CLEAN MODE ----------
if [[ "$CLEAN_ONLY" == "1" ]]; then
    clean_po_dir
    log "Clean-only mode complete."
    exit 0
fi

[[ -d "$APP_DIR" ]] || die "Missing $APP_DIR"
[[ -d "$COUNTRY_DIR" ]] || die "Missing $COUNTRY_DIR"

# ---------- CLEAN OUTPUT DIR BEFORE BUILD ----------
clean_po_dir

# ---------- Normalize LINGUAS ----------
normalize_linguas() {
    local file="$1"
    sed -e 's/#.*//' \
        -e 's/[[:space:]]\+/ /g' \
        -e 's/^ *//;s/ *$//' \
        -e '/^$/d' "$file" | tr ' ' '\n' | sort -u
}

APP_LING="$APP_DIR/LINGUAS"
COUNTRY_LING="$COUNTRY_DIR/LINGUAS"

[[ -f "$APP_LING" ]] || die "Missing $APP_LING"
[[ -f "$COUNTRY_LING" ]] || die "Missing $COUNTRY_LING"

APP_NORM="$(mktemp)"
COUNTRY_NORM="$(mktemp)"

normalize_linguas "$APP_LING" > "$APP_NORM"
normalize_linguas "$COUNTRY_LING" > "$COUNTRY_NORM"

if ! diff -q "$APP_NORM" "$COUNTRY_NORM" >/dev/null; then
    log "WARNING: LINGUAS files differ between application and countries"
    if [[ "$DEBUG" == "1" ]]; then
        log "--- application ---"
        cat "$APP_NORM"
        log "--- countries ---"
        cat "$COUNTRY_NORM"
    fi
fi

# Merge union of both
sort -u "$APP_NORM" "$COUNTRY_NORM" > "$OUT_DIR/LINGUAS"

debug "Final LINGUAS:"
debug "$(cat "$OUT_DIR/LINGUAS")"

# ---------- Combine PO FILES ----------
while read -r lang; do
    [[ -z "$lang" ]] && continue

    APP_PO="$APP_DIR/$lang.po"
    COUNTRY_PO="$COUNTRY_DIR/$lang.po"
    OUT_PO="$OUT_DIR/$lang.po"

    debug "Processing $lang"

    if [[ -f "$APP_PO" && -f "$COUNTRY_PO" ]]; then
        msgcat --use-first "$APP_PO" "$COUNTRY_PO" -o "$OUT_PO"
        debug "Merged $APP_PO + $COUNTRY_PO -> $OUT_PO"
    elif [[ -f "$APP_PO" ]]; then
        cp "$APP_PO" "$OUT_PO"
        debug "Copied $APP_PO -> $OUT_PO"
    elif [[ -f "$COUNTRY_PO" ]]; then
        cp "$COUNTRY_PO" "$OUT_PO"
        debug "Copied $COUNTRY_PO -> $OUT_PO"
    else
        log "WARNING: No .po files for $lang"
    fi

done < "$OUT_DIR/LINGUAS"

# ---------- Cleanup ----------
rm -f "$APP_NORM" "$COUNTRY_NORM"

log "Done."

