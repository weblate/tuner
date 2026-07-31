<!--
Copyright © 2026 <https://github.com/technosf>
SPDX-FileCopyrightText: © 2026 <https://github.com/technosf>

SPDX-License-Identifier: GPL-3.0-or-later
-->

# Tuner Release Process

## Local Build

Building Tuner locally is described in the [development doc](DEVELOP.md).

## Flathub

The flathub packaging for **Tuner** is maintained in its own github repo:
<https://github.com/tuner-labs/tuner-flathub> on branch *io.github.tuner_labs.tuner*

### Desktop Menu

The desktop file must be validated using this command:

```bash
desktop-file-validate io.github.tuner_labs.tuner.desktop
```

### metainfo

The metainfo.xml must be validated using this command:

```bash
flatpak run org.freedesktop.appstream-glib validate [path-to-xml]

```

### Test different languages

```bash
LANGUAGE=de_DE ./io.github.tuner_labs.tuner
```

## Flatpak

Releasing *Tuner* comprises cutting a release of the code in [tuner github](https://github.com/tuner-app/tuner) and then updating the [flathub repo](https://github.com/flathub/io.github.tuner_labs.tuner) which will automatically have the flatpak generated and rolled to Flathub for distribution.

## Flathub Builds

**flathub** builds can be monitored at <https://flathub.org/en/builds>

### Beta Releases

Beta releases should be tagged from [github](https://github.com/tuner-labs/tuner/releases/new) using the Tuner *development* branch - the *meson* buildfile should have the same version number - the beta format is *v2\*.\*-beta.\**

Once a beta release has been tagged, the Flathub *beta* branch can be updated via a pull request with the *beta* tag going into the manifest *.json*, and any patches and documentation updated as needed. The pull request will trigger a flathub build, but will not merge the pull request - pull requests should be merged only if they result in a successful build.

Once the beta is successfully built by flathub it will be available for installation and testing within the user community.

Once a beta roll is deemed a success its pull request can be merged, and a production release can be rolled.

### Production Releases

Production releases are generated from *development* pull requests into *main*. The updated *main* branch should be tagged with a version number format of *v2.\*.\**

Once a release has been tagged, the [flathub repo](https://github.com/flathub/io.github.tuner_labs.tuner) *main* branch can be updated with the *release* tag going into the manifest *.json*, and any patches and documentation updated as needed. Updates from the *main* branch should be copied in from a direct *pull request* of the *main* branch. The *main* branch **should not** come from a merge *beta* branch to avoid triggering subsequent builds in *beta*.

Once the main production release is built by flathub it will be available for installation and automatically distributed to user community.

The flathub build manifest can be found here:
<https://github.com/louis77/flathub/tree/io.github.tuner_labs.tuner>

### Dev Tricks

#### See Debug Log

<https://docs.elementary.io/develop/writing-apps/logging>

```bash
G_MESSAGES_DEBUG=all ./io.github.tuner_labs.tuner
```

### Manually compile schemas

```bash
sudo /usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas/
```

### Release Checklist

- [ ] Create Release Tag in metainfo
