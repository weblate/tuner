/*
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family> 
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Gtk;
using Gee;
using Granite.Widgets;

/**
 * @file SourceListBox.vala
 * @brief Defines the ContentBox widget for displaying content with a header and action button.
 *
 * This file contains the implementation of the ContentBox class, which is a custom
 * Gtk.Box widget used to display content with a header, optional icon, and an
 * optional action button. It provides a flexible layout for presenting various
 * types of content within the Tuner application.
 *
 * @namespace Tuner
 */
namespace Tuner
{
    public interface StationListHookup : Object
    {
        public abstract void station_list_hookup( StationList station_list );
    } // StationListHookup


    /**
    * @class StationListBox
    * @brief A custom Gtk.Box widget for displaying content with a header and action button.
    *
    * The ContentBox class is a versatile widget used to present various types of content
    * within the Tuner application. It features a header with an optional icon and action
    * button, and a content area that can display different views based on the current state.
    *
    * @extends Gtk.Box
    */
    public class StationListBox : Gtk.Box {

        /**
        * @property header_label
        * @brief The label displayed in the header of the ContentBox.
        */
        //  public HeaderLabel header_label;

        public Button tooltip_button{ get; private set; }
        public StationListItem item { get; private set; }
        public uint item_count { get; private set; }
        public string parameter { get; set; }
        public bool show_parameter { get; set; }

        /**
        * @brief Updates the badge text for the source list item
        * @param badge The text to display in the badge
        */
        public void badge (string badge)
        {
            item.badge = badge;
        } // badge
        

        /**
        * @signal action_button_activated_sig
        * @brief Emitted when the action button is clicked.
        */
        public signal void action_button_activated_sig ();


        /**
         * Signal emitted when the number of items in the list changes.
         *
         * @param item_count The new number of items in the list
         * @param parameter Additional parameter that provides context for the change
         */
        public signal void item_count_changed_sig ( uint item_count, string? parameter );


        /**
        * @signal content_changed_sig
        * @brief Emitted when the content of the ContentBox is changed.
        */
        public signal void content_changed_sig (uint count);


        // -----------------------------------
        
        private SourceList.ExpandableItem _category;
        private ThemedIcon _icon;
        private Box _content = base_content();
        private ListFlowBox _content_list;
        private Stack _stack;
        private SourceList _source_list;
        private Stack _substack = new Stack ();
        private StationSet? _data;


        
        /**
        * @brief Constructs a new ContentBox instance.
        *
        * @param icon The optional icon to display in the header.
        * @param title The title text for the header.
        * @param subtitle An optional subtitle to display below the header.
        * @param action_icon_name The name of the icon for the action button.
        * @param action_tooltip_text The tooltip text for the action button.
        */
        private StationListBox (
            Stack stack,
            SourceList source_list,
            SourceList.ExpandableItem category,
            string name,
            string icon,
            string title,
            string subtitle,
            bool prepopulated = false,
            StationSet? data,
            string? action_tooltip_text,
            string? action_icon_name,
            bool enable_count) 
        {
            Object (
                name:name,
                orientation: Orientation.VERTICAL,
                spacing: 0
            );

            //  get_style_context().add_class("station-list-box");
            
            var _header = base_header();

            _stack = stack;
            _source_list = source_list;
            _category = category;

            _data = data;
            _icon = new ThemedIcon (icon);
            
            item = new StationListItem (title, this, prepopulated);
            item.tooltip = subtitle;
            item.icon = _icon;
            item.set_data<string> ("stack_child", name);  

            var alert = new AlertView (_("Nothing here"), _("Something went wrong loading radio stations data from radio-browser.info. Please try again later."), "dialog-warning");
            //  /*
            //  alert.show_action ("Try again");
            //  alert.action_activated.connect (() => {
            //      realize ();
            //  });
            //  */

            _substack.add_named (alert, "alert");

            var no_results = new AlertView (_("No stations found"), _("Please try a different search term."), "dialog-warning");
            _substack.add_named (no_results, "nothing-found");

            _header.pack_start (new StackLabel (subtitle, 20, 20 ), false, false);

            if (action_icon_name != null && action_tooltip_text != null) {
                tooltip_button = new Button.from_icon_name (
                    action_icon_name,
                    IconSize.LARGE_TOOLBAR
                );
                tooltip_button.valign = Align.CENTER;
                tooltip_button.tooltip_text = action_tooltip_text;
                tooltip_button.clicked.connect (() => { action_button_activated_sig (); });
                _header.pack_start (tooltip_button, false, false);            
            }

            var _parameter_label = new StackLabel("", 20, 20);
            _header.pack_start (_parameter_label, false, false);            
            notify["parameter"].connect (() => 
            {
                _parameter_label.label = parameter;
            });

            pack_start (_header, false, false);

            // -----------------------------------

            pack_start (new Separator (Orientation.HORIZONTAL), false, false);

            // -----------------------------------

            _substack.add_named (content_scroller(_content), "content");
            add (_substack);
            
            show.connect (() => {   
                _substack.set_visible_child_full ("content", StackTransitionType.NONE);            
            });

            map.connect (() => {
                source_list.selected = item;
            });

            category.add (item);  
        } // SourceListBox

        
        /**
        * @brief Initializes the ContentBox instance.
        *
        * This method is called automatically by the Vala compiler and sets up
        * the initial style context for the widget.
        */
        construct {
            get_style_context ().add_class ("color-dark");
        } // construct


