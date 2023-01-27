ARG BASE_IMAGE="codercom/enterprise-base:ubuntu"

FROM ${BASE_IMAGE}

USER root

RUN apt update -y && apt upgrade -y
RUN apt install -y wget

# Install Go
RUN curl -L https://gist.githubusercontent.com/zekroTJA/87d560e04c68703efe384bd273c3901c/raw/836cf9b4b1f52cfd83ed222daa09412c1bcf4d6a/golang-download-latest.sh | bash -
ENV GOROOT /usr/local/go
ENV PATH $PATH:$GOROOT/bin
ENV GOPATH /home/coder/go
ENV GOBIN $GOPATH/bin
ENV PATH $PATH:$GOBIN

# Install Nodejs
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt install -y nodejs

# Install Taskfile
RUN env GOBIN=/bin go install github.com/go-task/task/v3/cmd/task@latest

# Install staticcheck
RUN env GOBIN=/bin go install honnef.co/go/tools/cmd/staticcheck@latest

# Install Corepack / Yarn
RUN corepack enable \
    && npm i -g corepack

# Install Elixir
RUN wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb \
    && dpkg -i erlang-solutions_2.0_all.deb \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y esl-erlang elixir

# Install hugo
RUN apt-get install -y hugo

# Install dotnet
RUN wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y dotnet-sdk-6.0

# Install MySQL client
RUN apt-get install -y mysql-client

# Install redis-server and redis-cli
RUN apt-get install -y redis-server 

USER coder

# Install Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y \
    && source "$HOME/.cargo/env" || true

RUN echo 'export PATH=$PATH:$GOROOT/bin' >> ~/.profile
