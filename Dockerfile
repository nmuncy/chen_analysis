FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
	apt-get install -y --fix-missing tcsh \
		xfonts-base libssl-dev       	  \
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
	mv /root/abin /opt && \
	export PATH=$PATH:/opt/abin:/bin/R && \
	export R_LIBS=/opt/R && \
	mkdir  $R_LIBS && \
	echo  'setenv R_LIBS /opt/R'     >> ~/.cshrc && \
	echo  'export R_LIBS=/opt/R' >> ~/.bashrc && \
	rPkgsInstall -pkgs ALL && \
	apt-get update && \
	apt-get install -y --fix-missing libv8-dev && \
	rPkgsInstall -pkgs brms && \
	mkdir /opt/c3d && \
	curl -fsSL --retry 5 https://sourceforge.net/projects/c3d/files/c3d/1.0.0/c3d-1.0.0-Linux-x86_64.tar.gz/download \
	| tar -xz -C /opt/c3d --strip-components 1

ENV PATH=$PATH:/opt/abin:/opt/R:/opt/c3d
ENV R_LIBS=/opt/R
