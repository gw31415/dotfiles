FROM ama-home-manager-pure:latest

COPY ./impure.sh /tmp/impure.sh
RUN  --mount=type=bind,source=./impure.sh,target=/tmp/impure.sh /tmp/impure.sh || true

CMD [ "/root/.nix-profile/bin/fish", "-l" ]
