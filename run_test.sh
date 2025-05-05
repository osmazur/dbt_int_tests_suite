#!/bin/bash

#set -e

# Set your DBT profiles directory relative to the script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DBT_PROFILES_DIR="$SCRIPT_DIR"

# Set default DBT target (can be overridden by .env)
DBT_TARGET="snowflake"

# File with repo URLs
REPOS_FILE="$SCRIPT_DIR/repos.yml"


# Log file for failed repos
FAILED_REPOS_FILE="$SCRIPT_DIR/failed_repos.log"
> "$FAILED_REPOS_FILE"  # Clear previous log
# Determine Python command
if command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_CMD="python"
else
    echo "Error: Neither python3 nor python found. Please install Python."
    exit 1
fi

# Check Python version
PYTHON_VERSION=$($PYTHON_CMD --version 2>&1)
if [[ "$PYTHON_VERSION" =~ "Python 2" ]]; then
    echo "Error: Python 3 is required."
    exit 1
fi

while IFS= read -r repo_url; do
  # Skip empty lines or comments
  [[ -z "$repo_url" || "$repo_url" =~ ^# ]] && continue

  repo_name=$(basename "$repo_url" .git)
  repo_dir="target/$repo_name"

  echo "###############################"
  echo ""

  # Skip if already cloned
  if [ -d "$repo_dir" ]; then
    echo "Skipping $repo_name — already exists in target/"
    continue
  fi

  echo "Cloning $repo_url..."
  git clone "$repo_url" "$repo_dir" >/dev/null 2>&1

  repo_path="$repo_dir/integration_tests"
  echo ""
  echo "###############################"
  echo ""

  if [ -d "$repo_path" ]; then
    echo "Setting up for $repo_name..."

    cd "$repo_path"
    echo ""
    # Create and activate virtual env
    echo "###############################"
    echo ""
    echo "Creating virtual environment with $PYTHON_CMD ($PYTHON_VERSION)..."
    $PYTHON_CMD -m venv env
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        source env/Scripts/activate
    else
        source env/bin/activate
    fi
    echo ""

    echo "###############################"
    echo "Loading environment from .env..."
    source "$SCRIPT_DIR/.env"
    echo ""

    DBT_TARGET="${DBT_TARGET:-snowflake}"

    # Force profile name to 'default'
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
      sed -i "s/^profile: .*/profile: 'default'/" dbt_project.yml
    else
      sed -i '' "s/^profile: .*/profile: 'default'/" dbt_project.yml
    fi

    echo "###############################"

    echo ""
    echo "Installing dbt core dbt-snowflake..."
    $PYTHON_CMD -m pip install --upgrade pip >/dev/null 2>&1
    $PYTHON_CMD -m pip install dbt-core dbt-snowflake > pip_install.log 2>&1
    echo ""

    echo "###############################"
    echo "Running DBT tests for $repo_name with target '$DBT_TARGET'..."
    dbt debug --target "$DBT_TARGET" || echo "$repo_name: dbt debug failed" >> "$FAILED_REPOS_FILE"
    dbt clean --target "$DBT_TARGET"

    if [ "$repo_name" == "snowplow_web" ]; then
      if ! bash .scripts/integration_test.sh -d "$DBT_TARGET"; then
        echo "$repo_name: integration_test.sh failed" >> "$FAILED_REPOS_FILE"
      fi
    elif [ "$repo_name" == "dbt-external-tables" ]; then
      dbt deps --target "$DBT_TARGET" || echo "$repo_name: dbt deps failed" >> "$FAILED_REPOS_FILE"
      dbt seed --full-refresh --target "$DBT_TARGET" || echo "$repo_name: dbt seed failed" >> "$FAILED_REPOS_FILE"
      dbt run-operation prep_external --target "$DBT_TARGET" || echo "$repo_name: prep_external failed" >> "$FAILED_REPOS_FILE"
      dbt run-operation dbt_external_tables.stage_external_sources --vars 'ext_full_refresh: true' --target "$DBT_TARGET" || echo "$repo_name: stage_external_sources (1) failed" >> "$FAILED_REPOS_FILE"
      dbt run-operation dbt_external_tables.stage_external_sources --target "$DBT_TARGET" || echo "$repo_name: stage_external_sources (2) failed" >> "$FAILED_REPOS_FILE"
      dbt test --target "$DBT_TARGET" || echo "$repo_name: dbt test failed" >> "$FAILED_REPOS_FILE"
    else
      dbt deps --target "$DBT_TARGET" || echo "$repo_name: dbt deps failed" >> "$FAILED_REPOS_FILE"
      dbt seed --target "$DBT_TARGET" --full-refresh || echo "$repo_name: dbt seed failed" >> "$FAILED_REPOS_FILE"
      dbt run --target "$DBT_TARGET" --full-refresh || echo "$repo_name: dbt run failed" >> "$FAILED_REPOS_FILE"
      dbt test --target "$DBT_TARGET" || echo "$repo_name: dbt test failed" >> "$FAILED_REPOS_FILE"
    fi

    echo "Done with $repo_name"
    echo ""

    deactivate
    cd "$SCRIPT_DIR"
  else
    echo "Skipping $repo_name — no integration_tests directory found"
  fi

done < "$REPOS_FILE"

echo ""
echo "==============================="
if [ -s "$FAILED_REPOS_FILE" ]; then
  echo "⚠️ Some projects failed:"
  cat "$FAILED_REPOS_FILE"
else
  echo "✅ All projects completed successfully!"
fi
