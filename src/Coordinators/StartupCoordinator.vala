/**
 * SPDX-FileCopyrightText: Copyright © 2026 <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file StartupCoordinator.vala
 */

using Tuner.Controllers;
using Tuner.Events;
using Tuner.Widgets;

namespace Tuner.Coordinators {

	/**
	 * @brief Coordinates startup flows that span multiple components.
	 *
	 * Current responsibility:
	 * - Deferred auto-play of the last played station once connectivity is available.
	 */
	public class StartupCoordinator : GLib.Object
	{
		private Application _app;
		private AppEventBus _events;
		private Window _window;
		private Settings _settings;
		private DirectoryController _directory;

		private bool _autoplay_pending = false;
			private bool _autoplay_attempted = false;
			private ulong _connectivity_handler_id = 0;


			/**
			 * @brief Creates a startup coordinator bound to the app event bus.
			 *
			 * @param app Application context used for connectivity state checks.
			 * @param events App-level event bus used for connectivity events.
			 * @param window Main window used to dispatch station playback.
			 * @param settings Application settings that control auto-play behavior.
			 * @param directory Directory controller used to resolve last station UUID.
			 */
			public StartupCoordinator (
				Application app,
				AppEventBus events,
				Window window,
				Settings settings,
				DirectoryController directory
		) {
			Object();
			_app = app;
			_events = events;
			_window = window;
			_settings = settings;
			_directory = directory;

			_connectivity_handler_id = _events.connectivity_changed_sig.connect((is_online ) => {
				if (is_online)
					try_autoplay();
			});
			}


			/**
			 * @brief Starts startup workflows managed by this coordinator.
			 *
			 * If auto-play is enabled, this queues an attempt and executes it
			 * immediately when possible or later on connectivity changes.
			 */
			public void start()
			{
				if (!_settings.auto_play)
					return;

			_autoplay_pending = true;
			try_autoplay();
			}


			/**
			 * @brief Attempts one deferred auto-play run.
			 *
			 * This method is idempotent for a single app session and returns early
			 * when offline, already attempted, or when no last-played station exists.
			 */
			private void try_autoplay()
			{
				if (!_autoplay_pending || _autoplay_attempted)
					return;

			if (_app.is_offline)
				return;

			if (_settings.last_played_station.strip().length == 0)
			{
				_autoplay_pending = false;
				_autoplay_attempted = true;
				return;
			}

			_autoplay_pending = false;
			_autoplay_attempted = true;
			_directory.load();

			var source = _directory.load_station_uuid(_settings.last_played_station);
			try
			{
				foreach (var station in source.next_page())
				{
					_window.handle_play_station(station);
					break;
				}
			}
			catch (SourceError e)
			{
				warning(_("Error while trying to autoplay, aborting…"));
			}
			}


			/**
			 * @brief Disconnects coordinator event handlers and releases resources.
			 */
			public override void dispose()
			{
				if (_connectivity_handler_id > 0)
			{
				_events.disconnect(_connectivity_handler_id);
				_connectivity_handler_id = 0;
			}
			base.dispose();
		}
	}
}
