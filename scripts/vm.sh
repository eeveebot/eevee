#!/bin/bash

# Eevee Bot Version Manager
# A master script to manage versioning and git tags for all eevee.bot projects

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

# Change to the project root directory (assuming the script is in docs/scripts/)
cd "$SCRIPT_DIR/../.." || { echo "Failed to change to project root directory"; exit 1; }

# All packages in the monorepo
PACKAGES=(
  "libeevee-js:@eeveebot/libeevee"
  "admin:@eeveebot/admin"
  "connector-irc:@eeveebot/connector-irc"
  "echo:@eeveebot/echo"
  "router:@eeveebot/router"
  "operator:@eeveebot/operator"
  "cli:@eeveebot/cli"
  "calculator:@eeveebot/calculator"
  "dice:@eeveebot/dice"
  "emote:@eeveebot/emote"
  "weather:@eeveebot/weather"
  "help:@eeveebot/help"
  "tell:@eeveebot/tell"
  "urltitle:@eeveebot/urltitle"
  "crds:@eeveebot/crds"
  "helm:@eeveebot/helm"
  "docs:@eeveebot/docs"
)

# Library package configuration
LIBRARY_PACKAGE="libeevee-js"
LIBRARY_NAME="@eeveebot/libeevee"

# Dependent packages that use libeevee-js
DEPENDENT_PACKAGES=(
  "admin"
  "connector-irc"
  "echo"
  "router"
  "operator"
  "cli"
  "calculator"
  "dice"
  "emote"
  "weather"
  "help"
  "tell"
  "urltitle"
  "crds"
  "helm"
)

# Command modules that trigger bot version increments
COMMAND_MODULES=(
  "admin"
  "calculator"
  "cli"
  "connector-irc"
  "dice"
  "echo"
  "emote"
  "help"
  "router"
  "tell"
  "urltitle"
  "weather"
)

# Packages that affect Helm when versioned
HELM_AFFECTING_PACKAGES=(
  "admin"
  "calculator"
  "cli"
  "connector-irc"
  "crds"
  "dice"
  "echo"
  "emote"
  "help"
  "operator"
  "router"
  "tell"
  "urltitle"
  "weather"
)

# Packages that need special tag suffixes
SPECIAL_TAG_SUFFIXES=(
  "crds:-build"
  "helm:-build"
)

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

# Check if a package affects Helm
package_affects_helm() {
  local package_name="$1"
  for pkg in "${HELM_AFFECTING_PACKAGES[@]}"; do
    if [[ "$pkg" == "$package_name" ]]; then
      return 0
    fi
  done
  return 1
}

# Get special tag suffix for a package
get_special_tag_suffix() {
  local package_name="$1"
  for entry in "${SPECIAL_TAG_SUFFIXES[@]}"; do
    IFS=':' read -r pkg suffix <<< "$entry"
    if [[ "$pkg" == "$package_name" ]]; then
      echo "$suffix"
      return 0
    fi
  done
  echo ""
  return 1
}

# Get current version of a package
get_version() {
  local package_dir="$1"
  
  # Special handling for docs project
  if [[ "$package_dir" == "docs" ]]; then
    # Get the latest tag from the docs repository that follows semver pattern
    local latest_tag
    latest_tag=$(cd "$package_dir" && git tag -l | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1) || true
    
    # If no semver tags found, return default
    if [[ -z "$latest_tag" ]]; then
      echo "0.0.0"
      return 0
    fi
    
    echo "$latest_tag"
    return 0
  fi
  
  if [[ ! -f "$package_dir/package.json" ]]; then
    error "package.json not found in $package_dir"
    return 1
  fi
  
  jq -r '.version' "$package_dir/package.json"
}

# Update version in package.json
update_version() {
  local package_dir="$1"
  local new_version="$2"
  
  # Special handling for docs project
  if [[ "$package_dir" == "docs" ]]; then
    local old_version
    old_version=$(get_version "$package_dir")
    
    # For docs, we don't update a package.json, we just create a git tag
    log "Prepared $package_dir for versioning from $old_version to $new_version"
    return 0
  fi
  
  if [[ ! -f "$package_dir/package.json" ]]; then
    error "package.json not found in $package_dir"
    return 1
  fi
  
  local old_version
  old_version=$(get_version "$package_dir")
  
  jq --arg version "$new_version" '.version = $version' "$package_dir/package.json" > "$package_dir/package.json.tmp" && \
    mv "$package_dir/package.json.tmp" "$package_dir/package.json"
  
  log "Updated $package_dir from $old_version to $new_version"
}

