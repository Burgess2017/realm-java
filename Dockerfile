FROM ubuntu:18.04

# Locales
RUN apt-get clean && apt-get -y update && apt-get install -y locales && locale-gen en_US.UTF-8
ENV LANG "en_US.UTF-8"
ENV LANGUAGE "en_US.UTF-8"
ENV LC_ALL "en_US.UTF-8"
ENV TZ=Europe/Copenhagen
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Set the environment variables
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV ANDROID_HOME /opt/android-sdk-linux
# Need by cmake
ENV ANDROID_NDK_HOME /opt/android-ndk
ENV ANDROID_NDK /opt/android-ndk
ENV PATH ${PATH}:${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools
ENV PATH ${PATH}:${NDK_HOME}
ENV NDK_CCACHE /usr/bin/ccache

# Keep the packages in alphabetical order to make it easy to avoid duplication
# tzdata needs to be installed first. See https://askubuntu.com/questions/909277/avoiding-user-interaction-with-tzdata-when-installing-certbot-in-a-docker-contai
# `file` is need by the Android Emulator
# FIXME: Ask Yavor/Jacek about how to best configure qemu/kvm
RUN DEBIAN_FRONTEND=noninteractive \
    && apt-get update -qq \
    && apt-get install -y tzdata \
    && apt-get install -y bsdmainutils \
                          build-essential \
                          ccache \
                          curl \
                          file \
                          git \
                          jq \
                          libc6 \
                          libgcc1 \
                          libncurses5 \
                          libstdc++6 \
                          libz1 \
                          openjdk-8-jdk-headless \
                          qemu-system-x86_64 \
                          s3cmd \
                          unzip \
                          wget \
                          zip \
    && apt-get clean

# https://stackoverflow.com/questions/48422001/how-to-launch-qemu-kvm-from-inside-a-docker-container    
RUN qemu-system-x86_64
RUN emu-system-x86_64 \
  -append 'root=/dev/vda console=ttyS0' \
  -drive file='rootfs.ext2.qcow2,if=virtio,format=qcow2'  \
  -enable-kvm \
  -kernel 'bzImage' \
  -nographic

# Install the Android SDK
RUN cd /opt && \
    wget -q https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip -O android-tools-linux.zip && \
    unzip android-tools-linux.zip -d ${ANDROID_HOME} && \
    rm -f android-tools-linux.zip

# Grab what's needed in the SDK
RUN sdkmanager --update

# Accept licenses before installing components, no need to echo y for each component
# License is valid for all the standard components in versions installed from this file
# Non-standard components: MIPS system images, preview versions, GDK (Google Glass) and Android Google TV require separate licenses, not accepted there
RUN yes | sdkmanager --licenses

# SDKs
# Please keep these in descending order!
# The `yes` is for accepting all non-standard tool licenses.
# Please keep all sections in descending order!
RUN yes | sdkmanager \
    'platform-tools' \
    'build-tools;29.0.2' \
    'extras;android;m2repository' \
    'platforms;android-29' \
    'cmake;3.6.4111459' \
    'ndk;21.0.6113669' \
    'emulator' \
    'system-images;android-29;default;x86'

# Make the SDK universally writable
RUN chmod -R a+rwX ${ANDROID_HOME}
