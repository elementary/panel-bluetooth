/*
* SPDX-License-Identifier: LGPL-2.1-or-later
* SPDX-FileCopyrightText: 2015-2025 elementary, Inc. (https://elementary.io)
*/

public class BluetoothIndicator.Widgets.PopoverWidget : Gtk.Box {
    public signal void device_requested (BluetoothIndicator.Services.Device device);
    public signal void discovery_requested ();

    public BluetoothIndicator.Services.ObjectManager object_manager { get; construct; }
    public BluetoothIndicator.Services.ObexManager obex_manager { get; construct; }
    public bool is_in_session { get; construct; }

    private Granite.SwitchModelButton main_switch;
    private Gtk.ListBox devices_list;
    private Gtk.Revealer revealer;

    public PopoverWidget (
        BluetoothIndicator.Services.ObjectManager object_manager,
        BluetoothIndicator.Services.ObexManager obex_manager, bool is_in_session
    ) {
        Object (
            object_manager: object_manager,
            obex_manager: obex_manager,
            is_in_session: is_in_session
        );
    }

    construct {
        orientation = VERTICAL;

        main_switch = new Granite.SwitchModelButton (_("Bluetooth"));
        main_switch.add_css_class (Granite.STYLE_CLASS_H4_LABEL);

        devices_list = new Gtk.ListBox ();
        devices_list.set_sort_func ((Gtk.ListBoxSortFunc) compare_rows);

        var scroll_box = new Gtk.ScrolledWindow () {
            child = devices_list,
            hscrollbar_policy = NEVER,
            max_content_height = 512,
            propagate_natural_height = true
        };

        var revealer_content_separator = new Gtk.Separator (HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        };

        var revealer_content = new Gtk.Box (VERTICAL, 0);
        revealer_content.append (revealer_content_separator);
        revealer_content.append (scroll_box);

        revealer = new Gtk.Revealer () {
            child = revealer_content
        };

        var show_settings_button = new Wingpanel.PopoverMenuItem () {
            text = _("Bluetooth Settings…")
        };

        append (main_switch);
        append (revealer);
        if (is_in_session) {
            var settings_button_separator = new Gtk.Separator (HORIZONTAL) {
                margin_top = 3,
                margin_bottom = 3
            };

            append (settings_button_separator);
            append (show_settings_button);
        }

        update_ui_state (object_manager.get_global_state ());

        devices_list.row_activated.connect ((row) => {
            ((Widgets.Device) row).toggle_device.begin ();
        });

        object_manager.settings.bind ("enabled", main_switch, "active", DEFAULT);

        show_settings_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("settings://network/bluetooth", null);
            } catch (Error e) {
                warning ("Failed to open bluetooth settings: %s", e.message);
            }
        });

        object_manager.global_state_changed.connect ((state, paired) => {
            update_ui_state (state);
        });

        object_manager.device_added.connect ((device) => {
            // Remove existing rows for this device which are no longer connected to device
            remove_device (device);

            // Add the new device so that it's status is correctly updated
            add_device (device);
        });

        object_manager.device_removed.connect ((device) => {
            remove_device (device);

            update_devices_box_visible ();
        });

        if (object_manager.has_object && object_manager.retrieve_finished) {
            foreach (var device in object_manager.get_devices ()) {
                add_device (device);
            }
        }

        update_devices_box_visible ();
    }

    [CCode (instance_pos = -1)]
    private int compare_rows (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        unowned Services.Device device1 = ((Widgets.Device) row1).device;
        unowned Services.Device device2 = ((Widgets.Device) row2).device;

        if (device1.name != null && device2.name == null) {
            return -1;
        }

        if (device1.name == null && device2.name != null) {
            return 1;
        }

        var name1 = device1.name ?? device1.address;
        var name2 = device2.name ?? device2.address;
        return name1.collate (name2);
    }

    private void update_ui_state (bool state) {
        if (main_switch.active != state) {
            main_switch.active = state;
        }

        devices_list.invalidate_sort ();
        update_devices_box_visible ();
    }

    private void update_devices_box_visible () {
        if (devices_list.get_row_at_index (0) != null) {
            revealer.reveal_child = main_switch.active;
        } else {
            revealer.reveal_child = false;
        }
    }

    private void add_device (BluetoothIndicator.Services.Device device) {
        var device_widget = new Widgets.Device (device, obex_manager);
        devices_list.append (device_widget);

        update_devices_box_visible ();

        device_widget.show_device.connect ((device_service) => {
            device_requested (device_service);
        });
    }

    private void remove_device (BluetoothIndicator.Services.Device device) {
        for (int i = 0; devices_list.get_row_at_index (i) != null; i++) {
            var device_child = (Widgets.Device) devices_list.get_row_at_index (i);
            if (device_child != null && device_child.device.address == device.address) {
                devices_list.remove (device_child);
                return;
            }
        }
    }
}