# Update version in package-lock.json
update_lock_version() {
  local package_dir="$1"
  local new_version="$2"
  
  # Update version in package-lock.json if it exists
  if [[ -f "$package_dir/package-lock.json" ]]; then
    jq --arg version "$new_version" '.version = $version' "$package_dir/package-lock.json" > "$package_dir/package-lock.json.tmp" && \
      mv "$package_dir/package-lock.json.tmp" "$package_dir/package-lock.json"
    log "Updated package-lock.json version in $package_dir to $new_version"
  fi
}

# Update dependency version in package.json
update_dependency() {
  local package_dir="$1"
  local dependency_name="$2"
  local new_version="$3"
  
  if [[ ! -f "$package_dir/package.json" ]]; then
    error "package.json not found in $package_dir"
    return 1
  fi
  
  # Check if dependency exists in dependencies
  if jq -e --arg dep "$dependency_name" '.dependencies[$dep]' "$package_dir/package.json" > /dev/null 2>&1; then
    jq --arg dep "$dependency_name" --arg version "^$new_version" '.dependencies[$dep] = $version' "$package_dir/package.json" > "$package_dir/package.json.tmp" && \
      mv "$package_dir/package.json.tmp" "$package_dir/package.json"
    log "Updated $dependency_name dependency in $package_dir to ^$new_version"
  fi
  
  # Check if dependency exists in devDependencies
  if jq -e --arg dep "$dependency_name" '.devDependencies[$dep]' "$package_dir/package.json" > /dev/null 2>&1; then
    jq --arg dep "$dependency_name" --arg version "^$new_version" '.devDependencies[$dep] = $version' "$package_dir/package.json" > "$package_dir/package.json.tmp" && \
      mv "$package_dir/package.json.tmp" "$package_dir/package.json"
    log "Updated $dependency_name devDependency in $package_dir to ^$new_version"
  fi
  
  # Update dependency version in package-lock.json if it exists
  if [[ -f "$package_dir/package-lock.json" ]]; then
    # Update in dependencies section
    if jq -e --arg dep "$dependency_name" '.packages[""].dependencies[$dep]' "$package_dir/package-lock.json" > /dev/null 2>&1; then
      jq --arg dep "$dependency_name" --arg version "$new_version" '.packages[""].dependencies[$dep] = $version' "$package_dir/package-lock.json" > "$package_dir/package-lock.json.tmp" && \
        mv "$package_dir/package-lock.json.tmp" "$package_dir/package-lock.json"
      log "Updated $dependency_name version in $package_dir/package-lock.json to $new_version"
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

# Update operator version in helm chart
update_operator_helm_version() {
  local new_version="$1"
  
  local helm_file="helm/src/operator.mts"
  if [[ ! -f "$helm_file" ]]; then
    warn "Helm file $helm_file not found, skipping operator image update"
    return 0
  fi
  
  # Update the image tag in the helm chart
  local new_image_line="const image: string = 'ghcr.io/eeveebot/operator:${new_version}';"
  
  # Check if the line exists and needs to be updated
  if grep -q "const image: string = 'ghcr.io/eeveebot/operator:" "$helm_file"; then
    sed -i '' "s|const image: string = 'ghcr.io/eeveebot/operator:[^']*';|${new_image_line}|" "$helm_file"
    log "Updated operator image tag to ${new_version} in $helm_file"
  else
    warn "Image line not found in $helm_file, skipping update"
  fi
}

# Update crds version in helm chart
update_crds_helm_version() {
  local new_version="$1"
  
  local helm_file="helm/src/crds.mts"
  if [[ ! -f "$helm_file" ]]; then
    warn "Helm file $helm_file not found, skipping crds image update"
    return 0
  fi
  
  # Update the image tag in the helm chart
  local new_image_line="const image: string = 'ghcr.io/eeveebot/crds:${new_version}';"
  
  # Check if the line exists and needs to be updated
  if grep -q "const image: string = 'ghcr.io/eeveebot/crds:" "$helm_file"; then
    sed -i '' "s|const image: string = 'ghcr.io/eeveebot/crds:[^']*';|${new_image_line}|" "$helm_file"
    log "Updated crds image tag to ${new_version} in $helm_file"
  else
    warn "Image line not found in $helm_file, skipping update"
  fi
}

# Update versions.yaml when operator version changes
update_helm_versions_operator() {
  local new_version="$1"
  
  local versions_file="helm/versions.yaml"
  if [[ ! -f "$versions_file" ]]; then
    warn "Versions file $versions_file not found, skipping version update"
    return 0
  fi
  
  # Update both chart and application versions for operator
  yq eval ".operator.chart = \"$new_version\" | .operator.application = \"$new_version\"" -i "$versions_file"
  log "Updated operator versions to $new_version in $versions_file"
  
  # Add the versions file to git if it was modified
  (cd helm && git add versions.yaml) 2>/dev/null || true
}

# Update versions.yaml when crds version changes
update_helm_versions_crds() {
  local new_version="$1"
  
  local versions_file="helm/versions.yaml"
  if [[ ! -f "$versions_file" ]]; then
    warn "Versions file $versions_file not found, skipping version update"
    return 0
  fi
  
  # Update both chart and application versions for crds
  yq eval ".crds.chart = \"$new_version\" | .crds.application = \"$new_version\"" -i "$versions_file"
  log "Updated crds versions to $new_version in $versions_file"
  
  # Add the versions file to git if it was modified
  (cd helm && git add versions.yaml) 2>/dev/null || true
}

# Increment bot version in versions.yaml
increment_bot_version() {
  local versions_file="helm/versions.yaml"
  if [[ ! -f "$versions_file" ]]; then
    warn "Versions file $versions_file not found, skipping bot version increment"
    return 0
  fi
  
  # Get current bot version
  local current_version
  current_version=$(yq eval '.bot.chart' "$versions_file")
  
  # Increment patch version
  local major minor patch
  IFS='.' read -r major minor patch <<< "$current_version"
  local new_version="${major}.${minor}.$((patch + 1))"
  
  # Update both chart and application versions for bot
  yq eval ".bot.chart = \"$new_version\" | .bot.application = \"$new_version\"" -i "$versions_file"
  log "Incremented bot version from $current_version to $new_version in $versions_file"
  
  # Add the versions file to git if it was modified
  (cd helm && git add versions.yaml) 2>/dev/null || true
}

# Tag and push helm repository
tag_and_push_helm() {
  local version="$1"
  local message="$2"
  
  # Check if helm directory exists
  if [[ ! -d "helm" ]]; then
    warn "Helm directory not found, skipping helm tagging"
    return 0
  fi
  
  # Check if there are changes in the helm repository
  local helm_changes
  helm_changes=$(cd helm && git diff-index --quiet HEAD -- . && echo "no-changes" || echo "changes")
  
  if [[ "$helm_changes" == "no-changes" ]] && [[ -z "$(cd helm && git diff --cached -- .)" ]]; then
    log "No changes in helm repository, skipping helm tagging"
    return 0
  fi
  
  # Commit changes in helm repository
  (cd helm && git commit -m "v${version} - ${message}") || {
    warn "Failed to commit changes in helm repository"
    return 1
  }
  log "Committed changes in helm repository"
  
  # Create tag for helm repository
  local tag_name="v${version}"
  if (cd helm && git rev-parse "$tag_name" >/dev/null 2>&1); then
    warn "Tag $tag_name already exists in helm repository, skipping..."
    return 0
  fi
  
  (cd helm && git tag "$tag_name") || {
    warn "Failed to create tag $tag_name in helm repository"
    return 1
  }
  log "Created tag $tag_name in helm repository"
  
  log "Created tag for helm repository (use git-push subcommand to push changes)"
}

# Git operations
git_add_commit() {
  local package_dir="$1"
  local version="$2"
  local message="$3"
  
  cd "$package_dir" || return 1
  
  # Special handling for docs project
  if [[ "$package_dir" == "docs" ]]; then
    # For docs, we don't have specific files to add, just proceed with tagging
    log "No files to commit for docs project, proceeding to tag creation"
  else
    # Add package.json
    git add package.json
    
    # Add package-lock.json if it exists
    if [[ -f "package-lock.json" ]]; then
      git add package-lock.json
    fi
  fi
  
  # Check if there are changes to commit
  if ! git diff-index --quiet HEAD --; then
    local commit_message="${version} - ${message}"
    if git commit -m "$commit_message"; then
      log "Committed changes in $package_dir (use git-push subcommand to push changes)"
    else
      warn "Failed to commit changes in $package_dir"
      cd - > /dev/null
      return 1
    fi
  else
    log "No changes to commit in $package_dir"
  fi
  
  cd - > /dev/null || return 1
}

# Create and push git tag
git_tag_and_push() {
  local package_dir="$1"
  local version="$2"
  
  cd "$package_dir" || return 1
  
  # Check for special tag suffix
  local tag_name="$version"
  local suffix
  suffix=$(get_special_tag_suffix "$package_dir")
  if [[ -n "$suffix" ]]; then
    tag_name="${version}${suffix}"
  fi
  
  # Check if tag already exists locally
  if git rev-parse "$tag_name" >/dev/null 2>&1; then
    warn "Tag $tag_name already exists locally in $package_dir, skipping..."
    cd - > /dev/null
    return 0
  fi
  
  # Check if tag already exists remotely
  if git ls-remote --tags origin "$tag_name" | grep -q "$tag_name"; then
    warn "Tag $tag_name already exists remotely in $package_dir, skipping..."
    cd - > /dev/null
    return 0
  fi
  
  # Create new tag
  if git tag "$tag_name"; then
    log "Created tag $tag_name in $package_dir"
  else
    error "Failed to create tag $tag_name in $package_dir"
    cd - > /dev/null
    return 1
  fi
  
  log "Created tag $tag_name in $package_dir (use git-push-tags subcommand to push tags)"
  
  cd - > /dev/null || return 1
}

# Version a single package
version_package() {
  local package_name="$1"
  local bump_type="${2:-patch}"
  local message="${3:-Version bump $bump_type}"
  
  # Find package directory and name
  local package_dir=""
  local full_package_name=""
  
  for pkg in "${PACKAGES[@]}"; do
    IFS=':' read -r dir name <<< "$pkg"
    if [[ "$dir" == "$package_name" ]]; then
      package_dir="$dir"
      full_package_name="$name"
      break
    fi
  done
  
  if [[ -z "$package_dir" ]]; then
    error "Package $package_name not found"
    return 1
  fi
  
  if [[ ! -d "$package_dir" ]]; then
    error "Directory $package_dir does not exist"
    return 1
  fi
  
  local current_version
  current_version=$(get_version "$package_dir") || return 1
  
  local new_version
  new_version=$(increment_version "$current_version" "$bump_type") || return 1
  
  # Check if tag already exists before making changes
  local tag_name="$new_version"
  local suffix
  suffix=$(get_special_tag_suffix "$package_dir")
  if [[ -n "$suffix" ]]; then
    tag_name="${new_version}${suffix}"
  fi
  
  # Check if tag already exists locally
  if (cd "$package_dir" && git rev-parse "$tag_name" >/dev/null 2>&1); then
    warn "Tag $tag_name already exists locally in $package_dir, skipping..."
    return 0
  fi
  
  # Check if tag already exists remotely
  if (cd "$package_dir" && git ls-remote --tags origin "$tag_name" | grep -q "$tag_name"); then
    warn "Tag $tag_name already exists remotely in $package_dir, skipping..."
    return 0
  fi
  
  log "Versioning $package_name from $current_version to $new_version"
  
  # Update the package version
  update_version "$package_dir" "$new_version" || return 1
  update_lock_version "$package_dir" "$new_version"
  
  # Track if helm changes were made
  local helm_changed=false
  
  # If this is the operator package, update the helm chart and versions
  if [[ "$package_name" == "operator" ]]; then
    update_operator_helm_version "$new_version"
    update_helm_versions_operator "$new_version"
    # Add the helm files to git if they were modified
    if [[ -f "helm/src/operator.mts" ]]; then
      (cd helm && git add src/operator.mts) 2>/dev/null || true
    fi
    helm_changed=true
  fi
  
  # If this is the crds package, update the helm chart and versions
  if [[ "$package_name" == "crds" ]]; then
    update_crds_helm_version "$new_version"
    update_helm_versions_crds "$new_version"
    # Add the helm files to git if they were modified
    if [[ -f "helm/src/crds.mts" ]]; then
      (cd helm && git add src/crds.mts) 2>/dev/null || true
    fi
    helm_changed=true
  fi

  # If this is the library package, update all dependents
  if [[ "$package_name" == "$LIBRARY_PACKAGE" ]]; then
    log "Updating dependents of $package_name..."
    for dependent in "${DEPENDENT_PACKAGES[@]}"; do
      if [[ -d "$dependent" ]]; then
        update_dependency "$dependent" "$LIBRARY_NAME" "$new_version" || warn "Failed to update dependency in $dependent"
      fi
    done
  fi
  
  # Git operations for the main package
  git_add_commit "$package_dir" "$new_version" "$message" || warn "Git operations failed for $package_dir"
  git_tag_and_push "$package_dir" "$new_version" || warn "Git tag operations failed for $package_dir"

  success "Versioned $package_name to $new_version (use git-push to push changes)"
}

# Version all packages
version_all() {
  local bump_type="${1:-patch}"
  local message="${2:-Bulk version bump $bump_type}"
  shift 2
  local exclude_packages=()
  
  # Parse --exclude arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --exclude)
        if [[ -n "$2" && "$2" != --* ]]; then
          exclude_packages+=("$2")
          shift 2
        else
          error "--exclude requires a package name"
          return 1
        fi
        ;;
      *)
        shift
        ;;
    esac
  done
  
  log "Versioning all packages with $bump_type bump..."
  
  # First, version the library package if it exists and is not excluded
  local library_new_version=""
  local library_excluded=false
  for excluded_pkg in "${exclude_packages[@]}"; do
    if [[ "$LIBRARY_PACKAGE" == "$excluded_pkg" ]]; then
      library_excluded=true
      log "Skipping $LIBRARY_PACKAGE (excluded)"
      break
    fi
  done
  
  if [[ "$library_excluded" == false && -d "$LIBRARY_PACKAGE" ]]; then
    local library_current_version
    library_current_version=$(get_version "$LIBRARY_PACKAGE") || return 1
    
    library_new_version=$(increment_version "$library_current_version" "$bump_type") || return 1
    
    log "Versioning $LIBRARY_PACKAGE from $library_current_version to $library_new_version"
    update_version "$LIBRARY_PACKAGE" "$library_new_version" || return 1
    update_lock_version "$LIBRARY_PACKAGE" "$library_new_version"
    
    # Update all dependents
    log "Updating dependents of $LIBRARY_PACKAGE..."
    for dependent in "${DEPENDENT_PACKAGES[@]}"; do
      # Check if dependent is excluded
      local dependent_excluded=false
      for excluded_pkg in "${exclude_packages[@]}"; do
        if [[ "$dependent" == "$excluded_pkg" ]]; then
          dependent_excluded=true
          log "Skipping $dependent (excluded)"
          break
        fi
      done
      
      if [[ "$dependent_excluded" == false && -d "$dependent" ]]; then
        update_dependency "$dependent" "$LIBRARY_NAME" "$library_new_version" || warn "Failed to update dependency in $dependent"
      fi
    done
    
    # Git operations for library
    git_add_commit "$LIBRARY_PACKAGE" "$library_new_version" "$message" || warn "Git operations failed for $LIBRARY_PACKAGE"
    git_tag_and_push "$LIBRARY_PACKAGE" "$library_new_version" || warn "Git tag operations failed for $LIBRARY_PACKAGE"
    
    success "Versioned $LIBRARY_PACKAGE to $library_new_version (use git-push to push changes)"
  fi
  
  # Track if any helm changes were made during the process
  local helm_changed=false
  
  # Then, version all other packages
  for pkg in "${PACKAGES[@]}"; do
    IFS=':' read -r dir name <<< "$pkg"
    
    # Skip library package as we already handled it
    if [[ "$dir" == "$LIBRARY_PACKAGE" ]]; then
      continue
    fi
    
    # Check if this package should be excluded
    local excluded=false
    for excluded_pkg in "${exclude_packages[@]}"; do
      if [[ "$dir" == "$excluded_pkg" ]]; then
        excluded=true
        log "Skipping $dir (excluded)"
        break
      fi
    done
    
    if [[ "$excluded" == true ]]; then
      continue
    fi
    
    if [[ -d "$dir" ]]; then
      # Special handling for helm package
      if [[ "$dir" == "helm" ]]; then
        local helm_current_version
        helm_current_version=$(get_version "$dir") || return 1
        local helm_new_version
        helm_new_version=$(increment_version "$helm_current_version" "$bump_type") || return 1
        update_version "$dir" "$helm_new_version" || return 1
        update_lock_version "$dir" "$helm_new_version"
        git_add_commit "$dir" "$helm_new_version" "$message" || warn "Git operations failed for $dir"
        git_tag_and_push "$dir" "$helm_new_version" || warn "Git tag operations failed for $dir"
        helm_changed=true
        success "Versioned $dir to $helm_new_version (use git-push to push changes)"
        continue
      fi
      
      # Check if this package affects Helm
      if package_affects_helm "$dir"; then
        helm_changed=true
      fi
      
      version_package "$dir" "$bump_type" "$message" || warn "Failed to version $dir"
    else
      warn "Directory $dir does not exist, skipping..."
    fi
  done
  
  # If helm was changed during the process, tag the helm repository (use git-push to push)
  if [[ "$helm_changed" == true ]]; then
    # Use simple incremented version for helm tag when versioning all packages
    local versions_file="helm/versions.yaml"
    if [[ -f "$versions_file" ]]; then
      # Get current bot version and increment it
      local current_version
      current_version=$(yq eval '.bot.chart' "$versions_file")
      local major minor patch
      IFS='.' read -r major minor patch <<< "$current_version"
      local helm_version="${major}.${minor}.$((patch + 1))"
    else
      # Fallback to simple version if versions.yaml not found
      local helm_version="1.0.0"
    fi
    tag_and_push_helm "$helm_version" "$message"
  fi
  
  success "All packages versioned successfully! (Use git-push and git-push-tags to push changes)"
}

