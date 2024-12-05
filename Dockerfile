FROM ruby:3.2-slim

WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN gem install sinatra redis rackup puma webrick

COPY app.rb .

EXPOSE 4567

CMD ["ruby", "app.rb", "-o", "0.0.0.0", "-p", "4567"]
