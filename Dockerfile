FROM ruby:3.2-slim

WORKDIR /usr/src/app

# Install system dependencies for building gems
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    libyaml-dev \
    libreadline-dev \
    zlib1g-dev \
    libsqlite3-dev \
    sqlite3 \
    libxml2-dev \
    libxslt1-dev \
    nodejs \
    tzdata && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY Gemfile ./

RUN bundle install

COPY . .

EXPOSE 4567

CMD ["ruby", "app.rb", "-o", "0.0.0.0", "-p", "4567"]
