/*
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Gtk;
using Tuner.Widgets.Granite;

namespace Tuner.Widgets.Base
{
    /**
    * @class StationListBoxContent
    * @brief Content stack for StationListBox.
    */
    public class StationListBoxContent : Gtk.Stack
    {
        private Box _content;
        private ListFlowBox _content_list;

        public ListFlowBox content_list { get { return _content_list; } }

        public StationListBoxContent()
        {
            Object ();

            var alert = new AlertView (
                _("Nothing here"),
                _("Something went wrong loading radio stations data from station provider. Please try again later."),
                "dialog-warning"
            );
            //  /*
            //  alert.show_action ("Try again");
            //  alert.action_activated.connect (() => {
            //      realize ();
            //  });
            //  */

            add_named (alert, "alert");

            var no_results = new AlertView (
                _("No stations found"),
                _("Please try a different search term."),
                "dialog-warning"
            );
            add_named (no_results, "nothing-found");

            _content = base_content();
            add_named (content_scroller(_content), "content");
        }

        public void show_alert ()
        {
            set_visible_child_full ("alert", StackTransitionType.NONE);
        }

        public void show_nothing_found ()
        {
            set_visible_child_full ("nothing-found", StackTransitionType.NONE);
        }

        public void show_content ()
        {
            set_visible_child_full ("content", StackTransitionType.NONE);
        }

        public void set_content (ListFlowBox content)
        {
            foreach (var child in _content.get_children ()) { child.destroy (); }

            _content_list = content;
            _content.add (_content_list);   // FIXME analyze why when 'saving a search' content is double wrapped?
            show_content ();
            show_all ();
        }

        private static Box base_content()
        {
            var content = new Box (Orientation.VERTICAL, 0);
            content.get_style_context ().add_class ("color-light");
            content.valign = Align.START;
            content.get_style_context().add_class("welcome");
            return content;
        }

        private static ScrolledWindow content_scroller(Gtk.Box content)
        {
            var scroller = new ScrolledWindow (null, null);
            scroller.hscrollbar_policy = PolicyType.NEVER;
            scroller.add (content);
            scroller.propagate_natural_height = true;
            return scroller;
        }
    } // StationListBoxContent
} // Tuner
