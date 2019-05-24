FROM alpine

RUN apk add --no-cache bash jq httpie coreutils curl

RUN http get https://raw.githubusercontent.com/coursehero/slacktee/master/slacktee.sh > /usr/local/bin/slacktee \
    && chmod +x /usr/local/bin/slacktee

RUN adduser -h /home/marvin -G users -D marvin

COPY slacktee.conf /home/marvin/.slacktee
RUN chown marvin.users /home/marvin/.slacktee


COPY close-older-resolved-tickets.sh /usr/bin/close-older-resolved-tickets

WORKDIR /home/marvin
USER marvin 

CMD [ 'close-older-resolved-tickets' ] 
