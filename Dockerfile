FROM ruby:onbuild

RUN apt-get update && apt-get install -y nodejs

CMD rails s -b 0.0.0.0 -p 3000 Puma
