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

[DBus (name = "org.bluez.Device1")]
public interface BluetoothIndicator.Services.Device : Object {
    public abstract void cancel_pairing () throws Error;
    public abstract async void connect () throws Error;
    public abstract void connect_profile (string UUID) throws Error; //vala-lint=naming-convention
    public abstract async void disconnect () throws Error;
    public abstract void disconnect_profile (string UUID) throws Error; //vala-lint=naming-convention
    public abstract void pair () throws Error;

    public abstract string[] UUIDs { owned get; }
    public abstract bool blocked { get; set; }
    public abstract bool connected { get; }
    public abstract bool legacy_pairing { get; }
    public abstract bool paired { get; }
    public abstract bool trusted { get; set; }
    public abstract int16 RSSI { get; }
    public abstract ObjectPath adapter { owned get; }
    public abstract string address { owned get; }
    public abstract string alias { owned get; set; }
    public abstract string icon { owned get; }
    public abstract string modalias { owned get; }
    public abstract string name { owned get; }
    public abstract uint16 appearance { get; }
    public abstract uint32 @class { get; }
}
