#!/bin/bash

set -e

INPUT_FILE="$1"
OUTPUT_DIR="${2:-$(pwd)}"

if [[ -z "$INPUT_FILE" ]]; then
  echo "Usage: $(basename "$0") <odin_file> [output_directory]"
  exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Error: File '$INPUT_FILE' not found"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
TEMP_DIR=$(mktemp -d)

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "Extracting: $(basename "$INPUT_FILE")"
echo "Output: $OUTPUT_DIR"

# Extract main archive
tar -xf "$INPUT_FILE" -C "$TEMP_DIR"

# Copy all files that look like firmware
find "$TEMP_DIR" -type f \( \
  -name "*.img" -o \
  -name "*.bin" -o \
  -name "*.pit" -o \
  -name "*.lz4" -o \
  -name "*.gz" -o \
  -name "boot" -o \
  -name "recovery" -o \
  -name "system" -o \
  -name "vendor" -o \
  -name "product" -o \
  -name "odm" -o \
  -name "vbmeta*" -o \
  -name "dtbo" -o \
  -name "modem*" -o \
  -name "*sboot*" \
  \) -exec cp {} "$OUTPUT_DIR/" \;

# Decompress LZ4 files if possible
if command -v lz4 >/dev/null 2>&1; then
  for lz4_file in "$OUTPUT_DIR"/*.lz4; do
    if [[ -f "$lz4_file" ]]; then
      echo "Decompressing: $(basename "$lz4_file")"
      lz4 -d "$lz4_file" "${lz4_file%.lz4}"
      rm "$lz4_file"
    fi
  done
fi

echo "Done. Files in: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"
