#!/bin/bash

# dk: Docker cleanup by keyword
# Usage: dk <keyword> [--delete]
# Example: dk remax          (stops containers only)
# Example: dk remax --delete (stops and removes containers)

delete_containers=false
keyword=""

# Parse arguments
for arg in "$@"; do
  case $arg in
    --delete)
      delete_containers=true
      ;;
    *)
      if [ -z "$keyword" ]; then
        keyword="$arg"
      fi
      ;;
  esac
done

if [ -z "$keyword" ]; then
  echo "Usage: dk <keyword> [--delete]"
  echo "  <keyword>  : Filter containers by name"
  echo "  --delete   : Remove containers after stopping (default: stop only)"
  exit 1
fi

if [ "$delete_containers" = true ]; then
  echo "Stopping and removing containers matching '$keyword'..."
else
  echo "Stopping containers matching '$keyword'..."
fi

# Get matching container IDs
containers=$(docker ps -a --filter "name=$keyword" --format "{{.ID}}")

if [ -n "$containers" ]; then
  docker stop $containers
  if [ "$delete_containers" = true ]; then
    docker rm $containers
  fi
else
  echo "No containers found matching '$keyword'"
fi

echo "Removing Docker networks matching '$keyword'..."

# Get matching network names
networks=$(docker network ls --filter "name=$keyword" --format "{{.Name}}")

if [ -n "$networks" ]; then
  docker network rm $networks
else
  echo "No networks found matching '$keyword'"
fi
