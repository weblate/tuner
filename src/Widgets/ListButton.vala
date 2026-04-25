/**
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file ListButton.vala
 *
 * @brief ListButton classes
 *
 */

using Gtk;
using Gee;

using Tuner.Models;

/**
 * @class ListButton
 *
 * @brief A custom button with a dropdown menu for station selection and context actions
 *
 * The ListButton class provides a button that displays a dropdown menu of stations
 * and allows for context actions such as copying the list to the clipboard or clearing
 * all items from the menu.
 *
 * @extends Gtk.Button
 */
public class Tuner.Widgets.ListButton : Gtk.Button
{
	private const int MAX_VISIBLE_ROWS = 12;

	/**
	* @signal item_station_selected_sig
	* @brief Emitted when a station is selected from the dropdown menu.
	* @param station The selected station.
	*/
	public signal void item_station_selected_sig(Station station);

	private Gtk.Popover history_popover;
	private Gtk.ListBox history_list;
	private Gtk.ScrolledWindow history_scroller;
	private Gtk.Label summary_plays_value;
	private Gtk.Label summary_changes_value;
	private Gtk.Label summary_distinct_value;
	private Gtk.Label summary_hearted_value;
	private Gtk.Label total_play_time_value;
	private Gee.HashMap<HistoryEntry, Gtk.ListBoxRow> rows_by_entry;
	private uint row_refresh_timeout_id = 0;

	/**
	* @brief Constructs a new ListButton with an icon.
	* @param icon_name The name of the icon to display on the button.
	* @param size The size of the icon.
	*/
	public ListButton.from_icon_name(History history, string? icon_name,  IconSize size = IconSize.BUTTON)
	{
		Object(history: history);
		var image = new Image.from_icon_name(icon_name, size);
		this.set_image(image);
		initialize();
	} // ListButton

	
	/**
	* @brief Constructs a new ListButton without an icon.
	*/
	public ListButton(History history)
	{
		Object(history: history);
		initialize();
	} // ListButton


	public History history { get; construct; }


	private void initialize()
	{
		rows_by_entry = new Gee.HashMap<HistoryEntry, Gtk.ListBoxRow>();
		build_popover();
		start_row_refresh_timer();
		this.clicked.connect(() => {
			if (history.entries.size > 0)
			{
				history_popover.popup();
			}
		});
		bind_history();
		refresh_summary();
	} // initialize


	private void build_popover()
	{
		history_popover = new Gtk.Popover(this);
		history_popover.position = Gtk.PositionType.BOTTOM;
		history_popover.border_width = 0;
		history_popover.get_style_context().add_class("history-popover");

		var content = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		content.margin_top = 10;
		content.margin_bottom = 10;
		content.margin_start = 10;
		content.margin_end = 10;

		var summary_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		summary_box.homogeneous = true;
		summary_box.get_style_context().add_class("history-summary-box");
		summary_box.pack_start(create_summary_tile(_("Tracks"), out summary_plays_value), true, true, 0);
		summary_box.pack_start(create_summary_tile(_("Stations"), out summary_changes_value), true, true, 0);
		summary_box.pack_start(create_summary_tile(_("Unique"), out summary_distinct_value), true, true, 0);
		summary_box.pack_start(create_summary_tile(_("Hearted"), out summary_hearted_value), true, true, 0);
		content.pack_start(summary_box, false, false, 0);

		var action_row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
		action_row.margin_top = 10;
		action_row.margin_bottom = 10;
		action_row.get_style_context().add_class("history-action-row");

		var copy_button = new Gtk.Button.from_icon_name("edit-copy-symbolic", IconSize.BUTTON);
		copy_button.tooltip_text = _("Copy history to clipboard");
		copy_button.clicked.connect(() => {
			copy_list_to_clipboard();
			history_popover.popdown();
		});

		var clear_button = new Gtk.Button.from_icon_name("edit-clear-symbolic", IconSize.BUTTON);
		clear_button.tooltip_text = _("Clear history");
		clear_button.clicked.connect(() => {
			clear_all_items();
		});

		action_row.pack_start(copy_button, false, false, 0);
		action_row.pack_start(clear_button, false, false, 0);

		var action_spacer = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		action_spacer.hexpand = true;
		action_row.pack_start(action_spacer, true, true, 0);

		total_play_time_value = new Gtk.Label(format_total_play_time());
		total_play_time_value.width_chars = 7;
		total_play_time_value.xalign = 1.0f;
		total_play_time_value.tooltip_text = _("Total play time");
		total_play_time_value.get_style_context().add_class("history-total-time");
		action_row.pack_start(total_play_time_value, false, false, 0);

		content.pack_start(action_row, false, false, 0);

		history_list = new Gtk.ListBox();
		history_list.selection_mode = Gtk.SelectionMode.NONE;
		history_list.activate_on_single_click = true;
		history_list.get_style_context().add_class("history-list");

		history_scroller = new Gtk.ScrolledWindow(null, null);
		history_scroller.hscrollbar_policy = Gtk.PolicyType.NEVER;
		history_scroller.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
		history_scroller.min_content_width = 420;
		history_scroller.min_content_height = 320;
		history_scroller.max_content_height = 420;
		history_scroller.add(history_list);
		content.pack_start(history_scroller, true, true, 0);

		history_popover.add(content);
		content.show_all();
		history_popover.hide();
	} // build_popover


