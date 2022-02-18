FROM gitpod/workspace-full-vnc

RUN sudo apt-get update \
 && sudo apt-get install -y \
    valac meson libgtk-3-dev libgee-0.8-dev libgranite-dev libgstreamer1.0-dev libgstreamer-plugins-bad1.0-dev libsoup2.4-dev libjson-glib-dev libgeoclue-2-dev libgeocode-glib-dev

RUN echo 'deb http://download.opensuse.org/repositories/home:/Prince781/xUbuntu_21.10/ /' | sudo tee /etc/apt/sources.list.d/home:Prince781.list
RUN curl -fsSL https://download.opensuse.org/repositories/home:Prince781/xUbuntu_21.10/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_Prince781.gpg > /dev/null
RUN sudo apt update
RUN sudo apt install vala-language-server

RUN sudo rm -rf /var/lib/apt/lists/*