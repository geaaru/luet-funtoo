FROM alpine
RUN mkdir /funtoo-minimal/etc/ -p && \
      touch /funtoo-minimal/etc/passwd && \
      touch /funtoo-minimal/etc/shadow && \
      touch /funtoo-minimal/etc/group && \
      touch /funtoo-minimal/etc/gshadow

FROM macaronios/luet:latest
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
RUN pkglist/funtoo-base

SHELL ["entities", "merge", "-a", "-s"]
RUN /usr/share/macaroni/layers/funtoo-base/entities/

SHELL ["/usr/bin/luet", "install", "-y", "--relax", "--force"]

RUN system/luet-geaaru
RUN sys-libs/ncurses
RUN sys-apps/systemd
RUN sys-apps/sed
RUN sys-apps/coreutils
RUN sys-apps/iproute2
RUN virtual/base

SHELL ["/bin/bash", "-c"]

RUN luet uninstall -y pkglist/funtoo-base && \
  luet cleanup --purge-repos

ENV TMPDIR=/tmp
ENTRYPOINT ["/bin/bash"]
