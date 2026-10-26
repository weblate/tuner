/**
 * SPDX-FileCopyrightText: Copyright © 2026 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file SelectorButton.vala
 */

using Gtk;

/**
 * @class SelectorButton
 *
 * @brief Widget for selecting from a list of options, with an optional action to trigger on selection.
 *
 * This class extends Gtk.Button to create a specialized button that, when clicked, shows a popover containing a list of selectable items. 
 * Each item has an associated ID and display name. When an item is selected, the button's label updates to reflect the selection, 
 * and an optional action is activated with the selected item's ID as a parameter.
 *
 * @extends Gtk.Button
 */

public class Tuner.Widgets.Base.SelectorButton : Gtk.Button 
{

    private static int min_height = 100;
    private static int row_height = 30;

    private GLib.Action? action;
    private Popover popover;
    private ScrolledWindow scroller;
    private ListBox listbox;
    private HashTable<string,string> items;


    /**
     * @brief Creates a new SelectorButton instance.
     * 
     * @param action Optional action to be activated when an item is selected.
     */
    public SelectorButton (GLib.Action? action = null) 
    {
        this.action = action;

        this.hexpand = true;
        this.halign = Gtk.Align.FILL;
        this.width_request = 200;

        items = new HashTable<string,string> (str_hash, str_equal);

        popover = new Gtk.Popover (this);

        scroller = new Gtk.ScrolledWindow (null,null);
        scroller.set_min_content_height (min_height);
        scroller.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);

        listbox = new Gtk.ListBox ();
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;

        scroller.add (listbox);
        popover.add (scroller);

        //scroller.set_min_content_height (10 * row_height); // row height heuristic
        scroller.set_max_content_height (-1);

        listbox.show ();
        scroller.show ();

        listbox.row_activated.connect ((row) => {
           // scroller.set_min_content_height ((int) items.size () * row_height); // row height heuristic
            string id = row.get_data<string> ("id");
            this.label = items[id];
            action.activate (new Variant.string (id));
            popover.popdown ();
        });

        this.clicked.connect (() => {
            popover.show_all ();
            popover.popup ();
        });
    } // SelectorButton


    /**
     * @brief Adds an item to the selector button's list of options.
     * 
     * @param id The unique identifier for the item.
     * @param name The display name for the item.
     */
    public void add_item (string id, string name) 
    {
        items[id] = name;

        var row = new Gtk.ListBoxRow ();
        row.set_data<string> ("id", id);

        var label = new Gtk.Label (name);
        label.halign = Gtk.Align.START;
        label.margin = 6;

        row.add (label);
        listbox.add (row);
        row.show_all ();

    } // add_item


    /**
     * @brief Sets the active item in the selector button based on its ID.
     * 
     * @param id The unique identifier of the item to be set as active.
     */
    public void set_active_id (string id) 
    {
       if (!items.contains (id))
            return;

        this.label = items[id];

        foreach (Widget w in listbox.get_children ()) {
            var row = w as ListBoxRow;
            if (row == null)
                continue;

            if (row.get_data<string> ("id") == id) {
                listbox.select_row (row);

                // Ensure visible in scroll view
                listbox.show_all ();
                row.grab_focus ();
                break;
            }
        }
    } // set_active_id


    /** 
     * @brief Adds an item to the selector button and returns the instance for chaining.
     * 
     * @param id The unique identifier for the item.
     * @param name The display name for the item.
     * @return The SelectorButton instance for chaining.
     */
    public SelectorButton with_item (string id, string name) 
    {
        add_item (id, name);
        return this;
    } // with_item


    /**
     * @brief Adds multiple items to the selector button from a map of IDs to display names.
     * 
     * @param items A map where keys are item IDs and values are their corresponding display names.
     */
    public SelectorButton with_items (Gee.Map<string,string> items) 
    {
        foreach (string id in items.keys) {
            add_item (id, items[id]);
        }
        
        // Dynamically size the scroller based on item count
        int num_items = (int) this.items.size();
        int calculated_height = num_items * row_height;
        int max_height = 400;  // Cap at 400 pixels for large lists
        int height = int.min(calculated_height, max_height);
        scroller.set_size_request (-1, height);  // Set height, width auto
    
        return this;
    } // with_items


    /**
     * @brief Sets the active item in the selector button.
     * 
     * @param id The unique identifier of the item to be set as active.
     */
    public SelectorButton with_active_id (string id) 
    {
        set_active_id (id);
        return this;
    } // with_active_id

} // SelectorButton
