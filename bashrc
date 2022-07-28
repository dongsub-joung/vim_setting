export PATH="/usr/local/go/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# rustup
#
# avoid https://github.com/rust-analyzer/rust-analyzer/issues/4172
#
# NOTE: Has to be defined after PATH update to locate .cargo directory.
#
export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"

# To support the configuring our go environment we will override the cd
# command to call the go logic for checking the go version.
#
# We also make sure to call ls when changing directories as it's nice to see
# what's in each directory.
#
# NOTE: We use `command` and not `builtin` because the latter doesn't take into
# account anything available on the user's $PATH but also because it didn't
# work with the Starship prompt which seems to override cd also.
function cd {
  command cd "$@"
  RET=$?
  ls
  go_version
  return $RET
}

# configure go environment
#
# Custom go binaries are installed in $HOME/go/bin.
#
function go_version {
    if [ -f "go.mod" ]; then
        v=$(grep -E '^go \d.+$' ./go.mod | grep -oE '\d.+$')
        if [[ ! $(go version | grep "go$v") ]]; then
          echo ""
          echo "About to switch go version to: $v"
          if ! command -v "$HOME/go/bin/go$v" &> /dev/null
          then
            echo "run: go install golang.org/dl/go$v@latest && go$v download && sudo cp \$(which go$v) \$(which go)"
            return
          fi
          sudo cp $(which go$v) $(which go)
        fi
    fi
}
if [ ! -f "$HOME/go/bin/gofumpt" ]; then
    go install mvdan.cc/gofumpt@latest
fi
if [ ! -f "$HOME/go/bin/revive" ]; then
    go install github.com/mgechev/revive@latest
fi

# configure rust environment
#
# - autocomplete
# - rust-analyzer
# - cargo audit
# - cargo-nextest
# - cargo fmt
# - cargo clippy
# - cargo edit
#
source $HOME/.cargo/env
if [ ! -f "$HOME/.config/rustlang/autocomplete/rustup" ]; then
  mkdir -p ~/.config/rustlang/autocomplete
  rustup completions bash rustup >> ~/.config/rustlang/autocomplete/rustup
fi
source "$HOME/.config/rustlang/autocomplete/rustup"
if ! command -v rust-analyzer &> /dev/null
then
  brew install rust-analyzer
fi
if ! cargo audit --version &> /dev/null; then
  cargo install cargo-audit --features=fix
fi
if ! cargo nextest --version &> /dev/null; then
  cargo install cargo-nextest
fi
if ! cargo fmt --version &> /dev/null; then
  rustup component add rustfmt
fi
if ! cargo clippy --version &> /dev/null; then
  rustup component add clippy
fi
if ! ls ~/.cargo/bin | grep 'cargo-upgrade' &> /dev/null; then
  cargo install cargo-edit
fi
