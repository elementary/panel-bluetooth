/*-
 * Copyright (c) 2015-2018 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class BluetoothIndicator.Services.ObjectManager : Object {
    public signal void global_state_changed (bool enabled, bool connected);
    public signal void device_added (BluetoothIndicator.Services.Device adapter);
    public signal void device_removed (BluetoothIndicator.Services.Device adapter);

    public bool has_object { get; private set; default = false; }
    public bool retrieve_finished { get; private set; default = false; }
    public Settings settings { get; construct; }
    private GLib.DBusObjectManagerClient object_manager;
    public bool is_powered {get; private set; default = false; }
    public bool is_connected {get; private set; default = false; }

    construct {
        settings = new Settings ("io.elementary.desktop.bluetooth");
        create_manager.begin ();
    }

    private async void create_manager () {
        try {
            object_manager = yield new GLib.DBusObjectManagerClient.for_bus.begin (
                BusType.SYSTEM,
                GLib.DBusObjectManagerClientFlags.NONE,
                "org.bluez",
                "/",
                object_manager_proxy_get_type,
                null
            );
            object_manager.get_objects ().foreach ((object) => {
                object.get_interfaces ().foreach ((iface) => on_interface_added (object, iface));
            });
            object_manager.interface_added.connect (on_interface_added);
            object_manager.interface_removed.connect (on_interface_removed);
            object_manager.object_added.connect ((object) => {
                object.get_interfaces ().foreach ((iface) => on_interface_added (object, iface));
            });
            object_manager.object_removed.connect ((object) => {
                object.get_interfaces ().foreach ((iface) => on_interface_removed (object, iface));
            });
        } catch (Error e) {
            critical (e.message);
        }

        retrieve_finished = true;
    }

    //TODO: Do not rely on this when it is possible to do it natively in Vala
    [CCode (cname="bluetooth_indicator_services_device_proxy_get_type")]
    extern static GLib.Type get_device_proxy_type ();

    [CCode (cname="bluetooth_indicator_services_adapter_proxy_get_type")]
    extern static GLib.Type get_adapter_proxy_type ();

    private GLib.Type object_manager_proxy_get_type (DBusObjectManagerClient manager, string object_path, string? interface_name) {
        if (interface_name == null)
            return typeof (GLib.DBusObjectProxy);

        switch (interface_name) {
            case "org.bluez.Device1":
                return get_device_proxy_type ();
            case "org.bluez.Adapter1":
                return get_adapter_proxy_type ();
            default:
                return typeof (GLib.DBusProxy);
        }
    }

    private void on_interface_added (GLib.DBusObject object, GLib.DBusInterface iface) {
        if (iface is BluetoothIndicator.Services.Device) {
            unowned BluetoothIndicator.Services.Device device = (BluetoothIndicator.Services.Device) iface;

            if (device.paired) {
                device_added (device);
            }

            ((DBusProxy) device).g_properties_changed.connect ((changed, invalid) => {
                var connected = changed.lookup_value ("Connected", new VariantType ("b"));
                var paired = changed.lookup_value ("Paired", new VariantType ("b"));
                if (paired != null) {
                    if (device.paired) {
                        device_added (device);
                    } else {
                        device_removed (device);
                    }
                }

                if (connected != null || paired != null) {
                    check_global_state ();
                }
            });

            check_global_state ();
        } else if (iface is BluetoothIndicator.Services.Adapter) {
            unowned BluetoothIndicator.Services.Adapter adapter = (BluetoothIndicator.Services.Adapter) iface;
            has_object = true;

            ((DBusProxy) adapter).g_properties_changed.connect ((changed, invalid) => {
                var powered = changed.lookup_value ("Powered", new VariantType ("b"));
                if (powered != null) {
                    check_global_state ();
                }
            });

            check_global_state ();
        }
    }

    private void on_interface_removed (GLib.DBusObject object, GLib.DBusInterface iface) {
        if (iface is BluetoothIndicator.Services.Device) {
            device_removed ((BluetoothIndicator.Services.Device) iface);
        } else if (iface is BluetoothIndicator.Services.Adapter) {
            has_object = !get_adapters ().is_empty;
        }

        check_global_state ();
    }

    public Gee.LinkedList<BluetoothIndicator.Services.Adapter> get_adapters () {
        var adapters = new Gee.LinkedList<BluetoothIndicator.Services.Adapter> ();
        object_manager.get_objects ().foreach ((object) => {
            GLib.DBusInterface? iface = object.get_interface ("org.bluez.Adapter1");
            if (iface == null)
                return;

            adapters.add (((BluetoothIndicator.Services.Adapter) iface));
        });

        return (owned) adapters;
    }

    public Gee.Collection<BluetoothIndicator.Services.Device> get_devices () {
        var devices = new Gee.LinkedList<BluetoothIndicator.Services.Device> ();
        object_manager.get_objects ().foreach ((object) => {
            GLib.DBusInterface? iface = object.get_interface ("org.bluez.Device1");
            if (iface == null)
                return;

            devices.add (((BluetoothIndicator.Services.Device) iface));
        });

        return (owned) devices;
    }

    private void check_global_state () {
        var powered = get_global_state ();
        var connected = get_connected ();

        /* Only signal if actually changed */
        if (powered != is_powered || connected != is_connected) {
            if (powered != is_powered) {
                is_powered = powered;
            }

            if (connected != is_connected) {
                is_connected = connected;
            }

            global_state_changed (is_powered, is_connected);
        }
    }

    public bool get_connected () {
        var devices = get_devices ();
        foreach (var device in devices) {
            if (device.connected) {
                return true;
            }
        }

        return false;
    }

    public bool get_global_state () {
        var adapters = get_adapters ();
        foreach (var adapter in adapters) {
            if (adapter.powered) {
                return true;
            }
        }

        return false;
    }

    private async void set_global_state (bool state) {
        /* `is_powered` and `connected` properties will be set by the check_global state () callback when adapter or device
         * properties change.  Do not set now so that global_state_changed signal will be emitted. */
        var adapters = get_adapters ();
        foreach (var adapter in adapters) {
            adapter.powered = state;
        }

        if (state == false) {
            var devices = get_devices ();
            foreach (var device in devices) {
                if (device.connected) {
                    try {
                        yield device.disconnect ();
                    } catch (Error e) {
                        critical (e.message);
                    }
                }
            }
        }

        check_global_state ();

    }

    public async void set_state_from_settings () {
        yield set_global_state (settings.get_boolean ("enabled"));
    }

    public static bool compare_devices (Device device, Device other) {
        return device.modalias == other.modalias;
    }
}
