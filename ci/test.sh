#!/bin/bash -ex

cd /src/conjur-policy-parser
bundle

bundle exec rake jenkins || true
