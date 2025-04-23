#!/bin/bash

#set -e

# Set your DBT profiles directory relative to the script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DBT_PROFILES_DIR="$SCRIPT_DIR"

# Set default DBT target (can be overridden by .env)
DBT_TARGET="snowflake"

# File with repo URLs
REPOS_FILE="$SCRIPT_DIR/repos.yml"

while IFS= read -r repo_url; do
  repo_name=$(basename "$repo_url" .git)

  # Clone the repo if not already present
  if [ ! -d "$repo_name" ]; then
    echo "📥 Cloning $repo_url..."
    git clone "$repo_url"
  fi

  repo_path="$repo_name/integration_tests"

  if [ -d "$repo_path" ]; then
    echo "🔧 Setting up for $repo_name..."

    cd "$repo_path"

    # Create and activate virtual env
    echo "🐍 Creating virtual environment..."
    python3 -m venv env
    source env/bin/activate

    # Source environment variables from shared .env
    echo "📂 Loading environment from .env..."
    source "$SCRIPT_DIR/.env"

    # Override DBT_TARGET if defined in .env
    DBT_TARGET="${DBT_TARGET:-snowflake}"

    # Set DBT profile to 'default'
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
      sed -i "s/^profile: .*/profile: 'default'/" dbt_project.yml
    else
      sed -i '' "s/^profile: .*/profile: 'default'/" dbt_project.yml
    fi

    # Install DBT dependencies
    echo "📦 Installing dbt core dbt-snowflake..."
    python -m pip install --upgrade pip >/dev/null 2>&1
    python -m pip install dbt-core dbt-snowflake >/dev/null 2>&1

    # Run DBT commands
    echo "🚀 Running DBT tests for $repo_name with target '$DBT_TARGET'..."
    dbt debug --target "$DBT_TARGET"
    dbt clean --target "$DBT_TARGET"
    dbt deps --target "$DBT_TARGET" || exit 1
    dbt seed --target "$DBT_TARGET" --full-refresh || exit 1
    dbt run --target "$DBT_TARGET" --full-refresh || exit 1
    dbt test --target "$DBT_TARGET" || exit 1

    echo "✅ Done with $repo_name"

    deactivate
    cd ../../
  else
    echo "⚠️ Skipping $repo_name — no integration_tests directory found"
  fi

done < "$REPOS_FILE"