# Show current status
show_status() {
  echo "Current package versions and git status:"
  echo "======================================="
  printf "%-15s %-25s %-15s %-10s %-10s %-10s %-10s\n" "DIRECTORY" "PACKAGE NAME" "VERSION" "UNSTAGED" "STAGED" "UNPUSHED" "TAGS"
  echo "---------------------------------------------------------------------------------------------"
  
  for pkg in "${PACKAGES[@]}"; do
    IFS=':' read -r dir name <<< "$pkg"
    
    if [[ -d "$dir" ]]; then
      # Get version
      local version="No package.json"
      if [[ -f "$dir/package.json" ]] || [[ "$dir" == "docs" ]]; then
        version=$(get_version "$dir" 2>/dev/null || echo "ERROR")
      fi
      
      # Get git status counts
      local unstaged_count=0
      local staged_count=0
      local unpushed_commits=0
      local unpushed_tags=0
      
      if [[ -d "$dir/.git" ]] || (cd "$dir" && git rev-parse --git-dir > /dev/null 2>&1); then
        # Count unstaged files (excluding untracked)
        tmp_count=$(cd "$dir" && git diff --name-only | wc -l)
        unstaged_count=${tmp_count//[[:space:]]/}
        
        # Count staged files
        tmp_count=$(cd "$dir" && git diff --cached --name-only | wc -l)
        staged_count=${tmp_count//[[:space:]]/}
        
        # Count unpushed commits
        tmp_count=$(cd "$dir" && git log --oneline @{u}..HEAD 2>/dev/null | wc -l)
        unpushed_commits=${tmp_count//[[:space:]]/}
        if [[ -z "$unpushed_commits" ]]; then
            unpushed_commits=0
        fi
        
        # Count unpushed tags
        local tag_output
        tag_output=$(cd "$dir" && git push --tags --dry-run 2>/dev/null) || tag_output=""
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
      
      # Use shorter labels to prevent wrapping
      # Clean all variables to ensure they don't contain extra characters
      clean_unstaged="${unstaged_count//[[:space:]]/}"
      clean_staged="${staged_count//[[:space:]]/}"
      clean_unpushed="${unpushed_commits//[[:space:]]/}"
      clean_tags="${unpushed_tags//[[:space:]]/}"
      
      printf "%-15s %-25s %-15s %-10s %-10s %-10s %-10s\n" "$dir" "$name" "$version" "$clean_unstaged" "$clean_staged" "$clean_unpushed" "$clean_tags"
    else
      printf "%-15s %-25s %-15s %-10s %-10s %-10s %-10s\n" "$dir" "$name" "Dir not found" "-" "-" "-" "-"
    fi
  done
}

# Stage all files for a specific project or all projects
stage_all_files() {
  local package_name="$1"
  shift
  local exclude_packages=()
  
  # Parse --exclude arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --exclude)
        if [[ -n "$2" && "$2" != --* ]]; then
          exclude_packages+=("$2")
          shift 2
        else
          error "--exclude requires a package name"
          return 1
        fi
        ;;
      *)
        shift
        ;;
    esac
  done
  
  if [[ -n "$package_name" ]]; then
    # Stage files for a specific project
    if [[ -d "$package_name" ]]; then
      log "Staging all files in $package_name..."
      cd "$package_name" && git add . && cd ..
      success "All files in $package_name have been staged"
    else
      error "Directory $package_name does not exist"
      return 1
    fi
  else
    # Stage files for all projects
    log "Staging all files in all projects..."

    # Stage files in each package directory
    for pkg in "${PACKAGES[@]}"; do
      IFS=':' read -r dir name <<< "$pkg"
      
      # Check if this package should be excluded
      local excluded=false
      for excluded_pkg in "${exclude_packages[@]}"; do
        if [[ "$dir" == "$excluded_pkg" ]]; then
          excluded=true
          log "Skipping $dir (excluded)"
          break
        fi
      done
      
      if [[ "$excluded" == false && -d "$dir" ]]; then
        cd "$dir" && git add . && cd ..
      fi
    done
    
    success "All files in all projects have been staged"
  fi
}

# Push changes for a specific project or all projects
git_push() {
  local package_name="$1"
  shift
  local exclude_packages=()
  
  # Parse --exclude arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --exclude)
        if [[ -n "$2" && "$2" != --* ]]; then
          exclude_packages+=("$2")
          shift 2
        else
          error "--exclude requires a package name"
          return 1
        fi
        ;;
      *)
        shift
        ;;
    esac
  done
  
  if [[ -n "$package_name" ]]; then
    # Push changes for a specific project
    if [[ -d "$package_name" ]]; then
      log "Pushing changes in $package_name..."
      cd "$package_name" && git push && cd ..
      cd "$package_name" && git push --tags && cd ..
      success "Changes in $package_name have been pushed"
    else
      error "Directory $package_name does not exist"
      return 1
    fi
  else
    # Push changes for all projects
    log "Pushing changes in all projects..."

    # Push changes in each package directory
    for pkg in "${PACKAGES[@]}"; do
      IFS=':' read -r dir name <<< "$pkg"
      
      # Check if this package should be excluded
      local excluded=false
      for excluded_pkg in "${exclude_packages[@]}"; do
        if [[ "$dir" == "$excluded_pkg" ]]; then
          excluded=true
          log "Skipping $dir (excluded)"
          break
        fi
      done
      
      if [[ "$excluded" == false && -d "$dir" ]]; then
        log "Pushing changes in $dir..."
        cd "$dir" && git push && cd ..
        cd "$dir" && git push --tags && cd ..
      fi
    done
    
    success "Changes in all projects have been pushed"
  fi
}

# Push tags for a specific project or all projects
git_push_tags() {
  local package_name="$1"
  shift
  local exclude_packages=()
  
  # Parse --exclude arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --exclude)
        if [[ -n "$2" && "$2" != --* ]]; then
          exclude_packages+=("$2")
          shift 2
        else
          error "--exclude requires a package name"
          return 1
        fi
        ;;
      *)
        shift
        ;;
    esac
  done
  
  if [[ -n "$package_name" ]]; then
    # Push tags for a specific project
    if [[ -d "$package_name" ]]; then
      log "Pushing tags in $package_name..."
      cd "$package_name" && git push --tags && cd ..
      success "Tags in $package_name have been pushed"
    else
      error "Directory $package_name does not exist"
      return 1
    fi
  else
    # Push tags for all projects
    log "Pushing tags in all projects..."

    # Push tags in each package directory
    for pkg in "${PACKAGES[@]}"; do
      IFS=':' read -r dir name <<< "$pkg"
      
      # Check if this package should be excluded
      local excluded=false
      for excluded_pkg in "${exclude_packages[@]}"; do
        if [[ "$dir" == "$excluded_pkg" ]]; then
          excluded=true
          log "Skipping $dir (excluded)"
          break
        fi
      done
      
      if [[ "$excluded" == false && -d "$dir" ]]; then
        log "Pushing tags in $dir..."
        cd "$dir" && git push --tags && cd ..
      fi
    done
    
    success "Tags in all projects have been pushed"
  fi
}

