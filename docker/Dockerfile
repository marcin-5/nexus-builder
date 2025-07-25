FROM rust:alpine
LABEL authors="marcin"

# Accept build arguments
ARG APP_NAME=nexus-builder
ARG RUST_DIR=rust
ARG TZ=UTC

# Install dependencies.
# Use a virtual package for build-time dependencies so they can be removed in a later step.
RUN apk add --no-cache --virtual .build-deps \
    musl-dev gcc libc-dev build-base \
    && apk add --no-cache \
    fish curl git fzf bash mc tzdata

# Set timezone
ENV TZ=$TZ
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install cargo-watch early in its own layer.
# This layer will be cached and only re-run if the base image changes.
RUN cargo install cargo-watch

# Set up fish plugins and apply default config for tide plugin
ENV FISH_CONFIG_DIR /root/.config/fish
RUN mkdir -p $FISH_CONFIG_DIR/functions
RUN curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish > $FISH_CONFIG_DIR/functions/fisher.fish
RUN fish -c "fisher install IlanCosman/tide && fisher install jethrokuan/fzf && fisher install jorgebucaran/autopair.fish"
RUN fish -c "tide configure --auto --style=Rainbow --prompt_colors='True color' --show_time='24-hour format' --rainbow_prompt_separators=Slanted --powerline_prompt_heads=Round --powerline_prompt_tails=Flat --powerline_prompt_style='Two lines, character and frame' --prompt_connection=Dotted --powerline_right_prompt_frame=No --prompt_connection_andor_frame_color=Dark --prompt_spacing=Sparse --icons='Many icons' --transient=Yes"

# Backup the installed and configured settings
RUN mkdir -p /opt/fish_config_default \
    && cp -r $FISH_CONFIG_DIR/* /opt/fish_config_default/

# Create app name environment variable for use by scripts
ENV APP_NAME=$APP_NAME
ENV RUST_DIR=$RUST_DIR

WORKDIR /app

# --- Caching Optimization ---
# 1. Copy only the dependency manifest files first.
COPY rust/Cargo.toml rust/Cargo.lock ./${RUST_DIR}/

# 2. Set the WORKDIR and create a dummy library file to allow `cargo fetch` to succeed.
WORKDIR /app/${RUST_DIR}
RUN mkdir src && touch src/lib.rs
RUN cargo fetch

# 3. Go back to the app's root and copy all other files.
# This overwrites the dummy file with the real one and copies the rest of your source code.
WORKDIR /app
COPY . .
# --- End of Caching Optimization ---

# Copy the entrypoint script and make it executable
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Now that the Rust code is built or dependencies are fetched,
# remove the build-time packages to reduce image size.
RUN apk del .build-deps

# Set the final WORKDIR for the command
WORKDIR /app/${RUST_DIR}

# Create directories for persistent fish history and config
RUN mkdir -p /root/.local/share/fish /root/.config/fish

# Define volumes for fish shell history and config
VOLUME ["/root/.local/share/fish", "/root/.config/fish"]

ENTRYPOINT ["entrypoint.sh"]
CMD ["cargo", "watch", "--why", "-x", "build"]
