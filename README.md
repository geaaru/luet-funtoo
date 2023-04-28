<p align="center">
  <img src="https://github.com/macaroni-os/macaroni-site/blob/master/site/static/images/logo.png">
</p>

# macaroni-funtoo
Funtoo Macaroni Repository Tree

Branches behavior:
* `master`: single packages tree based on 1.4-prime release.

* `terragon`: related to the `next` release of Funtoo but
  oriented to Container and with openRC.

* `systemd`: related to a not funtoo supported release with SystemD.
  The idea is to use it only for Server ISO release and as experimental
  base rootfs where we will develop an alternative tool that will
  replace SystemD probably written in Golang. Stay tuned!.


## Generate packages with `luet-portage-converter`

To generate specs for all packages defined on rules and their dependencies (runtime and buildtime):
```bash
$> luet-portage-converter generate -t ./packages/  --to . --rules portage-converter/office.yaml --ignore-missing-deps  --with-portage-pkg   --enable-stage4 --disable-conflicts
```

To generate specs for a specific package defined on rules and their dependencies (runtime and buildtime):

```bash
$> luet-portage-converter generate -t ./packages/  --to . --rules portage-converter/office.yaml --ignore-missing-deps  --with-portage-pkg   --enable-stage4 --disable-conflicts --pkg app/foo
```

NOTE: The `kit_cache` directory is generated by the `lxd-compose` command:

```
$> lxd-compose c r metatools-services reposcan-funtoo-kits
```

## Create lxd-compose command spec file to create reposcan files

To create the `lxd-compose` command to generate
the current reposcan files of all kits defined to
a specific git hash you can use:

```bash
$> # Export the right path where is cloned lxd-compose-galaxy
   # project
$> export LCG_KITS_FILE=$HOME/dev/mottainai/lxd-compose-galaxy/envs/funtoo/commands/reposcan-funtoo-kits.yml

$> sh scripts/lxd-compose-galaxy-kits-bump-command.sh
```

The script called generate the file `/tmp/reposcan.yml` that
could be saved in a differetn path with the override of the
variable `LCG_CMD_FILE`.

To generate reposcan files, then:

```bash
$> cd lxd-compose-galaxy
$> lxd-compose c r --command-file /tmp/reposcan.yml metatools-services reposcan-funtoo-kits
$> # Now under the directory kit_cache you can find the files to use with luet-portage-converter

```

**NOTE**: The `core-kit` must be the first kit of the list in the file /etc/reposcan.yml.
If it isn't so, fix it before run lxd-compose.


### Create repoman files of additional overlay

After the execution of `lxd-compose-galaxy-kits-bump-command.sh` in the generated file could
be added the additional kit to elaborate to the same level of the others kits.

For example:
```yaml
      - name: brother-overlay
        url: https://github.com/stefan-langenmaier/brother-overlay.git
        branch: master
        kind: independent
        commit_sha1: b216154a0197486ec867d92bedf48aec7f958c9d
```

After this you can follow the same commmand of the `lxd-compose` tool and get the repoman file of the
overlay added.

### Download stable/dev reposcan files from Macaroni CDN

Download Funtoo Kits reposcan files of the stable tree:

```shell
$> sh scripts/download-reposcan-files.sh
```

For develop tree JSONs:

```shell
$> STABLE=0 sh scripts/download-reposcan-files.sh
```

Download Extra kits reposcan files:

```shell
$> sh scripts/download-reposcan-extra-files.sh
```

All files are stored under the ./kit_cache directory.
