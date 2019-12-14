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

public class BluetoothIndicator.Widgets.Device : Gtk.ListBoxRow {
    private const string DEFAULT_ICON = "bluetooth";
    public signal void show_device (BluetoothIndicator.Services.Device device);

    public BluetoothIndicator.Services.Device device { get; construct; }
    private Gtk.Label status_label;
    private Gtk.Label name_label;
    private Gtk.Image icon_image;
    private Gtk.Image status_image;
    private Gtk.Spinner spinner;

    public Device (BluetoothIndicator.Services.Device device) {
        Object (device: device);
    }

    construct {
        name_label = new Gtk.Label ("<b>%s</b>".printf (Markup.escape_text (device.name)));
        name_label.halign = Gtk.Align.START;
        name_label.valign = Gtk.Align.END;
        name_label.vexpand = true;
        name_label.use_markup = true;

        status_label = new Gtk.Label (_("Not Connected"));
        status_label.halign = Gtk.Align.START;
        status_label.valign = Gtk.Align.START;
        status_label.vexpand = true;

        spinner = new Gtk.Spinner ();
        spinner.halign = Gtk.Align.START;
        spinner.valign = Gtk.Align.START;
        spinner.hexpand = true;

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.VERTICAL);
        size_group.add_widget (status_label);
        size_group.add_widget (spinner);

        icon_image = new Gtk.Image.from_icon_name (device.icon == null ? DEFAULT_ICON : device.icon, Gtk.IconSize.DIALOG);

        status_image = new Gtk.Image.from_icon_name ("user-offline", Gtk.IconSize.MENU);
        status_image.halign = Gtk.Align.END;
        status_image.valign = Gtk.Align.END;

        var overlay = new Gtk.Overlay ();
        overlay.add (icon_image);
        overlay.add_overlay (status_image);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.margin_end = 6;
        grid.attach (overlay, 0, 0, 1, 2);
        grid.attach (name_label, 1, 0, 2, 1);
        grid.attach (status_label, 1, 1, 1, 1);
        grid.attach (spinner, 2, 1, 1, 1);

        add (grid);

        (device as DBusProxy).g_properties_changed.connect (update_status);

        update_status ();

        get_style_context ().add_class (Gtk.STYLE_CLASS_MENUITEM);
        selectable = false;
    }

    public async void toggle_device () {
        if (spinner.active) {
            return;
        }

        spinner.active = true;
        status_image.icon_name = "user-away";
        try {
            if (!device.connected) {
                status_label.label = _("Connecting…");
                yield device.connect ();
            } else {
                status_label.label = _("Disconnecting…");
                yield device.disconnect ();
            }
        } catch (Error e) {
            critical (e.message);
            status_label.label = _("Unable to Connect");
            status_image.icon_name = "user-busy";
        }

        spinner.active = false;
    }

    private void update_status () {
        name_label.label = "<b>%s</b>".printf (Markup.escape_text (device.name));

        if (device.connected) {
            status_label.label = _("Connected");
            status_image.icon_name = "user-available";
        } else {
            status_label.label = _("Not Connected");
            status_image.icon_name = "user-offline";
        }

        icon_image.icon_name = device.icon == null ? DEFAULT_ICON : device.icon;
    }
}
