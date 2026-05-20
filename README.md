# docker-dump1090

> [!NOTE]
> **May 2025** - Major update to allow the latest versions of the FlightAware fork of Dump1090 to run on my old Raspberry PI 3 model B.

:whale2: Dockerfile to create a Docker image to run Dump1090 that is a self-contained ADS-B receiver that decodes aircraft transponder messages from a directly connected RTL-USB dongle and serves them over a local network.  The image only includes the binaries required to run dump1090 and nothing else to ensure that the container only has one concern.  This image is intended to be used in a containerized Docker application, however it can be used standalone.

## Dependencies

### [osmocom/rtl-sdr](https://github.com/osmocom/rtl-sdr)
 
Turns a Realtek RTL2832-based DVB-T USB dongle into a software defined radio (SDR) receiver. Required to interface with the hardware at the OS level.
### [flightaware/dump1090](https://github.com/flightaware/dump1090)

An ADS-B, Mode S, and Mode 3A/3C demodulator and decoder. Receives and decodes aircraft transponder messages from a directly connected SDR, or from data provided over a network connection.

## Host Driver Blacklisting

By default Linux will load the `dvb_usb_rtl28xxu` kernel module when the RTL-SDR dongle is plugged in, claiming the device before dump1090 (or the rtl-sdr library) can access it.  This must be prevented by blacklisting the relevant kernal module on the Raspberry Pi host.

Create a blacklist file:

```
sudo nano /etc/modprobe.d/rtlsdr-backlist.conf
```
Add the following lines:
```
blacklist dvb_usb_rtl28xxu
blacklist rtl2832
blacklist rtl2830
```
Then update the initramfs and reboot:
```
sudo update-initramfs -u
sudo reboot
```
After rebooting, verify the modules are not loaded:
```
lsmod | grep dvb
```
If the output is empty, the dongle is free for the container to use.  If any modules still appear, unload them manually with `sudo modprobe -r <module_name>` and check the blacklist file is saved correctly.

## Build Image

### Standard Build

1. Open a terminal on your system.
2. Navigate to the directory containing your **Dockerfile**.
3. Run `docker build --rm -t dump1090 .` If this is a rebuild it will use the existing cache.
4. Verify the image with `docker images` to confirm the new build is listed.

### Clean Build Without Cache

1. Open a terminal and go to your Dockerfile's directory.
2. Run `docker build --no-cache --rm -t dump1090 .`
3. Confirm the build by running  `docker images`

> [!NOTE]
> The `--rm` flag in the `docker build` command is used to **remove intermediate containers** after a successful build.
> This helps in keeping your system clean by not leaving behind any unnecessary intermediate containers.

## Run Container

To test everything is working as expected and you are receiving data from any aircraft in range

1. Open a terminal.
2. Run `docker run -it --device /dev/bus/usb dump1090 --interactive`
3. `-it` runs the container interactively. Combines `-i` (interactive mode) and `-t` (allocates a pseudo-TTY), allowing you to interact with the container in real-time.
4. `--device /dev/bus/usb` passes through the host's USB bus so the container can access the RTL-SDR dongle.
5. `--interactive` runs dump1090 in terminal mode, displaying the decoded messages directly.  This is good for testing purposes.

If there are any aircraft flying within range of your receiver, you will see something similar to this:

<img width="813" height="537" alt="image" src="https://github.com/user-attachments/assets/d3eeb1fd-3b86-4192-a2df-92c886c169e0" />

## Network Ports

When networking is enabled with `--net`, dump1090 listens on the following ports:

| Port | Purpose |
|------|---------|
| 8080 | Web interface (map view) |
| 30001 | Raw input — feed dump1090 with data in raw format |
| 30002 | Raw output — decoded data sent to clients as it arrives |
| 30003 | SBS1 (BaseStation) format output — suitable for feeding sharing sites |
| 30004 | Beast-format input |
| 30005 | Beast-format output |

Port 30003 outputs messages in SBS1 format, for example:
```
MSG,4,,,738065,,,,,,,,420,179,,,0,,0,0,0,0
MSG,3,,,738065,,,,,,,35000,,,34.81609,34.07810,,,0,0,0,0
```
This can be used to feed data to various sharing sites without the need for a separate decoder.



