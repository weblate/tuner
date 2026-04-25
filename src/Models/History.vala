/**
 * SPDX-FileCopyrightText: Copyright © 2026 <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file History.vala
 *
 * @brief Session history model for played tracks.
 */

using Gee;

namespace Tuner.Models
{
	/**
	 * @brief One played track in the current session history.
	 */
	public class HistoryEntry : GLib.Object
	{
		public Station station { get; private set; }
		public string title { get; private set; default = ""; }
		public bool hearted { get; private set; default = false; }
		public DateTime played_at { get; private set; }
		public int played_seconds { get; private set; default = 0; }
		public bool playing { get; private set; default = false; }

		private int64 _play_started_monotonic_usec = 0;


		public HistoryEntry(Station station, string title, bool hearted = false)
		{
			Object();
			this.station = station;
			this.title = title;
			this.hearted = hearted;
			this.played_at = new DateTime.now_local();
		} // HistoryEntry


		public void update_title(string title)
		{
			this.title = title;
			notify_property("title");
		} // update_title


		public void update_hearted(bool hearted)
		{
			if (this.hearted == hearted)
				return;

			this.hearted = hearted;
			notify_property("hearted");
		} // update_hearted


		public void start_playback()
		{
			if (playing)
				return;

			_play_started_monotonic_usec = GLib.get_monotonic_time();
			playing = true;
			notify_property("playing");
		} // start_playback


		public void stop_playback()
		{
			if (!playing)
				return;

			played_seconds = get_total_played_seconds();
			_play_started_monotonic_usec = 0;
			playing = false;
			notify_property("played-seconds");
			notify_property("playing");
		} // stop_playback


		public int get_total_played_seconds()
		{
			if (!playing || _play_started_monotonic_usec == 0)
				return played_seconds;

			var elapsed_usec = GLib.get_monotonic_time() - _play_started_monotonic_usec;
			if (elapsed_usec <= 0)
				return played_seconds;

			return played_seconds + (int) (elapsed_usec / 1000000);
		} // get_total_played_seconds
	} // HistoryEntry


	/**
	 * @brief Tracks a linear history of played station/title pairs.
	 */
	public class History : GLib.Object
	{
		public signal void entry_added_sig(HistoryEntry entry);
		public signal void entry_removed_sig(HistoryEntry entry);
		public signal void entry_changed_sig(HistoryEntry entry);
		public signal void cleared_sig();

		private Gee.List<HistoryEntry> _entries = new Gee.ArrayList<HistoryEntry>();
		private HistoryEntry _last_entry = null;

		public Gee.List<HistoryEntry> entries
		{
			get { return _entries; }
		}

		public HistoryEntry last_entry
		{
			get { return _last_entry; }
		}

		public int station_change_count
		{
			get
			{
				if (_entries.size == 0)
					return 0;

				int changes = 1;
				Station previous_station = _entries[0].station;
				for (int index = 1; index < _entries.size; index++)
				{
					var entry = _entries[index];
					if (entry.station != previous_station)
					{
						changes++;
						previous_station = entry.station;
					}
				}

				return changes;
			}
		}

		public int distinct_track_count
		{
			get
			{
				var track_keys = new Gee.HashSet<string>();
				foreach (var entry in _entries)
				{
					var title = entry.title.strip();
					if (title == "")
						continue;
					track_keys.add(create_track_key(entry.station, title));
				}

				return track_keys.size;
			}
		}

		public int hearted_track_count
		{
			get
			{
				int count = 0;
				foreach (var entry in _entries)
				{
					if (entry.hearted)
						count++;
				}
				return count;
			}
		}

		public int total_played_seconds
		{
			get
			{
				int total = 0;
				foreach (var entry in _entries)
					total += entry.get_total_played_seconds();
				return total;
			}
		}


		public void clear()
		{
			stop_last_entry_playback();

			foreach (var entry in _entries)
				entry_removed_sig(entry);

			_entries.clear();
			_last_entry = null;
			cleared_sig();
		} // clear


		public void clear_preserving_last()
		{
			if (_entries.size <= 1)
				return;

			var current_entry = _last_entry;
			var removed_entries = new Gee.ArrayList<HistoryEntry>();
			foreach (var entry in _entries)
			{
				if (entry != current_entry)
					removed_entries.add(entry);
			}

			foreach (var entry in removed_entries)
			{
				_entries.remove(entry);
				entry_removed_sig(entry);
			}
		} // clear_preserving_last


		public void append(Station station, string title)
		{
			var normalized_title = title != null ? title : "";
			if (_last_entry != null
				&& _last_entry.station == station
				&& _last_entry.title == normalized_title)
			{
				return;
			}

			if (_last_entry != null
				&& _last_entry.station == station
				&& _last_entry.title == "")
			{
				remove_last();
			}
			else
			{
				stop_last_entry_playback();
			}

			var entry = new HistoryEntry(station, normalized_title);
			_entries.add(entry);
			_last_entry = entry;
			entry_added_sig(entry);
		} // append


		public bool set_last_entry_hearted_if_matches(Station station, string title, bool hearted)
		{
			if (_last_entry == null)
				return false;

			if (_last_entry.station != station || _last_entry.title != title)
				return false;

			if (_last_entry.hearted == hearted)
				return true;

			_last_entry.update_hearted(hearted);
			entry_changed_sig(_last_entry);
			return true;
		} // set_last_entry_hearted_if_matches


		public bool is_last_entry_hearted_for(Station station, string title)
		{
			return _last_entry != null
				&& _last_entry.station == station
				&& _last_entry.title == title
				&& _last_entry.hearted;
		} // is_last_entry_hearted_for


		public void sync_play_state(Station station, StreamPlayer.State state)
		{
			if (_last_entry == null || _last_entry.station != station)
				return;

			switch (state)
			{
				case StreamPlayer.State.PLAYING:
					_last_entry.start_playback();
					entry_changed_sig(_last_entry);
					break;
				default:
					if (_last_entry.playing)
					{
						_last_entry.stop_playback();
						entry_changed_sig(_last_entry);
					}
					break;
			}
		} // sync_play_state


		public Gee.List<string> get_hearted_titles()
		{
			var results = new Gee.ArrayList<string>();
			foreach (var entry in _entries)
			{
				var title = entry.title.strip();
				if (!entry.hearted || title == "")
					continue;
				results.add(title);
			}
			return results;
		} // get_hearted_titles


		public Gee.List<string> get_hearted_history_lines()
		{
			var results = new Gee.ArrayList<string>();
			foreach (var entry in _entries)
			{
				var title = entry.title.strip();
				if (!entry.hearted || title == "")
					continue;
				results.add(entry.station.name + ": " + title);
			}
			return results;
		} // get_hearted_history_lines


		private string create_track_key(Station station, string title)
		{
			return station.stationuuid + "\n" + title;
		} // create_track_key


		private void remove_last()
		{
			if (_last_entry == null)
				return;

			_last_entry.stop_playback();
			_entries.remove(_last_entry);
			entry_removed_sig(_last_entry);
			_last_entry = _entries.size > 0 ? _entries.get(_entries.size - 1) : null;
		} // remove_last


		private void stop_last_entry_playback()
		{
			if (_last_entry == null || !_last_entry.playing)
				return;

			_last_entry.stop_playback();
			entry_changed_sig(_last_entry);
		} // stop_last_entry_playback
	} // History
} // Tuner.Models
