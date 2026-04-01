/*
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Gtk;

namespace Tuner.Widgets.Base
{
    /**
    * @class StationListBoxHeader
    * @brief Header widget for StationListBox.
    */
    public class StationListBoxHeader : Gtk.Box
    {
        public Button tooltip_button { get; private set; }

        public signal void action_activated ();

        private StackLabel _parameter_label;

        public StationListBoxHeader(string subtitle, string? action_tooltip_text, string? action_icon_name)
        {
            Object (
                orientation: Orientation.HORIZONTAL,
                spacing: 0
            );
            homogeneous = false;

            pack_start (new StackLabel (subtitle, 20, 20 ), false, false);

            tooltip_button = new Button ();
            if (action_icon_name != null && action_tooltip_text != null) {
                tooltip_button = new Button.from_icon_name (
                    action_icon_name,
                    IconSize.LARGE_TOOLBAR
                );
                tooltip_button.valign = Align.CENTER;
                tooltip_button.tooltip_text = action_tooltip_text;
                tooltip_button.clicked.connect (() => { action_activated (); });
                pack_start (tooltip_button, false, false);
            }

            _parameter_label = new StackLabel("", 20, 20);
            pack_start (_parameter_label, false, false);
        }

        public void set_parameter (string? parameter)
        {
            _parameter_label.label = parameter ?? "";
        }
    } // StationListBoxHeader
} // Tuner
