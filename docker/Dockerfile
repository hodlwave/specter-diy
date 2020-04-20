FROM ubuntu:16.04@sha256:97b54e5692c27072234ff958a7442dde4266af21e7b688e7fca5dc5acc8ed7d9

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8

# update, upgrade, install dependencies, and clean
RUN apt-get update -q && \
    apt-get install -qy \
        git=1:2.7.4-0ubuntu1.8 \
        wget=1.17.1-1ubuntu1.5 \
        make=4.1-6 \
        autotools-dev=20150820.1 \
        autoconf=2.69-9 \
        libtool=2.4.6-0.1 \
	xz-utils=5.1.1alpha+20120614-2ubuntu2 \
        libssl-dev=1.0.2g-1ubuntu4.15 \
        libssl1.0.0=1.0.2g-1ubuntu4.15 \
        openssl=1.0.2g-1ubuntu4.15 \
        zlib1g-dev=1:1.2.8.dfsg-2ubuntu4.3 \
        libffi-dev=3.2.1-4 \	
	# TODO: pin these dependencies
    	gcc-arm-none-eabi \ 
	binutils-arm-none-eabi \
	gdb-arm-none-eabi \
	openocd && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get autoremove -y && \	
    apt-get clean

