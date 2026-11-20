FROM docker.io/docker/sandbox-templates:opencode-docker

USER root

# The sandbox mounts its public CA bundle under /.msb with dialout group access.
RUN usermod -aG dialout agent

RUN apt-get update \
    && apt-get install -y --no-install-recommends vim git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV EDITOR=vim
ENV VISUAL=vim
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV HOME=/usr/local/share/acq-vim
WORKDIR /usr/local/share/acq-vim
RUN mkdir -p "$HOME" && chown agent:agent "$HOME"

# ACQ provisions /home/agent after the image starts. Store the baked assets
# outside that managed home directory, then install them after provisioning.
COPY --chown=agent:agent dotfiles/.acq.vimrc         .vimrc
COPY --chown=agent:agent dotfiles/.acq.plugins.vimrc .plugins.vimrc
COPY --chown=agent:agent dotfiles/.vim               .vim

# Pre-fetch vim-plug, every Plug'd plugin (incl. coc.nvim), and every coc.nvim
# extension in g:coc_global_extensions at build time instead of at editor-open
# time, so new sandboxes don't pay the PlugInstall/CocInstall cost on first
# `vim` launch.
USER agent
RUN set -eux; \
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim; \
    vim -V1"$HOME/vim-plug.log" -Es -u "$HOME/.plugins.vimrc" \
      -c 'PlugInstall --sync' -c 'qa!' \
      || { status=$?; cat "$HOME/vim-plug.log"; exit "$status"; }; \
    vim -V1"$HOME/coc-install.log" -Es -u "$HOME/.vimrc" \
      -c "execute 'CocInstall -sync ' . join(g:coc_global_extensions)" \
      -c 'qa!' \
      || { status=$?; cat "$HOME/coc-install.log"; exit "$status"; }; \
    vim -Es -u "$HOME/.vimrc" \
      -c "for extension in g:coc_global_extensions | if !filereadable(expand('~/.config/coc/extensions/node_modules/' . extension . '/package.json')) | echoerr 'Missing pre-baked CoC extension: ' . extension | cquit 1 | endif | endfor" \
      -c 'qa!'

USER root
COPY acq-install-vim-config /usr/local/bin/acq-install-vim-config
RUN chmod 0755 /usr/local/bin/acq-install-vim-config \
    && chown -R root:root /usr/local/share/acq-vim

USER agent
ENV HOME=/home/agent
WORKDIR /home/agent
