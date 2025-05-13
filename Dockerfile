# syntax=docker/dockerfile:1
# check=error=true

ARG RUBY_VERSION=3.4.3
FROM docker.io/library/ruby:$RUBY_VERSION-slim

# Rails app lives here
WORKDIR /workspaces/blueprinter_schema
