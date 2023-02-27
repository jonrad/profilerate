FROM bash:5.2.15

# SSH SERVER with no password required
# Don't ever do this
RUN mkdir -p /root/.ssh \
    && chmod 0700 /root/.ssh \
    && apk add openrc openssh \
    && mkdir -p /run/openrc \
    && touch /run/openrc/softlevel \
    && echo -e "PermitRootLogin yes" >> /etc/ssh/sshd_config \
    && echo -e "PermitEmptyPasswords yes" >> /etc/ssh/sshd_config \
    && echo -e "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config \
    && passwd -d root

RUN apk add tini rsync

RUN echo "export ETC_PROFILE=1" >> /etc/profile
RUN echo "export HOME_BASH_PROFILE=1" >> /root/.bash_profile

RUN apk add neovim

ENTRYPOINT [ "tini", "--", "sh", "-c", "rc-status; rc-service sshd start; sleep infinity" ]
