# Debugging Ruby Applications with mirrord

<div align="center">
  <a href="https://mirrord.dev">
    <img src="images/mirrord.svg" width="150" alt="mirrord Logo"/>
  </a>
  <a href="https://www.ruby-lang.org/en/">
    <img src="images/ruby.svg" width="150" alt="Ruby Logo"/>
  </a>
</div>

## Overview

This is a sample web application built with Ruby and Redis to demonstrate debugging Kubernetes applications using mirrord. The application tracks visitor counts using Redis and displays them on a web interface.

## Prerequisites

- Ruby 3.2 or higher
- Docker and Docker Compose
- Kubernetes cluster
- mirrord CLI installed

## Quick Start

1. Clone the repository:

```bash
git clone https://github.com/waveywaves/mirrord-ruby-debug-example
cd mirrord-ruby-debug-example
```

2. Deploy to Kubernetes:

```bash
kubectl create -f ./kube
```

3. Debug with mirrord:

```bash
mirrord exec -t deployment/ruby-app ruby app.rb
```

The application will be available at http://localhost:4567

## Architecture

The application consists of:
- Ruby web server
- Redis instance for storing visit counts

## License

This project is licensed under the MIT License - see the LICENSE file for details.