        /**
        * @brief Retrieves the next page of stations from the data source
        * @return A Set of Model.Station objects, or null if no data source exists
        * @throws SourceError If there's an error retrieving the next page
        */
        public Set<Model.Station>? next_page () throws SourceError
        {
            if ( _data == null ) return null;
            return _data.next_page();
        } // next_page


        /**
        * @brief Displays the alert view in the content area.
        */
        public void show_alert () {
            _substack.set_visible_child_full ("alert", StackTransitionType.NONE);
        } // show_alert


        /**
        * @brief Displays the "nothing found" view in the content area.
        */
        public void show_nothing_found () {
            _substack.set_visible_child_full ("nothing-found", StackTransitionType.NONE);
        } // show_nothing_found
        

        /**
        * @brief Sets the content list and displays it
        * @param content The ContentList to display
        */
        public void list(ListFlowBox content)
        {
            this.content = content;
            show_all();
        } // list


        /**
        * @brief Removes this SourceListBox from the stack and category
        */
        public void delist()
        {
            _stack.remove(this);
            _category.remove (item);
            tooltip_button.sensitive = false;
        } // delist


        /**
        * @property content
        * @brief Gets or sets the content list displayed in the ContentBox.
        *
        * When setting this property, it replaces the current content with the new
        * AbstractContentList and emits the content_changed_sig signal.
        */
        public ListFlowBox content { 
            set {
            
                foreach (var child in _content.get_children ()) { child.destroy (); }

                _substack.set_visible_child_full ("content", StackTransitionType.NONE);
                _content_list = value;

                _content.add (_content_list);   // FIXME analyze why when 'saving a search' content is double wrapped? 
                item_count = _content_list.item_count;
                item_count_changed_sig(item_count, parameter);
                show_all ();
            }

            get {
                return _content_list; 
            }
        } // content


        // -----------------------------------------------

        
        /**
        * @brief Creates a basic header box with horizontal orientation
        * @return A new Gtk.Box configured as a header
        */
        private static Box base_header()
        {
            var header = new Box (Orientation.HORIZONTAL, 0);
            header.homogeneous = false;
            return header;
        } // base_header


        /**
        * @brief Creates a basic content box with vertical orientation
        * @return A new Gtk.Box configured for content
        */
        private static Box base_content()
        {
            var content = new Box (Orientation.VERTICAL, 0);
            content.get_style_context ().add_class ("color-light");
            content.valign = Align.START;
            content.get_style_context().add_class("welcome");
            return content;
        } // base_content


        /**
        * @brief Creates a scrolled window containing the content box
        * @param content The content box to be placed in the scrolled window
        * @return A new Gtk.ScrolledWindow containing the content
        */
        private static ScrolledWindow content_scroller(Gtk.Box content)
        {
            var scroller = new ScrolledWindow (null, null);
            scroller.hscrollbar_policy = PolicyType.NEVER;
            scroller.add (content);
            scroller.propagate_natural_height = true;        
            return scroller;
        } // content_scroller

        // --------------------------------------------------


