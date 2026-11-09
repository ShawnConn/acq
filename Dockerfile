FROM docker.io/docker/sandbox-templates:opencode-docker

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends vim \
    && rm -rf /var/lib/apt/lists/*

USER agent

ENV EDITOR=vim
ENV VISUAL=vim
