FROM ruby:3.2-slim

WORKDIR /usr/src/app

COPY app.rb .

EXPOSE 4567

CMD ["ruby", "app.rb"]
