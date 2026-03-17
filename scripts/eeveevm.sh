#!/bin/bash

# Eevee.Bot Version Manager
# A simple script to manage versioning and git operations for Eevee.Bot components

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_PATH="${BASH_SOURCE[0]}"
# Resolve symlink
while [[ -L "$SCRIPT_PATH" ]]; do
  SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"
  SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
  [[ $SCRIPT_PATH == /* ]] || SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_PATH")" && pwd)"

# Change to the project root directory
cd "$SCRIPT_DIR/../../" || { echo "Failed to change to project root directory"; exit 1; }

# Eevee.Bot components
COMPONENTS=(
  "admin"
  "calculator"
  "cli"
  "connector-discord"
  "connector-irc"
  "crds"
  "dice"
  "docs"
  "echo"
  "emote"
  "gitops"
  "helm"
  "help"
  "libeevee-js"
  "operator"
  "router"
  "seen"
  "superslap"
  "tell"
  "urltitle"
  "weather"
)

# Define components that need -build suffix on tags
BUILD_SUFFIX_COMPONENTS=("crds" "helm")

# Utility functions
log() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Get current version of a component
get_version() {
  local component="$1"

  # Check if component directory exists
  if [[ ! -d "$component" ]]; then
    error "Component $component does not exist"
    return 1
  fi

  # Special handling for components without package.json
  if [[ "$component" == "docs" ]] || [[ "$component" == "gitops" ]]; then
    # Get the latest tag from the repository that follows semver pattern
    local latest_tag
    latest_tag=$(cd "$component" && git tag -l | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1) || true

    # If no semver tags found, return default
    if [[ -z "$latest_tag" ]]; then
      echo "0.0.0"
      return 0
    fi

    echo "$latest_tag"
    return 0
  fi

  # For components with package.json
  if [[ -f "$component/package.json" ]]; then
    jq -r '.version' "$component/package.json" 2>/dev/null || echo "0.0.0"
  else
    error "package.json not found in $component"
    return 1
  fi
}

# Update version in package.json
update_version() {
  local component="$1"
  local new_version="$2"

  # Special handling for components without package.json
  if [[ "$component" == "docs" ]] || [[ "$component" == "gitops" ]]; then
    log "Prepared $component for versioning to $new_version"
    return 0
  fi

  # For components with package.json
  if [[ ! -f "$component/package.json" ]]; then
    error "package.json not found in $component"
    return 1
  fi

  local old_version
  old_version=$(get_version "$component")

  jq --arg version "$new_version" '.version = $version' "$component/package.json" > "$component/package.json.tmp" && \
    mv "$component/package.json.tmp" "$component/package.json"

  log "Updated $component from $old_version to $new_version"

  # Run npm install to update package-lock.json
  if [[ -f "$component/package-lock.json" ]]; then
    log "Running npm install in $component to update package-lock.json"

    # Check if component has special npm args
    local custom_args=""
    if [[ "$component" == "crds" ]]; then
      custom_args="--legacy-peer-deps"
    fi

    if [[ -n "$custom_args" ]]; then
      log "Using custom npm args for $component: $custom_args"
      (cd "$component" && npm install $custom_args)
    else
      (cd "$component" && npm install)
    fi
  fi
}

# Increment version
increment_version() {
  local version="$1"
  local bump_type="$2"

  local major minor patch
  IFS='.' read -r major minor patch <<< "$version"

  case "$bump_type" in
    major)
      echo "$((major + 1)).0.0"
      ;;
    minor)
      echo "$major.$((minor + 1)).0"
      ;;
    patch)
      echo "$major.$minor.$((patch + 1))"
      ;;
    *)
      error "Invalid bump type: $bump_type"
      return 1
      ;;
  esac
}

# Stage all changes for one or more components
stage_all() {
  if [[ $# -lt 1 ]]; then
    error "At least one component name required"
    return 1
  fi

  local components_to_stage=()

  # Check if specified components exist
  for comp in "$@"; do
    if [[ ! -d "$comp" ]]; then
      warn "Component $comp does not exist, skipping..."
      continue
    fi
    components_to_stage+=("$comp")
  done

  # Stage changes for each component
  for component in "${components_to_stage[@]}"; do
    cd "$component" || continue

    # Add all files to git
    if git add .; then
      log "Staged all changes in $component"
    else
      error "Failed to stage changes in $component"
      cd - > /dev/null
      continue
    fi

    cd - > /dev/null || return 1
  done
}

# Git operations for a component
git_operations() {
  local component="$1"
  local version="$2"
  local message="$3"

  # Check if component directory exists
  if [[ ! -d "$component" ]]; then
    error "Component $component does not exist"
    return 1
  fi

  cd "$component" || return 1

  # Add files to git
  if [[ "$component" == "docs" ]] || [[ "$component" == "gitops" ]]; then
    # For docs and gitops, we don't have specific files to add
    log "No specific files to add for $component"
  else
    # Add package.json
    git add package.json 2>/dev/null || true

    # Add package-lock.json if it exists
    if [[ -f "package-lock.json" ]]; then
      git add package-lock.json 2>/dev/null || true
    fi
  fi

  # Commit changes if there are any
  if ! git diff-index --quiet HEAD -- || ! git diff --cached --quiet; then
    local commit_message="${version} - ${message}"
    if git commit -m "$commit_message"; then
      log "Committed changes in $component"
    else
      warn "Failed to commit changes in $component"
    fi
  else
    log "No changes to commit in $component"
  fi

  # Create tag
  local tag_name="${version}"

  # Check if tag already exists
  if git rev-parse "$tag_name" >/dev/null 2>&1; then
    warn "Tag $tag_name already exists in $component, skipping..."
  else
    # Check if this component needs -build suffix
    local needs_build_suffix=false
    for build_comp in "${BUILD_SUFFIX_COMPONENTS[@]}"; do
      if [[ "$component" == "$build_comp" ]]; then
        needs_build_suffix=true
        break
      fi
    done

    if [[ "$needs_build_suffix" == true ]]; then
      # For components that need -build suffix, create both regular and -build tags
      local build_tag_name="${version}-build"

      # Create -build tag pointing to the same commit
      if ! git rev-parse "$build_tag_name" >/dev/null 2>&1; then
        if git tag "$build_tag_name"; then
          log "Created build tag $build_tag_name in $component"
        else
          error "Failed to create build tag $build_tag_name in $component"
        fi
      else
        log "Build tag $build_tag_name already exists in $component"
      fi
    else
      # For components that don't need -build suffix, create regular tag
      if git tag "$tag_name"; then
        log "Created tag $tag_name in $component"
      else
        error "Failed to create tag $tag_name in $component"
        cd - > /dev/null
        return 1
      fi
    fi
  fi

  cd - > /dev/null || return 1
}

# Version a single component
version_component() {
  local component="$1"
  local bump_type="${2:-patch}"
  local message="${3:-Version bump $bump_type}"

  # Check if component exists
  if [[ ! -d "$component" ]]; then
    error "Component $component does not exist"
    return 1
  fi

  local current_version
  current_version=$(get_version "$component") || return 1

  local new_version
  new_version=$(increment_version "$current_version" "$bump_type") || return 1

  log "Versioning $component from $current_version to $new_version"

  # Update the component version
  update_version "$component" "$new_version" || return 1

  # Git operations
  git_operations "$component" "$new_version" "$message" || return 1

  success "Versioned $component to $new_version"
}

# Version multiple components
version_components() {
  local bump_type="${1:-patch}"
  local message="${2:-Bulk version bump $bump_type}"
  shift 2
  local components_to_version=()

  # If no components specified, version all
  if [[ $# -eq 0 ]]; then
    components_to_version=("${COMPONENTS[@]}")
  else
    # Check if specified components exist
    for comp in "$@"; do
      local found=false
      for available_comp in "${COMPONENTS[@]}"; do
        if [[ "$comp" == "$available_comp" ]]; then
          components_to_version+=("$comp")
          found=true
          break
        fi
      done

      if [[ "$found" == false ]]; then
        warn "Component $comp not found, skipping..."
      fi
    done
  fi

  log "Versioning components: ${components_to_version[*]} with $bump_type bump"

  # Version each component
  for component in "${components_to_version[@]}"; do
    version_component "$component" "$bump_type" "$message" || warn "Failed to version $component"
  done

  success "Finished versioning components"
}

# Push changes for one or more components
push_components() {
  local components_to_push=()

  # If no components specified, push all
  if [[ $# -eq 0 ]]; then
    components_to_push=("${COMPONENTS[@]}")
  else
    # Check if specified components exist
    for comp in "$@"; do
      local found=false
      for available_comp in "${COMPONENTS[@]}"; do
        if [[ "$comp" == "$available_comp" ]]; then
          components_to_push+=("$comp")
          found=true
          break
        fi
      done

      if [[ "$found" == false ]]; then
        warn "Component $comp not found, skipping..."
      fi
    done
  fi

  log "Pushing changes for components: ${components_to_push[*]}"

  # Push changes for each component
  for component in "${components_to_push[@]}"; do
    # Check if component exists
    if [[ ! -d "$component" ]]; then
      warn "Component $component does not exist, skipping..."
      continue
    fi

    log "Pushing changes in $component..."
    cd "$component" || continue

    # Push commits
    if ! git push; then
      log "Push failed, attempting git pull --rebase..."
      if git pull --rebase; then
        log "Rebase successful, retrying push..."
        if ! git push; then
          warn "Push failed even after rebase in $component"
        else
          log "Pushed commits in $component"
        fi
      else
        warn "Failed to rebase in $component"
      fi
    else
      log "Pushed commits in $component"
    fi

    if ! git push --tags; then
      log "Tag push failed, attempting git pull --rebase for tags..."
      if git pull --rebase; then
        log "Rebase successful, retrying tag push..."
        if ! git push --tags; then
          warn "Tag push failed even after rebase in $component"
        else
          log "Pushed tags in $component"
        fi
      else
        warn "Failed to rebase for tags in $component"
      fi
    else
      log "Pushed tags in $component"
    fi

    cd - > /dev/null || return 1
  done

  success "Finished pushing changes"
}

# Show current status
show_status() {
  echo "Current component versions and git status:"
  echo "=========================================="
  printf "%-20s %-15s %-10s %-10s %-10s %-10s\n" "COMPONENT" "VERSION" "UNSTAGED" "STAGED" "UNPUSHED" "TAGS"
  echo "-------------------------------------------------------------------------------"

  for component in "${COMPONENTS[@]}"; do
    if [[ -d "$component" ]]; then
      # Get version
      local version="N/A"
      version=$(get_version "$component" 2>/dev/null || echo "ERROR")

      # Get git status counts
      local unstaged_count=0
      local staged_count=0
      local unpushed_commits=0
      local unpushed_tags=0

      if [[ -d "$component/.git" ]] || (cd "$component" && git rev-parse --git-dir > /dev/null 2>&1); then
        # Count unstaged files (excluding untracked)
        tmp_count=$(cd "$component" && git diff --name-only 2>/dev/null | wc -l)
        unstaged_count=${tmp_count//[[:space:]]/}

        # Count staged files
        tmp_count=$(cd "$component" && git diff --cached --name-only 2>/dev/null | wc -l)
        staged_count=${tmp_count//[[:space:]]/}

        # Count unpushed commits
        tmp_count=$(cd "$component" && git log --oneline @{u}..HEAD 2>/dev/null | wc -l)
        unpushed_commits=${tmp_count//[[:space:]]/}
        if [[ -z "$unpushed_commits" ]]; then
            unpushed_commits=0
        fi

        # Count unpushed tags
        local tag_output
        tag_output=$(cd "$component" && git push --tags --dry-run 2>/dev/null) || tag_output=""
        if [[ -n "$tag_output" ]]; then
            unpushed_tags=$(echo "$tag_output" | grep -c "new tag" 2>/dev/null || echo "0")
        else
            unpushed_tags="0"
        fi
      else
        unstaged_count="-"
        staged_count="-"
        unpushed_commits="-"
        unpushed_tags="-"
      fi

      printf "%-20s %-15s %-10s %-10s %-10s %-10s\n" "$component" "$version" "$unstaged_count" "$staged_count" "$unpushed_commits" "$unpushed_tags"
    else
      printf "%-20s %-15s %-10s %-10s %-10s %-10s\n" "$component" "Not found" "-" "-" "-" "-"
    fi
  done
}

# Show help
show_help() {
  echo "
Eevee.Bot Version Manager

Usage:
  ./eeveevm.sh status                            - Show current versions and git status
  ./eeveevm.sh version <component> [bump] [msg]  - Version a specific component
  ./eeveevm.sh version-all [bump] [msg] [components...] - Version one or more components
  ./eeveevm.sh stage-all <component> [components...] - Stage all changes for one or more components
  ./eeveevm.sh push [components...]              - Push changes for one or more components
  ./eeveevm.sh help                              - Show this help

Bump types: major, minor, patch (default: patch)

Examples:
  ./eeveevm.sh version admin patch "Fixed admin panel bug"
  ./eeveevm.sh version-all minor "Added new features"
  ./eeveevm.sh version-all patch admin router
  ./eeveevm.sh stage-all admin
  ./eeveevm.sh push
  ./eeveevm.sh push admin router
  "
}

# Main function
main() {
  if [[ $# -eq 0 ]]; then
    show_help
    exit 0
  fi

  local command="$1"
  shift

  case "$command" in
    status)
      show_status
      ;;
    version)
      if [[ $# -lt 1 ]]; then
        error "Component name required"
        show_help
        exit 1
      fi
      local component="$1"
      local bump_type="${2:-patch}"
      local message="${3:-Version bump $bump_type}"
      version_component "$component" "$bump_type" "$message"
      ;;
    version-all)
      local bump_type="patch"
      local message="Bulk version bump patch"

      # Parse arguments
      if [[ $# -gt 0 && "$1" != -* ]]; then
        bump_type="$1"
        message="Bulk version bump $bump_type"
        shift
      fi

      if [[ $# -gt 0 && "$1" != -* ]]; then
        message="$1"
        shift
      fi

      version_components "$bump_type" "$message" "$@"
      ;;
    stage-all)
      if [[ $# -lt 1 ]]; then
        error "Component name required"
        show_help
        exit 1
      fi
      stage_all "$@"
      ;;
    push)
      push_components "$@"
      ;;
    help)
      show_help
      ;;
    *)
      error "Unknown command '$command'"
      show_help
      exit 1
      ;;
  esac
}

# Run main function with all arguments
main "$@"