	private Gtk.Widget create_summary_tile(string label_text, out Gtk.Label value_label)
	{
		var tile = new Gtk.Box(Gtk.Orientation.VERTICAL, 2);
		tile.hexpand = true;
		tile.margin_top = 4;
		tile.margin_bottom = 4;
		tile.margin_start = 6;
		tile.margin_end = 6;
		tile.get_style_context().add_class("history-summary-tile");

		value_label = new Gtk.Label("0");
		value_label.xalign = 0.5f;
		value_label.get_style_context().add_class("history-summary-value");

		var caption_label = new Gtk.Label(label_text);
		caption_label.xalign = 0.5f;
		caption_label.get_style_context().add_class("history-summary-caption");

		tile.pack_start(value_label, false, false, 0);
		tile.pack_start(caption_label, false, false, 0);
		return tile;
	} // create_summary_tile


	/**
	* @brief Copies the list of menu items to the clipboard.
	*/
	private void copy_list_to_clipboard()
	{
		var clipboard = Gtk.Clipboard.get_default(Gdk.Display.get_default());
		clipboard.set_text(build_clipboard_text(), -1);
	} // copy_list_to_clipboard


	/**
	* @brief Clears all items from the dropdown menu.
	*/
	private void clear_all_items()
	{
		history.clear_preserving_last();
	} // clear_all_items


	/**
	* @brief Appends a station-title pair to the dropdown menu.
	* @param station The station to add.
	* @param title The title associated with the station.
	*/
	public void append_station_title_pair(Station station, string title)
	{
		history.append(station, title);
	} // append_station_title_pair


	/**
	* @brief Replaces the last station-title pair if it matches the provided title.
	*
	* @param station Station associated with the last item.
	* @param title_to_match Title to match against the last item.
	* @param replacement_title Title to use when replacing.
	* @return True if the last item was replaced.
	*/
	public bool set_last_entry_hearted_if_matches(Station station, string title, bool hearted)
	{
		return history.set_last_entry_hearted_if_matches(station, title, hearted);
	} // set_last_entry_hearted_if_matches


	/**
	* @brief Returns all hearted track titles from the list.
	*
	* @return List of track titles without the heart prefix.
	*/
	public Gee.List<string> get_hearted_titles()
	{
		return history.get_hearted_titles();
	} // get_hearted_titles


	/**
	* @brief Returns all hearted history lines from the list.
	*
	* @return List of history lines without the heart prefix.
	*/
	public Gee.List<string> get_hearted_history_lines_without_hearts()
	{
		return history.get_hearted_history_lines();
	} // get_hearted_history_lines_without_hearts


	private void bind_history()
	{
		history.entry_added_sig.connect((entry) => { add_menu_item(entry); });
		history.entry_removed_sig.connect((entry) => { remove_menu_item(entry); });
		history.entry_changed_sig.connect((entry) => { update_menu_item(entry); });
		history.cleared_sig.connect(() => {
			clear_menu_items();
			refresh_summary();
		});

		foreach (var entry in history.entries)
			add_menu_item(entry);
	} // bind_history


	/**
	 * @brief Adds a menu item for the given history entry.
	 * @param entry The history entry to add.
	 */
	private void add_menu_item(HistoryEntry entry)
	{
		var row = build_history_row(entry);
		rows_by_entry.set(entry, row);
		history_list.insert(row, 0);
		refresh_row_styles();
		refresh_summary();
	} // add_menu_item


	/**
	 * @brief Removes the menu item for the given history entry.
	 * @param entry The history entry to remove.
	 */
	private void remove_menu_item(HistoryEntry entry)
	{
		var row = rows_by_entry.get(entry);
		if (row == null)
			return;
		history_list.remove(row);
		rows_by_entry.unset(entry);
		refresh_row_styles();
		refresh_summary();
	} // remove_menu_item


	private void update_menu_item(HistoryEntry entry)
	{
		var row = rows_by_entry.get(entry);
		if (row == null)
			return;
		rebuild_history_row(row, entry);
		refresh_summary();
	} // update_menu_item


	private void clear_menu_items()
	{
		foreach (var row in rows_by_entry.values)
			history_list.remove(row);
		rows_by_entry.clear();
		refresh_row_styles();
	} // clear_menu_items


	private Gtk.ListBoxRow build_history_row(HistoryEntry entry)
	{
		var row = new Gtk.ListBoxRow();
		row.activatable = true;
		row.selectable = false;
		row.get_style_context().add_class("history-row");
		rebuild_history_row(row, entry);
		row.activate.connect(() => {
			item_station_selected_sig(entry.station);
			history_popover.popdown();
		});
		return row;
	} // build_history_row


