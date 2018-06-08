FROM phusion/baseimage

# add user developer
RUN \
  apt-get update && apt-get install -y sudo && \
  useradd -m -s /bin/bash developer && \
  echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# initialize
RUN mkdir -p /etc/my_init.d
ADD 01_fix_uid.sh /etc/my_init.d/01_fix_uid.sh

# tools
RUN \
  apt-get install -y git bzip2 tree mc

# node
RUN \
  curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
  apt-get install -y nodejs

# yarn
RUN curl -o- -L https://yarnpkg.com/install.sh | bash -s -- --version 1.5.1

# dapp.tools
RUN su developer -l -c "curl https://nixos.org/nix/install | sh"
RUN \
  su developer -l -c "nix-channel --add https://nix.dapphub.com/pkgs/dapphub && \
  nix-channel --update && \
  nix-env -iA dapphub.{dapp,seth,hevm,evmdis}" 

RUN echo "USER=`whoami`" >> /home/developer/.bashrc
RUN echo "if [ -e /home/developer/.nix-profile/etc/profile.d/nix.sh ]; then . /home/developer/.nix-profile/etc/profile.d/nix.sh; fi" >>/home/developer/.bashrc
RUN echo "cd ~/mtc" >> /home/developer/.bashrc