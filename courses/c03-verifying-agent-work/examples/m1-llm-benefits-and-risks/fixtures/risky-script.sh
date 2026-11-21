#!/bin/bash
# TODO: handle missing file properly
SOURCE_FILE="fixtures/nonexistent-data.txt"
cat "$SOURCE_FILE" || true
