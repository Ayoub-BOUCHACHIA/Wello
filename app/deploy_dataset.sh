#!/bin/bash

set -e

usage() {
  echo "Usage: $0 -h DB_HOST -p DB_PORT -d DB_NAME -u DB_USER -w DB_PASSWORD"
  echo ""
  echo "Options:"
  echo "  -h   Database host"
  echo "  -p   Database port"
  echo "  -d   Database name"
  echo "  -u   Database user"
  echo "  -w   Database password"
  exit 1
}

while getopts "h:p:d:u:w:" opt; do
  case $opt in
    h) DB_HOST="$OPTARG" ;;
    p) DB_PORT="$OPTARG" ;;
    d) DB_NAME="$OPTARG" ;;
    u) DB_USER="$OPTARG" ;;
    w) DB_PASSWORD="$OPTARG" ;;
    *) usage ;;
  esac
done

if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
  usage
fi

echo "Detecting updated SQL files..."
UPDATED_FILES=$(git diff --name-only HEAD~1 HEAD | grep -E "\.sql$" || true)

if [ -z "$UPDATED_FILES" ]; then
  echo "No updated .sql files found in the latest commit."
  exit 0
fi

echo "Deploying updated datasets to database $DB_NAME..."
for sql_file in $UPDATED_FILES; do
  if [ -f "$sql_file" ]; then
    DATASET_NAME=$(basename "$(dirname "$sql_file")")
    CONTENT=$(cat "$sql_file" | sed "s/'/''/g") 

    echo "Processing dataset: $DATASET_NAME"
    echo "Executing SQL content from $sql_file"

    PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -p "$DB_PORT" -c "
      UPDATE sl_datasets
      SET expression = '$CONTENT'
      WHERE name = '$DATASET_NAME';
    "
    echo "Dataset $DATASET_NAME updated successfully."
  else
    echo "Error: File $sql_file does not exist."
    exit 1
  fi
done

echo "Deployment complete."
