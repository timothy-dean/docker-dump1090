# ── Stage 1: Build ──────────────────────────────────────────────────────────
FROM debian:bookworm AS builder

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    librtlsdr-dev \
    libusb-1.0-0-dev \
    pkg-config \
    libncurses5-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Build rtl-sdr from source
RUN git clone https://github.com/osmocom/rtl-sdr.git && \
    mkdir rtl-sdr/build && \
    cd rtl-sdr/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Build dump1090-fa with plain make, RTL-SDR only
RUN git clone --depth 1 https://github.com/flightaware/dump1090.git && \
    cd dump1090 && \
    make \
        BLADERF=no \
        HACKRF=no \
        LIMESDR=no \
        SOAPYSDR=no \
        -j$(nproc)

# ── Stage 2: Runtime ────────────────────────────────────────────────────────
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    libusb-1.0-0 \
    libncurses6 \
    && rm -rf /var/lib/apt/lists/*

# Copy rtl-sdr libs and tools
COPY --from=builder /usr/local/lib/librtlsdr* /usr/local/lib/
COPY --from=builder /usr/local/bin/rtl_* /usr/local/bin/

# Copy dump1090-fa binary and web assets
COPY --from=builder /build/dump1090/dump1090 /usr/bin/dump1090
COPY --from=builder /build/dump1090/view1090 /usr/bin/view1090
COPY --from=builder /build/dump1090/public_html /usr/share/dump1090/html

RUN ldconfig

EXPOSE 8080 30001 30002 30003 30004 30005

ENTRYPOINT ["/usr/bin/dump1090"]
