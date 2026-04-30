#!/bin/bash

echo "Files that will be removed:"
git clean -xfdn | sed 's/^Would remove //'

echo ""
read -r -p "Proceed with git clean -xfd? [y/N] " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
  git clean -xfd
else
  echo "Aborted."
fi
