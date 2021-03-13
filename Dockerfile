FROM alpine:3.12 AS builder

WORKDIR /tmp

RUN apk add --no-cache \
    build-base \
    cmake \
    git \
    libusb \
    libusb-dev \
    ncurses \
    ncurses-dev

RUN mkdir -p /etc/modprobe.d && \
    echo 'blacklist r820t' >> /etc/modprobe.d/blacklist.conf && \
    echo 'blacklist rtl2832' >> /etc/modprobe.d/blacklist.conf && \
    echo 'blacklist rtl2830' >> /etc/modprobe.d/blacklist.conf && \
    echo 'blacklist dvb_usb_rtl128xxu' >> /etc/modprobe.d/blacklist.conf

RUN git clone -b 0.6.0 --depth 1 https://github.com/osmocom/rtl-sdr.git && \
    mkdir rtl-sdr/build && \
    cd rtl-sdr/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON && \
    make && \
    make install 

RUN git clone -b v4.0 https://github.com/flightaware/dump1090.git /tmp/dump1090 && \
    cd /tmp/dump1090 && \
    make dump1090 BLADERF=no

FROM alpine:3.12

LABEL Name=dump1090 Version=1.0.0

RUN apk add --no-cache \
    libusb \
    ncurses

COPY --from=builder /etc/modprobe.d/blacklist.conf /etc/modprobe.d/
COPY --from=builder /usr/local/bin/* /usr/local/bin/
COPY --from=builder /etc/udev/rules.d/rtl-sdr.rules /etc/udev/rules.d/rtl-sdr.rules
COPY --from=builder /usr/local/lib/librtlsdr* /usr/local/lib/
COPY --from=builder /tmp/dump1090/dump1090 /usr/bin

EXPOSE 30001 30002 30003 30004 3005 30104

ENTRYPOINT ["/usr/bin/dump1090"]