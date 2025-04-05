#!/bin/bash
set -e  # Exit on error

# ============================================
# Citron Build Script
# ============================================
# This script:
# - Clones or updates the official Citron repository
# - Checks out a specific version (default: master)
# - Builds Citron using CMake and Ninja
# - Creates an AppImage package using appimagetool-x86_64.AppImage
# - Saves the output to OUTPUT_DIR
# ============================================
# # ============================================

# Set the Citron version (default to 'master' if not provided)
CITRON_VERSION=${CITRON_VERSION:-master}
CITRON_BUILD_MODE=${CITRON_BUILD_MODE:-steamdeck}  # Default to SteamDeck build
OUTPUT_LINUX_BINARIES=${OUTPUT_LINUX_BINARIES:-false}  # Default to not output binaries
USE_CACHE=${USE_CACHE:-false}  # Default to not using cache

# Set output and working directories
OUTPUT_DIR=${OUTPUT_DIR:-"/root/output"}
mkdir -p "${OUTPUT_DIR}"
sudo chmod -R 777 "${OUTPUT_DIR}"
WORKING_DIR=${WORKING_DIR:-"/root"}

# Define build configurations
case "$CITRON_BUILD_MODE" in
  release)
    CXX_FLAGS="-march=native -mtune=native -Wno-error"
    C_FLAGS="-march=native -mtune=native"
    ;;
  steamdeck)
    CXX_FLAGS="-march=znver2 -mtune=znver2 -Wno-error"
    C_FLAGS="-march=znver2 -mtune=znver2"
    ;;
  compatibility)
    CXX_FLAGS="-march=core2 -mtune=core2 -Wno-error"
    C_FLAGS="-march=core2 -mtune=core2"
    ;;
  debug)
    CXX_FLAGS="-march=native -mtune=native -Wno-error"
    C_FLAGS="-march=native -mtune=native"
    BUILD_TYPE=Debug
    ;;
  *)
    echo "❌ Error: Unknown build mode '$CITRON_BUILD_MODE'. Use 'release', 'steamdeck', 'compatibility', or 'debug'."
    exit 1
    ;;
esac

BUILD_TYPE=${BUILD_TYPE:-Release}  # Default to Release mode

echo "🛠️ Building Citron (Version: ${CITRON_VERSION}, Mode: ${CITRON_BUILD_MODE}, Build: ${BUILD_TYPE})"

# Check if CITRON_VERSION exists on the remote repository
#CITRON_REPO="https://git.citron-emu.org/Citron/Citron.git"
CITRON_REPO="https://github.com/WolfSc84/Citron_Wolf.git"

# Check if CITRON_VERSION is a commit hash
if [[ "${CITRON_VERSION}" =~ ^[0-9a-f]{7,40}$ ]]; then
    echo "🔍 Commit hash detected: ${CITRON_VERSION}"
    COMMIT_HASH="${CITRON_VERSION}"
    # Reset CITRON_VERSION to 'master' to later attempt to checkout the commit hash
    CITRON_VERSION="master"
    echo "🔍 Resetting Citron Version to 'master' to later checkout commit hash '${COMMIT_HASH}'"
fi

# Preparing the citron repository
# This section checks if the specified Citron version exists in the remote repository.
# If it doesn't exist, it attempts to use a cached repository if available.
# If the version exists, it clones or updates the repository accordingly.
echo "🔎 Checking if version '${CITRON_VERSION}' exists in the remote repository..."

CACHE_FILENAME="citron.tar.zst"
CACHE_FILE="${OUTPUT_DIR}/${CACHE_FILENAME}"
CLONE_DIR="${WORKING_DIR}/Citron"

# Check if the specified version exists in the remote repository and is accessible
if ! git ls-remote --exit-code --refs "$CITRON_REPO" "refs/heads/${CITRON_VERSION}" > /dev/null && ! git ls-remote --exit-code --refs "$CITRON_REPO" "refs/tags/${CITRON_VERSION}" > /dev/null; then
    echo "⚠️ Warning: The specified version or branch '${CITRON_VERSION}' does not exist in the remote repository or the repository is not accessible."
    
    # Check if the cache file exists and use it if available
    if [ "$USE_CACHE" = "true" ] && [ -f "$CACHE_FILE" ]; then
        echo "📥 Falling back to cached repository ${CACHE_FILENAME}..."
        cp --preserve=all "$CACHE_FILE" "$WORKING_DIR/"
        
        # Extract the cached repository
        tar --use-compress-program=zstd -xf "$CACHE_FILENAME" -C "$WORKING_DIR"

        cd "$CLONE_DIR"
        git config --global --add safe.directory "$CLONE_DIR"
        
        # Try to checkout the cached repository with the specified version
        if ! git checkout "${CITRON_VERSION}" && ! git checkout "tags/${CITRON_VERSION}"; then
            echo "❌ Error: Failed to checkout the cached repository with version '${CITRON_VERSION}'. Please verify the cache is a valid citron repository and try again."
            exit 1
        fi
    else
        echo "❌ Error: Cache option not available."
        echo "🔎 Please verify that ${CACHE_FILENAME} exists in the current directory and is a valid citron repository, enable the use cache option then try again."
        exit 1
    fi
