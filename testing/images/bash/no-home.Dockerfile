FROM jonrad/profilerate-bash:v1

RUN adduser -u 1000 -D -H no-home

USER no-home

ENTRYPOINT [ "tini", "--" ]
CMD [ "sleep", "infinity" ]
