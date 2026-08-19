/*
* SPDX-License-Identifier: LGPL-2.1-or-later
* SPDX-FileCopyrightText: 2015-2025 elementary, Inc. (https://elementary.io)
*/

public class BluetoothIndicator.Widgets.DisplayWidget : Granite.Bin {
    public BluetoothIndicator.Services.ObjectManager object_manager { get; construct; }

    private Granite.Symbol symbol;

    public DisplayWidget (BluetoothIndicator.Services.ObjectManager object_manager) {
        Object (object_manager: object_manager);
    }

    construct {
        symbol = new Granite.Symbol ("/io/elementary/wingpanel/bluetooth/icons/bluetooth.svg") {
            pixel_size = 24
        };

        child = symbol;

        object_manager.global_state_changed.connect ((state, connected) => {
            set_icon ();
        });

        if (object_manager.has_object && object_manager.retrieve_finished) {
            set_icon ();
        } else {
            object_manager.notify["retrieve-finished"].connect (set_icon);
        }

        var gesture_click = new Gtk.GestureClick () {
            button = Gdk.BUTTON_MIDDLE
        };
        gesture_click.pressed.connect (() => {
            object_manager.settings.set_boolean (
                "enabled",
                !object_manager.settings.get_boolean ("enabled")
            );
        });

        add_controller (gesture_click);
    }

    private void set_icon () {
        if (get_realized ()) {
            update_icon ();
        } else {
            /* When called from constructor usually not realized */
            realize.connect_after (update_icon);
        }
    }

    private void update_icon () {
        var state = object_manager.is_powered;
        var connected = object_manager.is_connected;
        string description;
        string context;

        if (state) {
            context = _("Middle-click to turn Bluetooth off");
            if (connected) {
                symbol.state = Granite.Symbol.State.CHECKED;
                description = _("Bluetooth connected");
            } else {
                symbol.state = Granite.Symbol.State.NORMAL;
                description = _("Bluetooth is on");
            }
        } else {
            symbol.state = Granite.Symbol.State.DISABLED;
            description = _("Bluetooth is off");
            context = _("Middle-click to turn Bluetooth on");
        }

        tooltip_markup = "%s\n%s".printf (
            description, Granite.TOOLTIP_SECONDARY_TEXT_MARKUP.printf (context)
        );
    }
}
