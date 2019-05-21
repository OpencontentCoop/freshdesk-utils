FROM alpine

RUN apk add --no-cache bash jq httpie coreutils curl

RUN http get https://raw.githubusercontent.com/coursehero/slacktee/master/slacktee.sh > /usr/local/bin/slacktee \
    && chmod +x /usr/local/bin/slacktee

COPY slacktee.conf ~/.slacktee

COPY close-older-resolved-tickets.sh /usr/bin/close-older-resolved-tickets

CMD [ 'close-older-resolved-tickets' ] 
