/**
 * SPDX-FileCopyrightText: Copyright © 2026 <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file ScreenshotMode.vala
 *
 * @brief Development-only controls for taking representative screenshots.
 */

#if DEBUG_LOCAL

using Gee;
using Tuner.Models;
using Tuner.Widgets;

namespace Tuner.Services
{
	/**
	 * @brief Puts a local debug build into a known state for Flathub screenshots.
	 *
	 * Compiled only into local debug builds (DEBUG_LOCAL), so it is not in release
	 * or Flatpak builds. It is switched on by one environment variable:
	 *
	 *     TUNER_SCREENSHOT="size=1000x625;theme=light;view=Discover"
	 *
	 * The value is a list of `key=value` pairs separated by `;`. Keys:
	 *
	 * | key        | value                              | effect |
	 * | :-         | :-                                 | :- |
	 * | size       | `WIDTHxHEIGHT`                     | resize the window (Flathub wants about 1000x625) |
	 * | theme      | `light`, `dark` or `system`        | theme for this run |
	 * | layout     | GTK decoration layout, `:close`    | title-bar buttons; default `:close` leaves only the close button |
	 * | offline    | `1`                                | show the offline look |
	 * | starred    | station uuids, comma separated     | star these stations (use a clean data directory) |
	 * | station    | a station uuid                     | play this station |
	 * | view       | side-bar item name, e.g. `Discover`, `Trending`, `Popular`, `Jukebox`, `Starred by You`, `Latest Search` | select it |
	 * | history    | station uuids, comma separated     | play each of these for `history_dwell` ms before the `station`, so the History list has several tracks |
	 * | history_dwell | milliseconds                  | how long each `history` station plays; default 15000 |
	 * | activate   | side-bar item name, e.g. `Jukebox` | double-click it: for Jukebox this starts shuffle mode and its animated icon |
	 * | activate_wait | milliseconds                    | wait after activating so a station is chosen and plays; default 12000 |
	 * | search     | text                               | open the search bar and search for the text |
	 * | popover    | `history` or `preferences`         | open that popover last |
	 * | delay      | milliseconds                       | wait before the first step; default 1500 |
	 * | popover_delay | milliseconds                  | wait before opening the popover, e.g. to let the history fill up; default 0 |
	 *
	 * Names are matched against the English labels, so run with LANG=C.
	 * scripts/screenshots.sh wraps this: it also uses a throw-away settings store
	 * (GSETTINGS_BACKEND=memory) and a throw-away data directory so that nothing from
	 * the developer's real favourites, history or settings appears, and nothing is saved.
	 */
	public class ScreenshotMode : GLib.Object
	{
		public const string ENV_SPEC = "TUNER_SCREENSHOT";

		private const uint DEFAULT_DELAY_MS = 1500u;
		private const uint STEP_SETTLE_MS = 2500u;     // lists and station info need time to load
		private const string DEFAULT_LAYOUT = ":close";

		private static HashMap<string, string>? _spec = null;


		/**
		 * @brief Whether screenshot mode was requested through the environment.
		 */
		public static bool is_active()
		{
			return spec().size > 0;
		} // is_active


		/**
		 * @brief Applies the settings that must be in place before the window is built.
		 *
		 * Sets the title-bar button layout and theme, and turns off the startup jingle and
		 * auto-play so nothing starts by itself.
		 */
		public static void prepare()
		{
			if (!is_active())
				return;

			if (Environment.get_variable("GSETTINGS_BACKEND") != "memory")
				warning("Screenshot mode without GSETTINGS_BACKEND=memory: changes below are written to your real settings. Use scripts/screenshots.sh");

			var settings = Gtk.Settings.get_default();
			settings.gtk_decoration_layout = get_value("layout", DEFAULT_LAYOUT);

			app().settings.startup_jingle = false;
			app().settings.auto_play = false;

			var theme = get_value("theme", "");
			if (theme == "dark")
				app().theme_name = THEME.DARK.get_name();
			else if (theme == "light")
				app().theme_name = THEME.LIGHT.get_name();
			else if (theme == "system")
				app().theme_name = THEME.SYSTEM.get_name();

			message("Screenshot mode: %s", Environment.get_variable(ENV_SPEC));
		} // prepare


