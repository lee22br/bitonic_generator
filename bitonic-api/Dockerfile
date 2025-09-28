# Development Dockerfile
FROM almalinux:9

# Install required dependencies and Zig
RUN dnf update -y && dnf install -y \
    wget \
    xz \
    gcc \
    gcc-c++ \
    make \
    glibc-devel \
    git \
    && dnf clean all

# Download and install Zig
RUN wget -q https://ziglang.org/builds/zig-x86_64-linux-0.16.0-dev.452+1f7ee99b3.tar.xz \
    && tar -xf zig-x86_64-linux-0.16.0-dev.452+1f7ee99b3.tar.xz \
    && mv zig-x86_64-linux-0.16.0-dev.452+1f7ee99b3 /opt/zig \
    && rm zig-x86_64-linux-0.16.0-dev.452+1f7ee99b3.tar.xz \
    && ln -s /opt/zig/zig /usr/local/bin/zig

# Set the working directory
WORKDIR /app

# Set environment variables to avoid cache permission issues
ENV ZIG_CACHE_DIR=/tmp/zig-cache
ENV ZIG_GLOBAL_CACHE_DIR=/tmp/zig-global-cache

# Copy build configuration
COPY build.zig .

# Install zap dependency (this will create build.zig.zon)
RUN zig fetch --save "git+https://github.com/zigzap/zap#v0.11.0"

# Copy source code
COPY src/ ./src/

# Build the application
RUN zig build

# Expose the port
EXPOSE 8080

# Run the built application
CMD ["./zig-out/bin/bitonic-api"]
