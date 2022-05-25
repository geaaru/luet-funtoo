FROM alpine
RUN mkdir /funtoo-minimal/etc/ -p
FROM macaronios/luet:latest-amd64
ADD conf/luet.yaml.docker /etc/luet/luet.yaml

#COPY luet /usr/bin/luet
#ADD https://raw.githubusercontent.com/geaaru/luet-specs/master/contrib/geaaru.yml /etc/luet/repos.conf.d/

COPY --from=0 /funtoo-minimal/ /
ENV USER=root

SHELL ["/usr/bin/luet", "install", "-y", "--force", "--sync-repos", "--relax"]
RUN repository/mottainai-stable
RUN repository/macaroni-commons
RUN repository/macaroni-funtoo-systemd

RUN system/entities

SHELL ["/usr/bin/luet", "install", "-y", "--relax", "--force"]

RUN system/luet-geaaru
RUN sys-apps/shadow
RUN sys-apps/sed
RUN app-shells/bash
RUN sys-devel-9.2.0/gcc

RUN sys-libs/ncurses
RUN sys-apps/systemd
RUN sys-apps/coreutils
RUN sys-apps/iproute2

RUN virtual/base
RUN virtual-entities/base

SHELL ["/bin/bash", "-c"]

RUN luet cleanup --purge-repos

ENV TMPDIR=/tmp
ENTRYPOINT ["/bin/bash"]
