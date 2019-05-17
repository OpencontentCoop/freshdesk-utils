FROM alpine

RUN RUN apk add --no-cache bash jq httpie

RUN http get https://github.com/coursehero/slacktee/raw/master/slacktee.sh > /usr/local/bin/slacktee \
    && chmod +x /usr/local/bin/slacktee

ADD slacktee.conf ~/.slacktee

ADD *.sh /usr/local/bin

RUN [ "close-older-resolved-tickets.sh" ] 
