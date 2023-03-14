FROM alpine
RUN mkdir /funtoo-minimal/etc/ -p
FROM macaronios/luet:latest-amd64
ADD conf/luet.yaml.docker /etc/luet/luet.yaml

#COPY luet /usr/bin/luet
#ADD https://raw.githubusercontent.com/geaaru/luet-specs/master/contrib/geaaru.yml /etc/luet/repos.conf.d/

COPY --from=0 /funtoo-minimal/ /
ENV USER=root

RUN [ \
  "/usr/bin/luet", "install", "-y", "--force", "--sync-repos", \
  "repository/mottainai-stable", \
  "repository/macaroni-commons", \
  "repository/macaroni-funtoo-systemd"]

RUN [ \
  "/usr/bin/luet", "install", "-y", "--force", "--sync-repos", \
  "--skip-config-protect", \
  "system/entities", \
  "system/luet-geaaru-thin", \
  "sys-apps/shadow", \
  "sys-apps/sed", \
  "app-shells/bash", \
  "sys-devel-9.2.0/gcc", \
  "sys-libs/ncurses", \
  "sys-apps/systemd", \
  "sys-apps/coreutils", \
  "sys-apps/iproute2", \
  "virtual/base", \
  "virtual-entities/base", \
  "app-admin/macaronictl-thin" ]

SHELL ["/bin/bash", "-c"]

RUN macaronictl env-update && \
  luet rm -y --nodeps virtual-entities/base dev-lang-2.7/python && \
  luet cleanup --purge-repos

ENV TMPDIR=/tmp
ENTRYPOINT ["/bin/bash"]
