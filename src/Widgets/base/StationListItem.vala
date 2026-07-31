/*
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Tuner.Models;
using Tuner.Widgets.Granite;

namespace Tuner.Widgets.Base
{
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
        * @param slb The parent StationListBox this item belongs to
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
                var? slist = StationList.with_stations (_slb.pager.next_page ());
                if ( slist != null )
                {
                    _slb.attach_station_list (station_list, slist);
                }
            } catch (SourceError e) {
                _slb.show_alert ();
            }
        } // populate
    } // SourceListItem
} // Tuner