        /**
        * @brief Factory method to create a new SourceListBox instance
        * @param stack The main stack widget
        * @param source_list The source list widget
        * @param category The category to add this item to
        * @param name The name identifier for this box
        * @param icon The icon name to display
        * @param title The title text to display
        * @param subtitle The subtitle text to display
        * @param prepopulated Whether the content is pre-populated
        * @param data The station data set
        * @param action_tooltip_text The tooltip text for the action button
        * @param action_icon_name The icon name for the action button
        * @return A new SourceListBox instance
        */
        public static StationListBox create(
            Stack stack,
            SourceList source_list,
            SourceList.ExpandableItem category,
            string name,
            string icon,
            string title,
            string subtitle,
            bool prepopulated = false,
            StationSet? data = null,
            string? action_tooltip_text = null,
            string? action_icon_name = null ) 
        {
            var slb = new StationListBox(
                stack,
                source_list,
                category,
                name,
                icon,
                title,
                subtitle,
                prepopulated,
                data,
                action_tooltip_text,
                action_icon_name,
                true);

            stack.add_named (slb, name);

            return slb;
        } // create

        /**
        * @brief Creates a predefined category in the source list.
        * @param stack The stack widget.
        * @param source_list The source list widget.
        * @param category The category to add to.
        * @param name The name of the category.
        * @param icon The icon for the category.
        * @param title The title of the category.
        * @param subtitle The subtitle of the category.
        * @param stations The collection of stations for the category.
        * @return The created SourceListBox for the category.
        */
        public static StationListBox create_category_predefined
        ( StationListHookup slh
        , Gtk.Stack stack
        , Granite.Widgets.SourceList source_list
        , Granite.Widgets.SourceList.ExpandableItem category
        , string name
        , string icon
        , string title
        , string subtitle
        , Collection<Model.Station>? stations
        )
        {
            var genre = StationListBox.create 
                ( stack
                , source_list
                , category
                , name
                , icon
                , title
                , subtitle 
                , true
                );

            if (stations != null)
            {
                var slist = StationList.with_stations (stations);
                slh.station_list_hookup(slist);
                genre.content = slist;
            }

            return genre;

        } // create_category_predefined

        /**
        * @brief Creates a specific category in the source list.
        * @param stack The stack widget.
        * @param source_list The source list widget.
        * @param category The category to add to.
        * @param name The name of the category.
        * @param icon The icon for the category.
        * @param title The title of the category.
        * @param subtitle The subtitle of the category.
        * @param station_set The set of stations for the category.
        * @param action_tooltip_text Optional tooltip text for the action.
        * @param action_icon_name Optional icon name for the action.
        * @return The created SourceListBox for the category.
        */
        public static StationListBox create_category_specific
        ( Gtk.Stack stack,
        Granite.Widgets.SourceList source_list,
        Granite.Widgets.SourceList.ExpandableItem category,
        string name,
        string icon,
        string title,
        string subtitle,
        StationSet station_set,
        string? action_tooltip_text = null,
        string? action_icon_name    = null
        )
        {
            var genre = StationListBox.create
            ( stack,
            source_list,
            category,
            name,
            icon,
            title,
            subtitle,
            false,
            station_set,
            action_tooltip_text,
            action_icon_name
            );

            return genre;
        } // create_category_specific

    } // SourceListBox


    /**
    * @class StationListItem
    * @brief A custom source list item that manages its own population state
    *
    * This class extends SourceList.Item to provide functionality for lazy-loading
    * content and managing the populated state of radio station listings.
    *
    * @extends SourceList.Item
    */
    public class StationListItem : SourceList.Item
    {
        private bool _populated;
        private StationListBox _slb;

        /**
        * @brief Constructs a new SourceListItem
        * @param title The display title for the item
        * @param slb The parent SourceListBox this item belongs to
        * @param prepopulated Whether this item starts with populated content
        */
        public StationListItem(string title, StationListBox slb, bool prepopulated = false ) 
        {
            base (
                title
            );
            _slb = slb;
            _populated = prepopulated;
        }

        /**
        * @brief Populates the item with station data if not already populated
        * @param display The Display instance to hook up the station list
        * 
        * This method checks if the item needs population and if the app is online,
        * then attempts to load the next page of stations. If successful, it hooks
        * up the station list to the display and updates the content.
        */
        public void populate( StationListHookup station_list, bool force = false )
        {
            if ( ( _populated && !force ) || app().is_offline ) return;
            _populated = true;
            try {
                var? slist = StationList.with_stations (_slb.next_page ());
                if ( slist != null ) 
                {
                    station_list.station_list_hookup(slist);
                    _slb.content = slist;
                    _slb.content.show_all ();
                }
            } catch (SourceError e) {
                _slb.show_alert ();
            }
        } // populate
    } // SourceListItem
} // Tuner