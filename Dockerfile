# Use Arch Linux as the base image
FROM archlinux:latest

# Install dependencies
RUN pacman -Syu --needed --noconfirm base-devel boost catch2 cmake ffmpeg fmt git glslang libzip lz4 \
    mbedtls ninja nlohmann-json openssl opus qt5 sdl2 zlib zstd zip unzip qt6-base qt6-tools qt6-svg \
    qt6-declarative qt6-webengine sdl3 qt6-multimedia clang qt6-wayland fuse2 rapidjson wget sdl3 dos2unix

# Set working directory
WORKDIR /root

# Creating folder to place artifcat
RUN ls -a
RUN mkdir -p /root/output
RUN chmod 777 /root/output
RUN ls -a

# Copy the build script
COPY build-citron.sh /root/build-citron.sh
RUN chmod +x /root/build-citron.sh

# Convert any CRLF line endings to just LF
RUN dos2unix /root/build-citron.sh

# Set output directory as a volume
VOLUME ["/output"]

# Set default entrypoint
ENTRYPOINT ["/root/build-citron.sh"]