	private void rebuild_history_row(Gtk.ListBoxRow row, HistoryEntry entry)
	{
		var existing_child = row.get_child();
		if (existing_child != null)
			row.remove(existing_child);

		var shell = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
		shell.margin_top = 8;
		shell.margin_bottom = 8;
		shell.margin_start = 10;
		shell.margin_end = 10;

		var text_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 3);
		text_box.hexpand = true;

		var station_label = new Gtk.Label(entry.station.name);
		station_label.xalign = 0.0f;
		station_label.ellipsize = Pango.EllipsizeMode.END;
		station_label.get_style_context().add_class("history-row-station");

		var title_label = new Gtk.Label(format_entry_title(entry));
		title_label.xalign = 0.0f;
		title_label.wrap = true;
		title_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
		title_label.max_width_chars = 52;
		title_label.ellipsize = Pango.EllipsizeMode.END;
		title_label.tooltip_text = format_entry_title(entry);
		title_label.get_style_context().add_class("history-row-title");
		if (entry.hearted)
			title_label.get_style_context().add_class("history-row-title-hearted");

		text_box.pack_start(station_label, false, false, 0);
		text_box.pack_start(title_label, false, false, 0);
		shell.pack_start(text_box, true, true, 0);

		var meta_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 4);
		meta_box.valign = Gtk.Align.START;
		meta_box.halign = Gtk.Align.END;
		meta_box.margin_start = 8;

		var time_label = new Gtk.Label(format_play_time(entry));
		time_label.width_chars = 7;
		time_label.xalign = 1.0f;
		time_label.get_style_context().add_class("history-play-time");
		meta_box.pack_start(time_label, false, false, 0);

		if (entry.hearted)
		{
			var heart_label = new Gtk.Label("♥");
			heart_label.valign = Gtk.Align.START;
			heart_label.halign = Gtk.Align.END;
			heart_label.get_style_context().add_class("history-heart-badge");
			meta_box.pack_start(heart_label, false, false, 0);
			row.get_style_context().add_class("history-row-hearted");
		}
		else
		{
			row.get_style_context().remove_class("history-row-hearted");
		}

		shell.pack_start(meta_box, false, false, 0);

		row.add(shell);
		row.tooltip_text = format_entry_title(entry);
		row.show_all();
	} // rebuild_history_row


	private string format_entry_title(HistoryEntry entry)
	{
		var title = entry.title.strip();
		if (title == "")
			return _("Unknown Track");
		return title;
	} // format_entry_title


	private void refresh_row_styles()
	{
		var children = history_list.get_children();
		int index = 0;
		foreach (var child in children)
		{
			var row = child as Gtk.ListBoxRow;
			if (row == null)
				continue;

			if ((index % 2) == 1)
				row.get_style_context().add_class("history-row-alt");
			else
				row.get_style_context().remove_class("history-row-alt");

			index++;
		}
	} // refresh_row_styles


	private void refresh_summary()
	{
		summary_plays_value.label = history.entries.size.to_string();
		summary_changes_value.label = history.station_change_count.to_string();
		summary_distinct_value.label = history.distinct_track_count.to_string();
		summary_hearted_value.label = history.hearted_track_count.to_string();
		if (total_play_time_value != null)
			total_play_time_value.label = format_total_play_time();

		bool has_entries = history.entries.size > 0;
		this.sensitive = has_entries;

		if (history_scroller != null)
			history_scroller.min_content_height = history.entries.size > MAX_VISIBLE_ROWS ? 420 : 320;
	} // refresh_summary


	private void start_row_refresh_timer()
	{
		row_refresh_timeout_id = Timeout.add_seconds(1, () =>
		{
			if (!history_popover.visible)
				return Source.CONTINUE;

			foreach (var entry in history.entries)
			{
				if (entry.playing)
					update_menu_item(entry);
			}

			return Source.CONTINUE;
		});
	} // start_row_refresh_timer


	private string format_play_time(HistoryEntry entry)
	{
		int total_seconds = entry.get_total_played_seconds();
		return format_seconds(total_seconds);
	} // format_play_time


	private string format_total_play_time()
	{
		return format_seconds(history.total_played_seconds);
	} // format_total_play_time


	private string format_seconds(int total_seconds)
	{
		int hours = total_seconds / 3600;
		int minutes = (total_seconds % 3600) / 60;
		int seconds = total_seconds % 60;

		if (hours > 0)
			return "%d:%02d:%02d".printf(hours, minutes, seconds);

		return "%d:%02d".printf(minutes, seconds);
	} // format_seconds


	private string build_clipboard_text()
	{
		var builder = new StringBuilder();
		for (int index = history.entries.size - 1; index >= 0; index--)
		{
			var entry = history.entries[index];
			builder.append(entry.station.name).append("\n\t");
			if (entry.hearted)
				builder.append("♥ ");
			builder.append(format_entry_title(entry)).append("\n");
		}
		return builder.str;
	} // build_clipboard_text
} // ListButton
