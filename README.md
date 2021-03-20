# docker-dump1090
:whale2: Dockerfile to create an Alpine Linux image to run Dump1090 a simple Mode S decoder for RTLSDR devices

This image is intended to be used in a containerized Docker application, however it can be used standalone. 

You can run a pre-built image for the Raspberry Pi from Docker Hub using this command:

```
docker run -it --device/dev/bus/usb tjdean/dump1090 --interactive
```

If there are any aircraft flying within range of your receiver, you will see something similar to this:

![image](https://user-images.githubusercontent.com/45572244/111875319-10cbff80-8991-11eb-9685-417a97d3091c.png)

You can build the image yourself by downloading the Dockerfile and then use this command:

```
docker build --rm -t dump1090 .
```
