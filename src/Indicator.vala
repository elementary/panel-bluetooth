/*-
 * Copyright (c) 2015-2023 elementary LLC. (https://elementary.io)
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

public class BluetoothIndicator.Indicator : Wingpanel.Indicator {
    public bool is_in_session { get; construct; default = false; }

    private Widgets.PopoverWidget popover_widget;
    private Widgets.DisplayWidget dynamic_icon;
    private Services.ObjectManager object_manager;
    private Services.ObexManager obex_manager;

    public Indicator (bool is_in_session) {
        Object (
            code_name: Wingpanel.Indicator.BLUETOOTH,
            is_in_session: is_in_session
        );
    }

    construct {
        GLib.Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");

        object_manager = new BluetoothIndicator.Services.ObjectManager ();
        object_manager.bind_property ("has-object", this, "visible", GLib.BindingFlags.SYNC_CREATE);
        obex_manager = new BluetoothIndicator.Services.ObexManager ();
        if (object_manager.has_object) {
            object_manager.set_state_from_settings.begin ();
        }

        object_manager.notify["has-object"].connect (() => {
            if (object_manager.has_object) {
                object_manager.set_state_from_settings.begin ();
            }
        });
    }

    public override Gtk.Widget get_display_widget () {
        if (dynamic_icon == null) {
            dynamic_icon = new Widgets.DisplayWidget (object_manager);
        }

        return dynamic_icon;
    }

    public override Gtk.Widget? get_widget () {
        if (popover_widget == null) {
            popover_widget = new Widgets.PopoverWidget (object_manager, obex_manager, is_in_session);
        }

        return popover_widget;
    }


    public override void opened () {
    }

    public override void closed () {
    }
}

public Wingpanel.Indicator get_indicator (Module module, Wingpanel.ServerType server_type) {
    debug ("Activating Bluetooth Indicator");
    var indicator = new BluetoothIndicator.Indicator (server_type == Wingpanel.ServerType.SESSION);

    return indicator;
}
