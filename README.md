# docker-dump1090
:whale2: Dockerfile to create an Alpine Linux image to run Dump1090 a simple Mode S decoder for RTLSDR devices

To test image use:
```
docker run -it --device=/dev/bus/usb dump1090 --interactive
```
