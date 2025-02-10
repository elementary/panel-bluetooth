# Wingpanel Bluetooth Indicator
[![Packaging status](https://repology.org/badge/tiny-repos/wingpanel-indicator-bluetooth.svg)](https://repology.org/metapackage/wingpanel-indicator-bluetooth)
[![Translation status](https://l10n.elementary.io/widgets/wingpanel/-/wingpanel-indicator-bluetooth/svg-badge.svg)](https://l10n.elementary.io/engage/wingpanel/?utm_source=widget)

![Screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

    gobject-introspection
    libglib2.0-dev
    libgranite-dev >= 6.0.0
    libwingpanel-dev
    meson
    valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install
