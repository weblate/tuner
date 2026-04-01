/**
 * SPDX-FileCopyrightText: Copyright © 2026 <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file HistoryList.vala
 *
 * @brief History list model for station/title entries.
 */

using Gee;
using Tuner.Models;

public class Tuner.Widgets.Base.HistoryEntry : GLib.Object
{
    public Station station { get; construct; }
    public string title { get; construct; }

    public HistoryEntry(Station station, string title)
    {
        Object(station: station, title: title);
    }
}

public class Tuner.Widgets.Base.HistoryList : GLib.Object
{
    public signal void entry_added_sig(HistoryEntry entry);
    public signal void entry_removed_sig(HistoryEntry entry);
    public signal void cleared_sig();

    private Gee.List<HistoryEntry> _entries = new Gee.ArrayList<HistoryEntry>();
    private HistoryEntry _last_entry = null;

    public Gee.List<HistoryEntry> entries { get { return _entries; } }
    public HistoryEntry last_entry { get { return _last_entry; } }

    public void clear()
    {
        foreach (var entry in _entries)
            entry_removed_sig(entry);
        _entries.clear();
        _last_entry = null;
        cleared_sig();
    }

    public void append(Station station, string title)
    {
        if (_last_entry != null && _last_entry.station == station && _last_entry.title == title)
            return;

        if (_last_entry != null && _last_entry.station == station && _last_entry.title == "")
            remove_last();

        var entry = new HistoryEntry(station, title);
        _entries.add(entry);
        _last_entry = entry;
        entry_added_sig(entry);
    }

    public bool replace_last_if_matches(Station station, string title_to_match, string replacement_title)
    {
        if (_last_entry == null)
            return false;
        if (_last_entry.station != station || _last_entry.title != title_to_match)
            return false;

        remove_last();
        append(station, replacement_title);
        return true;
    }

    public Gee.List<string> get_hearted_titles()
    {
        var results = new Gee.ArrayList<string>();
        foreach (var entry in _entries)
        {
            if (!entry.title.has_prefix("♥ "))
                continue;
            var title = strip_heart_prefix(entry.title);
            if (title != "")
                results.add(title);
        }
        return results;
    }

    private string strip_heart_prefix(string title)
    {
        if (!title.has_prefix("♥ "))
            return title;
        var space_index = title.index_of(" ");
        if (space_index < 0)
            return "";
        return title.substring(space_index + 1).strip();
    }

    private void remove_last()
    {
        if (_last_entry == null)
            return;
        _entries.remove(_last_entry);
        entry_removed_sig(_last_entry);
        _last_entry = _entries.size > 0 ? _entries.get(_entries.size - 1) : null;
    }
}
