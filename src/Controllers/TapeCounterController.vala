/**
 * SPDX-FileCopyrightText: Copyright © 2026 <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file TapeCounterController.vala
 */

using Tuner.Events;
using Tuner.Models;

namespace Tuner.Controllers
{
	/**
	 * @brief Counts cumulative playback time and emits milestones for long-running playback.
	 *
	 * This controller counts elapsed playing time for the current station and the
	 * overall session. It emits tape counter events at a fixed interval while
	 * playback remains active.
	 *
	 * Yes, its the wrong metaphor for radio, but there is Jukebox also, so keeping it old-school tape fits :)
	 */
	public class TapeCounterController : GLib.Object
	{
		private const uint MILESTONE_SECONDS = 606; // per-station play time: 10 mins plus 1% - the radio index counts after 10 minutes. Pauses when play stops, resets on station change

		private AppEventBus _events;
		private History _history;
		private StationSession _session;
		private uint _timer_id = 0;
		private Station _station = null;
		private bool _active = false;
		private string? _station_uuid = null;	// station the milestone count belongs to
		private int64 _station_base = 0;	// that station's session play seconds when it became current
		private int64 _next_milestone = MILESTONE_SECONDS;	// station seconds at which the next milestone is due


		/**
		 * @brief Emitted every second while playback remains active.
		 *
		 * @param station The current station.
		 * @param total_play_seconds Total playback time in seconds for the session.
		 * @param station_play_seconds Playback seconds for the current station since it was selected.
		 */
		public signal void playback_time_tick_sig(Station station, int total_play_seconds, int station_play_seconds);


		/**
		 * @brief Emitted when a tape counter milestone is reached.
		 *
		 * @param station The current station.
		 * @param total_play_seconds Total playback seconds for the session.
		 * @param station_play_seconds Playback seconds for the current station since it was selected.
		 */
		public signal void tape_counter_reached_sig(Station station, int total_play_seconds, int station_play_seconds);


		/**
		 * @brief Constructs a new TapeCounterController.
		 *
		 * @param events The application event bus for player state notifications.
		 * @param history The playback history used to synchronize play state.
		 * @param session Session station records that hold the play times.
		 */
		public TapeCounterController(AppEventBus events, History history, StationSession session)
		{
			Object();
			_events = events;
			_history = history;
			_session = session;

			_events.player_state_changed_sig.connect((station, state) =>
			{
				if (state == StreamPlayer.State.PLAYING)
					start_counter(station);
				else
					stop_counter();
			});
		}


		/**
		 * @brief Total playback seconds for the current session.
		 */
		public int total_play_seconds
		{
			get { return (int) _session.total_play_seconds; }
		}


		/**
		 * @brief Playback seconds for the current station since it was selected.
		 *
		 * Only time spent playing is counted: the count stops while playback is paused and
		 * carries on from the same value when it resumes. Changing station restarts it.
		 */
		public int station_play_seconds
		{
			get { return (int) station_seconds(); }
		}


		/**
		 * @brief Reset accumulated playback counters.
		 *
		 * Stops tracking and clears the session's play-time totals.
		 */
		public void reset()
		{
			stop_counter();
			_session.reset_play_times();
			_station_uuid = null;
		}


		/**
		 * @brief Start tracking playback time for a station.
		 *
		 * Opens a play interval in the session. The station count and the milestone restart
		 * only when the station changes (by uuid). After a pause they carry on from where they stopped.
		 *
		 * @param station The station whose playback time should be counted.
		 */
		private void start_counter(Station station)
		{
			if (station == null)
				return;

			_station = station;
			_session.begin_play(station);

			if (_station_uuid != station.stationuuid)
			{
				_station_uuid = station.stationuuid;
				_station_base = _session.record_for(station).play_seconds_now;
				_next_milestone = MILESTONE_SECONDS;
			}

			if (_active)
				return;

			_active = true;
			_timer_id = Timeout.add_seconds_full(Priority.LOW, 1, () =>
			{
				if (!_active || _station == null)
					return Source.REMOVE;

				var played = station_seconds();
				var total = (int) _session.total_play_seconds;

				_history.tick_playback(_station, 1);
				playback_time_tick_sig.emit(_station, total, (int) played);
				_events.playback_time_tick_sig(_station, total, (int) played);

				if (played >= _next_milestone)
				{
					_next_milestone = (played / MILESTONE_SECONDS + 1) * MILESTONE_SECONDS;
					tape_counter_reached_sig.emit(_station, total, (int) played);
					_events.tape_counter_sig(_station);
				}

				return Source.CONTINUE;
			});
		}


		/**
		 * @brief Playback seconds for the current station since it was selected.
		 */
		private int64 station_seconds()
		{
			if (_station == null)
				return 0;
			return _session.record_for(_station).play_seconds_now - _station_base;
		}


		/**
		 * @brief Stop tracking playback time, close the session's play interval and cancel the timer.
		 */
		private void stop_counter()
		{
			_session.end_play();

			if (!_active)
				return;

			_active = false;
			if (_timer_id > 0)
			{
				Source.remove(_timer_id);
				_timer_id = 0;
			}
		}
	} // TapeCounterController
} // namespace Tuner.Controllers
