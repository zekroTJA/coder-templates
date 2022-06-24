ARG BASE_IMAGE="codercom/enterprise-base:ubuntu"

FROM ${BASE_IMAGE}

USER root

RUN apt update -y && apt upgrade -y

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

# Install Corepack / Yarn
RUN corepack enable \
    && npm i -g corepack

USER coder
RUN echo "export PATH=$PATH:$GOROOT/bin" >> ~/.profile