FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
	apt-get install -y --fix-missing tcsh xfonts-base libssl-dev       \
	    python-is-python3                 \
	    python3-matplotlib                \
	    gsl-bin netpbm gnome-tweak-tool   \
	    libjpeg62 xvfb xterm vim curl     \
	    gedit evince eog                  \
	    libglu1-mesa-dev libglw1-mesa     \
	    libxm4 build-essential            \
	    libcurl4-openssl-dev libxml2-dev  \
	    libgfortran-8-dev libgomp1        \
	    gnome-terminal nautilus           \
	    gnome-icon-theme-symbolic         \
	    firefox xfonts-100dpi             \
	    r-base-dev && \
    ln -s /usr/lib/x86_64-linux-gnu/libgsl.so.23 /usr/lib/x86_64-linux-gnu/libgsl.so.19 && \
    ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime && \
	dpkg-reconfigure --frontend noninteractive tzdata && \
    curl -O https://afni.nimh.nih.gov/pub/dist/bin/misc/@update.afni.binaries && \
	tcsh @update.afni.binaries -package linux_ubuntu_16_64 -do_extras && \
	export PATH=$PATH:/root/abin/:/root/R && \
	export R_LIBS=/root/R && \
	mkdir  $R_LIBS && \
	echo  'setenv R_LIBS /root/R'     >> ~/.cshrc && \
	echo  'export R_LIBS=/root/R' >> ~/.bashrc && \
	rPkgsInstall -pkgs ALL && \
	apt-get update && \
	apt-get install -y libv8-dev && \
	rPkgsInstall -pkgs brms && \
	@update.afni.binaries -d

ENV PATH=$PATH:/root/abin:/root/R
ENV R_LIBS=/root/R
