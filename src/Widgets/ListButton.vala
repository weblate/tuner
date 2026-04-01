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
using Tuner.Widgets.Base;

/**
 * @class ListButton
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
/**
 * @signal item_station_selected_sig
 * @brief Emitted when a station is selected from the dropdown menu.
 * @param station The selected station.
 */
	public signal void item_station_selected_sig(Station station);

	private Gtk.Menu dropdown_menu;
	private Gtk.Menu context_menu;
	private Gee.HashMap<HistoryEntry, Gtk.MenuItem> menu_items;
	private StringBuilder clipboard_text = new StringBuilder();
	private HistoryList _history;

/**
 * @brief Constructs a new ListButton with an icon.
 * @param icon_name The name of the icon to display on the button.
 * @param size The size of the icon.
 */
	public ListButton.from_icon_name(string? icon_name,  IconSize size = IconSize.BUTTON)
	{
		Object();
		var image = new Image.from_icon_name(icon_name, size);
		this.set_image(image);
		this.dropdown_menu = new Gtk.Menu();
		menu_items = new Gee.HashMap<HistoryEntry, Gtk.MenuItem>();
		this.clicked.connect(() => {
			if (menu_items.size > 0)
			{
				this.dropdown_menu.popup_at_widget(this, Gdk.Gravity.SOUTH, Gdk.Gravity.NORTH, null);
				limit_dropdown_menu_width();
			}
		});
		initialize_context_menu();
	}

/**
 * @brief Constructs a new ListButton without an icon.
 */
	public ListButton()
	{
		Object();
		this.dropdown_menu = new Gtk.Menu();
		menu_items = new Gee.HashMap<HistoryEntry, Gtk.MenuItem>();
		this.clicked.connect(() => {
			if (menu_items.size > 0)
			{
				this.dropdown_menu.popup_at_widget(this, Gdk.Gravity.SOUTH, Gdk.Gravity.NORTH, null);
				limit_dropdown_menu_width();
			}
		});
		initialize_context_menu();
	}


/**
 * @brief Initializes the context menu with copy and clear actions.
 */
	private void initialize_context_menu()
	{
		context_menu = new Gtk.Menu();

		var copy_item = new Gtk.MenuItem.with_label(_("Copy List to Clipboard"));
		copy_item.activate.connect(() => {
			copy_list_to_clipboard();
			context_menu.popdown();
			dropdown_menu.popdown();
		});
		context_menu.append(copy_item);

		var clear_item = new Gtk.MenuItem.with_label(_("Clear All Items"));
		clear_item.activate.connect(() => {
			clear_all_items();
			context_menu.popdown();
			dropdown_menu.popdown();
		});
		context_menu.append(clear_item);
		context_menu.show_all();
	}

/**
 * @brief Copies the list of menu items to the clipboard.
 */
	private void copy_list_to_clipboard()
	{
		var clipboard = Gtk.Clipboard.get_default(Gdk.Display.get_default());
		clipboard.set_text(clipboard_text.str, -1);
	}

/**
 * @brief Clears all items from the dropdown menu.
 */
	private void clear_all_items()
	{
		foreach (var item in menu_items.values)
			dropdown_menu.remove(item);
		menu_items.clear();
		clipboard_text.truncate();
		if (_history != null)
			_history.clear();
	}

/**
 * @brief Appends a station-title pair to the dropdown menu.
 * @param station The station to add.
 * @param title The title associated with the station.
 */
	public void append_station_title_pair(Station station, string title)
	{
		ensure_history();
		_history.append(station, title);
	}

/**
 * @brief Replaces the last station-title pair if it matches the provided title.
 *
 * @param station Station associated with the last item.
 * @param title_to_match Title to match against the last item.
 * @param replacement_title Title to use when replacing.
 * @return True if the last item was replaced.
 */
	public bool replace_last_title_if_matches(Station station, string title_to_match, string replacement_title)
	{
		ensure_history();
		return _history.replace_last_if_matches(station, title_to_match, replacement_title);
	}

/**
 * @brief Returns all hearted track titles from the list.
 *
 * @return List of track titles without the heart prefix.
 */
	public Gee.List<string> get_hearted_titles()
	{
		ensure_history();
		return _history.get_hearted_titles();
	}

	public Gee.List<string> get_hearted_history_lines_without_hearts()
	{
		ensure_history();
		var results = new Gee.ArrayList<string>();
		foreach (var entry in _history.entries)
		{
			var title = entry.title;
			if (!title.has_prefix("♥ "))
				continue;
			title = strip_heart_prefix(title);
			results.add(entry.station.name + ": " + title);
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

	private void ensure_history()
	{
		if (_history != null)
			return;

		_history = new HistoryList();
		_history.entry_added_sig.connect((entry) => { add_menu_item(entry); });
		_history.entry_removed_sig.connect((entry) => { remove_menu_item(entry); });
		_history.cleared_sig.connect(() => { menu_items.clear(); clipboard_text.truncate(); });
	}

	private void add_menu_item(HistoryEntry entry)
	{
		var label_text = entry.station.name + "\n\t" + entry.title;
		var item = new Gtk.MenuItem.with_label(label_text);
		menu_items.set(entry, item);

		item.button_press_event.connect((event) => {
			if (event.button == 1)   // Left click
			{
				item_station_selected_sig(entry.station);
				dropdown_menu.popdown();
				return true;
			}
			else if (event.button == 3)   // Right click
			{
				context_menu.popup_at_pointer(event);
				return true;
			}
			return false;
		});

		item.show();
		dropdown_menu.prepend(item);
		clipboard_text.prepend(label_text + "\n");
	}

	private void remove_menu_item(HistoryEntry entry)
	{
		var item = menu_items.get(entry);
		if (item == null)
			return;
		dropdown_menu.remove(item);
		menu_items.unset(entry);
		var label_text = entry.station.name + "\n\t" + entry.title;
		if (clipboard_text.str.has_prefix(label_text + "\n"))
			clipboard_text.erase(0, label_text.length + 1);
	}

/**
 * @brief Limits the width of the dropdown menu to 2/3 of the header bar width.
 */
	private void limit_dropdown_menu_width()
	{
		var header_bar = this.get_toplevel() as Gtk.HeaderBar;
		if (header_bar != null)
		{
			var max_width = header_bar.get_allocated_width() * 2 / 3;
			dropdown_menu.set_size_request(max_width, -1);
		}
	}
}
