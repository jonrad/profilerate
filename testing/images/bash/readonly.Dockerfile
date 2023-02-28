FROM jonrad/profilerate-bash:v1

RUN adduser -u 1000 -D -H readonly
RUN chmod 700 /tmp

USER readonly

ENTRYPOINT [ "tini", "--" ]
CMD [ "sleep", "infinity" ]
