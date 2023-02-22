FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    unzip \
    sudo \
    vim `#best text editor out there` \
    psmisc \
    expect `#used to test interactive shell` \
    git `#needed to pull bats`

WORKDIR /root

# Docker
RUN mkdir -m 0755 -p /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y docker-ce-cli

# bats bash testing framework
# TODO pin version
RUN git clone --depth 1 https://github.com/bats-core/bats-core.git && \
  cd bats-core && \
  ./install.sh /usr/local && \
  cd .. && \
  rm -rf bats-core

RUN git clone --depth 1 https://github.com/bats-core/bats-support.git bats-support && \
  git clone --depth 1 https://github.com/bats-core/bats-assert.git bats-assert && \
  mkdir -p /test_helper && \
  mv bats-support /test_helper/ && \
  mv bats-assert /test_helper/

# Remove host checking
# don't ever do this
COPY ssh_config /root/.ssh/config

# Startup
WORKDIR /code
CMD [ "./testing/tests" ]
ENTRYPOINT [ "bats" ]
