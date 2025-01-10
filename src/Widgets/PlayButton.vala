/**
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file PlayButton.vala
 * @author technosf
 * @date 2024-12-01
 * @since 2.0.0
 * @brief Player 'PLAY' button
 */

using Gtk;

/**
 * @class PlayButton
 *
 * @brief A custom widget that shows player state.
 *
 * PlayButton can control the player and does so by an ActionEvent linkage defined in the HeaderBar
 *
 * @extends Gtk.Button
 */
public class Tuner.PlayButton : Gtk.Button
{

/* Constants    */

	private Image PLAY = new Gtk.Image.from_icon_name (
		"media-playback-start-symbolic",
		IconSize.LARGE_TOOLBAR
		);

	private Image BUFFERING = new Gtk.Image.from_icon_name (
		"media-playback-pause-symbolic",
		IconSize.LARGE_TOOLBAR
		);

	private Image STOP = new Gtk.Image.from_icon_name (
		"media-playback-stop-symbolic",
		IconSize.LARGE_TOOLBAR
		);

	private Image ERROR = new Gtk.Image.from_icon_name (
		"dialog-error-symbolic",
		IconSize.LARGE_TOOLBAR
		);


/* Public */

/**
 * @class PlayButton
 *
 * @brief Create the play button and hook it up to the PlayerController
 *
 */
	public PlayButton()
	{
		Object();

		image     = PLAY;
		sensitive = true;

		app().player.state_changed_sig.connect ((station, state) =>
		                                        // Link the button image to the inverse of the player state
		{
			set_inverse_symbol (state);
		});
	}


/**
 * @brief Set the play button symbol and sensitivity
 *
 * This method is instigated from a Gst.Player state change signal.
 * Performing any UI actions directly while handling the signal
 * causes a segmentation fault. To get around this, threads_add_idle
 * is used.
 *
 * @param state The new play state string.
 */
	private void set_inverse_symbol (PlayerController.Is state)
	{
		switch (state)
		{
		case PlayerController.Is.PLAYING:
			image         = STOP;
			image.opacity = 1.0;
			break;

		case PlayerController.Is.BUFFERING:
			image         = BUFFERING;
			image.opacity = 0.5;
			break;

		case PlayerController.Is.STOPPED_ERROR:
			image         = ERROR;
			image.opacity = 0.5;
			break;

		default:            //  STOPPED:
			image         = PLAY;
			image.opacity = 1.0;
			break;
		}
	}     // set_reverse_symbol
} //  PlayButton