# Update libraries in all relevant packages
update_libraries() {
  local exclude_packages=()
  
  # Parse --exclude arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --exclude)
        if [[ -n "$2" && "$2" != --* ]]; then
          exclude_packages+=("$2")
          shift 2
        else
          error "--exclude requires a package name"
          return 1
        fi
        ;;
      *)
        shift
        ;;
    esac
  done
  
  log "Updating libraries in all relevant packages..."
  
  # Packages that have the update-libraries script
  local update_packages=(
    "admin"
    "calculator"
    "cli"
    "connector-irc"
    "dice"
    "echo"
    "emote"
    "help"
    "operator"
    "router"
    "tell"
    "urltitle"
    "weather"
  )
  
  local updated_count=0
  
  # Update libraries in each package
  for package in "${update_packages[@]}"; do
    # Check if this package should be excluded
    local excluded=false
    for excluded_pkg in "${exclude_packages[@]}"; do
      if [[ "$package" == "$excluded_pkg" ]]; then
        excluded=true
        log "Skipping $package (excluded)"
        break
      fi
    done
    
    if [[ "$excluded" == false && -d "$package" ]]; then
      log "Updating libraries in $package..."
      if cd "$package" && npm run update-libraries; then
        cd ..
        success "Libraries updated in $package"
        ((updated_count++))
      else
        cd ..
        error "Failed to update libraries in $package"
      fi
    elif [[ ! -d "$package" ]]; then
      warn "Directory $package does not exist, skipping..."
    fi
  done
  
  success "Library updates completed in $updated_count packages"
}