		/**
		 * @brief Runs the requested steps once the window is up.
		 *
		 * Order: size, offline, stars, view, station, search, popover. Each step that
		 * depends on loaded content waits for it to settle first.
		 *
		 * @param window The main window.
		 */
		public static async void apply(Window window)
		{
			if (!is_active())
				return;

			yield pause(get_uint("delay", DEFAULT_DELAY_MS));

			// Size
			var size = get_value("size", "");
			if (size != "")
			{
				var parts = size.split("x");
				if (parts.length == 2)
				{
					window.unmaximize();
					window.resize(int.parse(parts[0]), int.parse(parts[1]));
				}
				else
					warning("Screenshot mode: size must be WIDTHxHEIGHT, got '%s'", size);
			}

			// Offline look
			if (get_value("offline", "") == "1")
			{
				app().debug_set_online(false);
				message("Screenshot mode: offline");
				return;    // nothing else works offline
			}

			yield pause(STEP_SETTLE_MS);   // display initialisation loads the lists

			// Stars
			var starred = get_value("starred", "");
			if (starred != "")
			{
				foreach (var uuid in starred.split(","))
				{
					var station = yield fetch_station(uuid.strip());
					if (station != null)
					{
						station.starred = true;
						app().stars.add_station(station);
					}
				}
			}

			// View
			var view = get_value("view", "");
			if (view != "" && !window.screenshot_select_view(view))
				warning("Screenshot mode: no side-bar item named '%s'", view);

			// Station
			var station_uuid = get_value("station", "");
			if (station_uuid != "")
			{
				var station = yield fetch_station(station_uuid);
				if (station != null)
					window.handle_play_station(station);

				yield pause(STEP_SETTLE_MS);   // title, metadata and artwork arrive after play starts
			}

			// Activate (double-click) an item, e.g. Jukebox, which starts shuffling and picks a station
			var activate = get_value("activate", "");
			if (activate != "")
			{
				// Activating Jukebox picks a random station from radio-browser, which can fail or
				// come back empty: activate again (that shuffles again) until something is playing.
				var wait = get_uint("activate_wait", 12000u);
				for (int attempt = 1; attempt <= 3; attempt++)
				{
					if (!window.screenshot_activate_view(activate))
					{
						warning("Screenshot mode: no side-bar item named '%s' to activate", activate);
						break;
					}

					yield pause(wait);
					if (app().player.player_state == StreamPlayer.State.PLAYING)
						break;

					message("Screenshot mode: nothing playing after activating '%s' (attempt %d)", activate, attempt);
				}
			}

			// History: play a few stations in turn so the History list has several entries.
			// Stations are played in order; the one given as `station` is played again last.
			var history = get_value("history", "");
			if (history != "")
			{
				var dwell = get_uint("history_dwell", 15000u);
				foreach (var uuid in history.split(","))
				{
					var past = yield fetch_station(uuid.strip());
					if (past != null)
					{
						window.handle_play_station(past);
						yield pause(dwell);
					}
				}

				if (station_uuid != "")
				{
					var last = yield fetch_station(station_uuid);
					if (last != null)
						window.handle_play_station(last);
					yield pause(STEP_SETTLE_MS);
				}
			}

			// Search
			var search = get_value("search", "");
			if (search != "")
			{
				var titlebar = window.get_titlebar();
				var button = titlebar != null ? find_by_tooltip(titlebar, _("Search for Stations")) as Gtk.Button : null;
				if (button != null)
					button.clicked();

				yield pause(500);

				var entry = titlebar != null ? find_search_entry(titlebar) : null;
				if (entry != null)
					entry.text = search;
				else
					warning("Screenshot mode: search entry not found");

				yield pause(STEP_SETTLE_MS);
			}

			// Popover
			var popover = get_value("popover", "");
			if (popover != "")
			{
				yield pause(get_uint("popover_delay", 0));   // e.g. let the history fill up first
				open_popover(window, popover);
			}
		} // apply


		/**
		 * @brief Opens the history or preferences popover.
		 */
		private static void open_popover(Window window, string which)
		{
			var titlebar = window.get_titlebar();
			if (titlebar == null)
				return;

			if (which == "history")
			{
				var button = find_by_tooltip(titlebar, _("History")) as Gtk.Button;
				if (button != null)
					button.clicked();
				else
					warning("Screenshot mode: History button not found");
			}
			else if (which == "preferences")
			{
				var button = find_by_tooltip(titlebar, _("Preferences")) as Gtk.MenuButton;
				if (button != null)
					button.active = true;
				else
					warning("Screenshot mode: Preferences button not found");
			}
			else
				warning("Screenshot mode: popover must be 'history' or 'preferences', got '%s'", which);
		} // open_popover


		/**
		 * @brief Fetches one station from the provider by uuid.
		 */
		private static async Station? fetch_station(string uuid)
		{
			try
			{
				var page = yield app().directory.load_station_uuid(uuid).next_page_async();
				if (page != null)
				{
					foreach (var station in page)
						return station;
				}
			}
			catch (SourceError e)
			{
				warning("Screenshot mode: could not load station %s: %s", uuid, e.message);
			}
			return null;
		} // fetch_station


		/**
		 * @brief Waits without blocking the main loop.
		 */
		private static async void pause(uint ms)
		{
			Timeout.add(ms, pause.callback);
			yield;
		} // pause


		/**
		 * @brief Finds the first descendant widget with the given tooltip text.
		 */
		private static Gtk.Widget? find_by_tooltip(Gtk.Widget root, string tooltip)
		{
			if (root.tooltip_text == tooltip)
				return root;

			var container = root as Gtk.Container;
			if (container == null)
				return null;

			Gtk.Widget? found = null;
			container.forall((child) =>
			{
				if (found == null)
					found = find_by_tooltip(child, tooltip);
			});
			return found;
		} // find_by_tooltip


		/**
		 * @brief Finds the first search entry below a widget.
		 */
		private static Gtk.SearchEntry? find_search_entry(Gtk.Widget root)
		{
			var entry = root as Gtk.SearchEntry;
			if (entry != null)
				return entry;

			var container = root as Gtk.Container;
			if (container == null)
				return null;

			Gtk.SearchEntry? found = null;
			container.forall((child) =>
			{
				if (found == null)
					found = find_search_entry(child);
			});
			return found;
		} // find_search_entry


		// ------------------------------------------------------------
		// Spec parsing
		// ------------------------------------------------------------

		private static HashMap<string, string> spec()
		{
			if (_spec == null)
			{
				_spec = new HashMap<string, string>();
				var text = Environment.get_variable(ENV_SPEC);
				if (text != null)
				{
					foreach (var pair in text.split(";"))
					{
						var kv = pair.split("=", 2);
						if (kv.length == 2 && kv[0].strip() != "")
							_spec[kv[0].strip()] = kv[1].strip();
					}
				}
			}
			return _spec;
		} // spec


		private static string get_value(string key, string fallback)
		{
			var map = spec();
			return map.has_key(key) ? map[key] : fallback;
		} // get_value


		private static uint get_uint(string key, uint fallback)
		{
			var map = spec();
			return map.has_key(key) ? (uint) uint64.parse(map[key]) : fallback;
		} // get_uint
	} // ScreenshotMode
}

#endif