else
    echo "✅ Version '${CITRON_VERSION}' exists in the remote repository."

    cd "$WORKING_DIR"

    # Clone or use existing cached repository
    if [ "$USE_CACHE" = "true" ] && [ -f "$CACHE_FILE" ]; then
        echo "📥 Using cached repository ${CACHE_FILENAME}..."
        cp --preserve=all "$CACHE_FILE" "$WORKING_DIR/"
        
        # Extract the cached repository
        tar --use-compress-program=zstd -xf "$CACHE_FILENAME" -C "$WORKING_DIR"

        cd "$CLONE_DIR"
        git config --global --add safe.directory "$CLONE_DIR"
        
        # Update the repository to the latest commit of the given version, if remote connection fails now, fallback to cached repository
        echo "🔄 Updating the repository to the latest commit of ${CITRON_VERSION}..."
        if ! git fetch --all --tags --prune; then
            echo "⚠️ Warning: Failed to fetch the latest changes from the remote repository. Falling back to the cached repository..."
            cd "$WORKING_DIR"
            if ! git checkout "${CITRON_VERSION}" && ! git checkout "tags/${CITRON_VERSION}"; then
                echo "❌ Error: Failed to checkout the cached repository with version '${CITRON_VERSION}'. Please verify the cache is a valid citron repository and try again."
                exit 1
            fi
        else
            git submodule update --init --recursive # Update submodules
            if ! git reset --hard "origin/${CITRON_VERSION}"; then
                echo "⚠️ Warning: Failed to reset to origin/${CITRON_VERSION}, trying tags/${CITRON_VERSION}..."
                git checkout "tags/${CITRON_VERSION}"
            fi
        fi
    else
        echo "📥 Cloning Citron repository..."
        if ! git clone --recursive "$CITRON_REPO" "$CLONE_DIR"; then
            echo "❌ Error: Failed to clone the Citron repository."
            exit 1
        fi

        cd "$CLONE_DIR"
        git checkout "${CITRON_VERSION}" || git checkout "tags/${CITRON_VERSION}"

        # Cache the repository for future builds if USE_CACHE=true
        cd "$WORKING_DIR"
        if [ "$USE_CACHE" = "true" ]; then
            echo "💾 Caching repository to file ${CACHE_FILENAME}..."
            tar --use-compress-program=zstd -cf "$CACHE_FILE" -C "$WORKING_DIR" Citron
        fi
    fi
fi

# Try to checkout COMMIT_HASH if it was set
if [ -n "$COMMIT_HASH" ]; then
    echo "🔍 Checking out commit hash '${COMMIT_HASH}'..."
    cd "$CLONE_DIR"
    if ! git checkout "$COMMIT_HASH"; then
        echo "❌ Error: Failed to checkout commit hash '${COMMIT_HASH}'."
        exit 1
    fi
fi

echo "✅ Repository is ready at ${CLONE_DIR}"

# Get the short hash of the current commit
cd "$CLONE_DIR"
GIT_COMMIT_HASH=$(git rev-parse --short HEAD)
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

# Build Citron
mkdir -p ${WORKING_DIR}/Citron/build
cd ${WORKING_DIR}/Citron/build

cmake .. -GNinja \
  -DCITRON_ENABLE_LTO=ON \
  -DCITRON_USE_BUNDLED_VCPKG=ON \
  -DCITRON_TESTS=OFF \
  -DCITRON_USE_LLVM_DEMANGLE=OFF \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DCMAKE_CXX_FLAGS="$CXX_FLAGS" \
  -DCMAKE_C_FLAGS="$C_FLAGS" \
  -DUSE_DISCORD_PRESENCE=OFF \
  -DBUNDLE_SPEEX=ON \
  -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5

ninja
ninja install

# Set output file name
if [[ "$CITRON_VERSION" == "master" ]]; then
    OUTPUT_NAME="citron-nightly-${CITRON_BUILD_MODE}-${TIMESTAMP}-${GIT_COMMIT_HASH}"
else
    OUTPUT_NAME="citron-${CITRON_VERSION}-${CITRON_BUILD_MODE}"
fi

# Copy Linux binaries if enabled
if [ "$OUTPUT_LINUX_BINARIES" = "true" ]; then
    mkdir -p ${OUTPUT_DIR}/linux-binaries-${OUTPUT_NAME}
    cp -r ${WORKING_DIR}/Citron/build/bin/* ${OUTPUT_DIR}/linux-binaries-${OUTPUT_NAME}/
    echo "✅ Linux binaries copied to ${OUTPUT_DIR}/linux-binaries-${OUTPUT_NAME}"
fi

# Build the AppImage
cd ${WORKING_DIR}/Citron
${WORKING_DIR}/Citron/appimage-builder.sh citron ${WORKING_DIR}/Citron/build

# Prepare AppImage deployment
cd ${WORKING_DIR}/Citron/build/deploy-linux
cp /usr/lib/libSDL3.so* ${WORKING_DIR}/Citron/build/deploy-linux/AppDir/usr/lib/
wget https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage
# Workaround for lack of FUSE support in WSL
./appimagetool-x86_64.AppImage --appimage-extract
chmod +x ./squashfs-root/AppRun
./squashfs-root/AppRun AppDir

# Move the most recently created AppImage to a fresh output folder
APPIMAGE_PATH=$(ls -t ${WORKING_DIR}/Citron/build/deploy-linux/*.AppImage 2>/dev/null | head -n 1)
chmod +x "$APPIMAGE_PATH"
chmod 777 "$APPIMAGE_PATH"

if [[ -n "$APPIMAGE_PATH" ]]; then
    mv -f "$APPIMAGE_PATH" "${OUTPUT_DIR}/${OUTPUT_NAME}.AppImage"
    echo "✅ Build complete! The AppImage is located in ${OUTPUT_DIR}/${OUTPUT_NAME}.AppImage"
else
    echo "❌ Error: No .AppImage file found in ${WORKING_DIR}/Citron/build/deploy-linux/"
    exit 1
fi
