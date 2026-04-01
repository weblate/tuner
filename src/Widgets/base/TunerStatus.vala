/**
 * SPDX-FileCopyrightText: Copyright © 2026technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file TunerStatus.vala
 *
 * @brief TunerStatus widget
 *
 */


using Gtk;
using Tuner.Controllers;
using Tuner.Models;
using Tuner.Services;

/** 
 * TunerStatus widget for displaying tuner on-line status and data provider information.
 */
public class Tuner.Widgets.Base.TunerStatus : Fixed
{
    private Overlay _tuner_icon = new Overlay();
	private Image _tuner_on     = new Image.from_icon_name("tuner:tuner-on", IconSize.DIALOG);

    public TunerStatus(Application app, Window window, DataProvider.API provider) 
    {
            // Tuner icon
        _tuner_icon.add(new Image.from_icon_name("tuner:tuner-off", IconSize.DIALOG));
        _tuner_icon.add_overlay(_tuner_on);
        _tuner_icon.valign = Align.START;

		add(_tuner_icon);
		set_valign(Align.CENTER);
		set_margin_bottom(5);   // 20px padding on the right
		set_margin_start(5);   // 20px padding on the right
		set_margin_end(5);   // 20px padding on the right
		tooltip_text = _("Data Provider");
		query_tooltip.connect((x, y, keyboard_tooltip, tooltip) =>
		{
			
				if (app.is_offline)
					return false;
				string provider_text = _("Data Provider") + ": %s\n\n%u " + _("Stations") + ",\t%u " + _("Tags");
				tooltip.set_text (provider_text.printf (window.directory.provider (),
				provider.available_stations (),
				provider.available_tags ()
				));

			return true;
		});
    } // construct


    /**
     * Sets the online status of the tuner.
     * @param show_online Whether the tuner is online.
     */
    public bool online 
    {
        set {
            _tuner_on.opacity = value ? 1.0 : 0.0;
        }
    } // online


} // TunerStatus