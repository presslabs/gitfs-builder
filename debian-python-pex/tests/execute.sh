#!/bin/sh

set -x

# Now ensure that pex can't download anything from PyPI.
export http_proxy=127.0.0.1:9
export https_proxy=127.0.0.1:9

pex -m textwrap -vv -o script && ./script
