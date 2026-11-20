#!/bin/bash

podman build --tag localhost/acq-opencode-vim:local .
podman save localhost/acq-opencode-vim:local -o /tmp/acq-opencode-vim.tar
msb image load -i /tmp/acq-opencode-vim.tar -t localhost/acq-opencode-vim:local
