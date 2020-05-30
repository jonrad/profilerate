DIR=$(dirname "$0")
export PROFILERATE_ID=$(basename $DIR)
if [ -x "$(command -v zsh)" ]; then
  zsh
elif [ -x "$(command -v bash)" ]; then
  bash --init-file $DIR/profilerate.sh
else
  sh
fi
