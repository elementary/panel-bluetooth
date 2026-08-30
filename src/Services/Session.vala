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

[DBus (name = "org.bluez.obex.Session1")]
public interface BluetoothIndicator.Services.Obex.Session : Object {
    public abstract string get_capabilities () throws GLib.Error;
    public abstract string source { owned get; }
    public abstract string destination { owned get; }
    public abstract uchar channel { get; }
    public abstract string target { owned get; }
    public abstract string root { owned get; }
}