# Show help
show_help() {
  echo "
Eevee Bot Version Manager

Usage:
  ./vm.sh status                           - Show current versions and git status
  ./vm.sh version <package> [bump]         - Version a specific package (creates commits and tags, but does not push)
  ./vm.sh version-all [bump] [--exclude package]... - Version all packages (creates commits and tags, but does not push)
  ./vm.sh stage-all [package] [--exclude package]... - Stage all files for a project or all projects
  ./vm.sh git-push [package] [--exclude package]... - Push changes for a project or all projects
  ./vm.sh git-push-tags [package] [--exclude package]... - Push tags for a project or all projects
  ./vm.sh update-libraries [--exclude package]... - Update libraries in all relevant packages
  ./vm.sh help                             - Show this help

Bump types: major, minor, patch (default: patch)

Note: Versioning commands create commits and tags locally but do not automatically push.
Use git-push and git-push-tags commands to push changes to remote repositories.

Examples:
  ./vm.sh version admin patch "Fixed admin panel bug"
  ./vm.sh version-all minor "Added new features"
  ./vm.sh version-all patch --exclude docs --exclude helm
  ./vm.sh stage-all                - Stage all files in all projects
  ./vm.sh stage-all admin          - Stage all files in admin project
  ./vm.sh stage-all --exclude docs --exclude helm
  ./vm.sh git-push                 - Push changes in all projects
  ./vm.sh git-push admin           - Push changes in admin project
  ./vm.sh git-push --exclude docs --exclude helm
  ./vm.sh update-libraries         - Update libraries in all relevant packages
  ./vm.sh update-libraries --exclude admin --exclude cli
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
        error "Package name required"
        show_help
        exit 1
      fi
      local package_name="$1"
      local bump_type="${2:-patch}"
      local message="${3:-Version bump $bump_type}"
      version_package "$package_name" "$bump_type" "$message"
      ;;
    version-all)
      local bump_type="patch"
      local message="Bulk version bump patch"
      
      # Parse arguments until we hit a flag or run out
      if [[ $# -gt 0 && "$1" != --* ]]; then
        bump_type="$1"
        message="Bulk version bump $bump_type"
        shift
      fi
      
      if [[ $# -gt 0 && "$1" != --* ]]; then
        message="$1"
        shift
      fi
      
      # Pass remaining args (including flags like --exclude) to version_all
      version_all "$bump_type" "$message" "$@"
      ;;
    stage-all)
      local package_name="$1"
      # Shift past known arguments to pass remaining args (like --exclude) to stage_all_files
      shift 1 2>/dev/null || true
      stage_all_files "$package_name" "$@"
      ;;
    git-push)
      local package_name="$1"
      # Shift past known arguments to pass remaining args (like --exclude) to git_push
      shift 1 2>/dev/null || true
      git_push "$package_name" "$@"
      ;;
    update-libraries)
      update_libraries "$@"
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
