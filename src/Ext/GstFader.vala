/**
 * SPDX-FileCopyrightText: Copyright © 2026 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file GstFader.vala
 *
 * @brief Volume transitions (crossfade, fade in, fade out) between GstStreamPlayer instances.
 */

using Tuner.Models;

namespace Tuner.Ext {
    /**
     * @brief Volume transitions between GstStreamPlayer instances: crossfade, fade in and fade out.
     *
     * Options are set with the set_* methods and apply to the next transition. A transition
     * requested while another is running is handled according to the TransitionPolicy.
     * Emits fade_completed when a transition finishes.
     */
    public class GstFader : GLib.Object {
        /**
         * @brief When the incoming player's volume starts to rise.
         *
         * UNBUFFERED starts the fade at once. PLAYING_READY waits for the player to reach PLAYING.
         * AUDIO_READY waits until the player's level is above the silence threshold.
         * PREROLL_AUDIO_READY prerolls the player first, then waits as AUDIO_READY. The waiting
         * modes give up after the fade-in timeout (set_fade_in_timeout_ms).
         */
        public enum FadeInMode {
            UNBUFFERED,
            PLAYING_READY,
            AUDIO_READY,
            PREROLL_AUDIO_READY
        }

        /**
         * @brief What a new transition request does while one is already running.
         *
         * IGNORE_DURING_FADE drops the new request. CANCEL_AND_START cancels the running transition
         * and starts the new one. QUEUE_LATEST keeps only the latest request and runs it when the
         * current transition finishes.
         */
        public enum TransitionPolicy {
            IGNORE_DURING_FADE,
            CANCEL_AND_START,
            QUEUE_LATEST
        }

        /**
         * @brief Shape of the volume ramp over the fade duration.
         */
        public enum FadeCurve {
            LINEAR,
            EXPONENTIAL,
            LOGARITHMIC,
            SMOOTHSTEP,
            EQUAL_POWER
        }

        // Crossfade timing state.
        private uint timeout_id = 0;
        private uint tail_timeout_id = 0;
        private uint gate_timeout_id = 0;
        private GstStreamPlayer? from_player;
        private GstStreamPlayer? to_player;
        private double target_volume = 0.5;
        private uint duration_ms = 1500;
        private uint interval_ms = 50;
        private uint elapsed_ms = 0;
        private FadeCurve curve = FadeCurve.LINEAR;
        private bool preroll_enabled = false;
        private bool tail_enabled = false;
        private bool limiter_enabled = false;
        private bool silence_gate_enabled = false;
        private bool beat_sync_enabled = false;
        private bool loudness_trim_enabled = false;
        private uint tail_duration_ms = 1200;
        private double tail_level = 0.12;
        private double silence_threshold_db = -35.0;
        private uint silence_gate_timeout_ms = 2000;
        private double target_rms_db = -20.0;
        private double max_trim_db = 12.0;
        private uint beat_window_ms = 2000;
        private uint beat_poll_ms = 50;
        private bool apply_trim_after_fade = false;
        private double pending_trim_to_db = 0.0;
        private FadeInMode fade_in_mode = FadeInMode.UNBUFFERED;
        private uint fade_in_timeout_ms = 3000;
        private TransitionPolicy transition_policy = TransitionPolicy.CANCEL_AND_START;
        private bool in_transition = false;
        private TransitionRequest? queued_request;
        private TransitionKind active_kind = TransitionKind.CROSSFADE;
        private GstStreamPlayer? active_from_player;
        private GstStreamPlayer? active_to_player;
        private double active_from_volume_start = 0.0;
        private double active_to_volume_start = 0.0;

        public signal void fade_completed (GstStreamPlayer player);

        /**
         * @brief Creates a fader with the default options: linear curve, 1500 ms, CANCEL_AND_START.
         */
        public GstFader () {
        }

        /**
         * @brief Sets the volume ramp shape used by later transitions.
         */
        public void set_curve (FadeCurve curve) {
            this.curve = curve;
        }

        /**
         * @brief Sets the default transition duration, used when a call gives no duration.
         */
        public void set_duration_ms (uint duration_ms) {
            this.duration_ms = duration_ms;
        }

        /**
         * @brief Sets when the incoming player's volume starts to rise (see FadeInMode).
         */
        public void set_fade_in_mode (FadeInMode mode) {
            fade_in_mode = mode;
        }

        /**
         * @brief Sets how a request made during a running transition is handled (see TransitionPolicy).
         */
        public void set_transition_policy (TransitionPolicy policy) {
            transition_policy = policy;
        }

        /**
         * @brief Sets the longest wait for the incoming player to become ready before the fade starts anyway.
         */
        public void set_fade_in_timeout_ms (uint timeout_ms) {
            fade_in_timeout_ms = timeout_ms;
        }

        /**
         * @brief Enables prerolling the incoming player before a crossfade starts.
         */
        public void set_preroll_enabled (bool enabled) {
            preroll_enabled = enabled;
        }

        /**
         * @brief Enables the tail: the outgoing player keeps playing quietly for a short time after the fade.
         *
         * @see set_tail_params
         */
        public void set_tail_enabled (bool enabled) {
            tail_enabled = enabled;
        }

        /**
         * @brief Enables scaling both volumes down during a crossfade so their sum never exceeds 1.0.
         */
        public void set_limiter_enabled (bool enabled) {
            limiter_enabled = enabled;
        }

        /**
         * @brief Enables waiting for a quiet moment in the outgoing stream before a crossfade starts.
         *
         * @see set_silence_gate_params
         */
        public void set_silence_gate_enabled (bool enabled) {
            silence_gate_enabled = enabled;
        }

        /**
         * @brief Enables waiting for a loud peak in the outgoing stream before a crossfade starts.
         *
         * Used only when the silence gate is off. @see set_beat_sync_params
         */
        public void set_beat_sync_enabled (bool enabled) {
            beat_sync_enabled = enabled;
        }

        /**
         * @brief Enables trimming each player's gain towards a target loudness.
         *
         * @see set_loudness_trim_params
         */
        public void set_loudness_trim_enabled (bool enabled) {
            loudness_trim_enabled = enabled;
        }

        /**
         * @brief Sets the loudness trim parameters.
         *
         * @param target_rms_db Loudness, in dB RMS, that the trim aims for.
         * @param max_trim_db Largest boost or cut, in dB, the trim may apply.
         */
        public void set_loudness_trim_params (double target_rms_db, double max_trim_db) {
            this.target_rms_db = target_rms_db;
            this.max_trim_db = max_trim_db;
        }

        /**
         * @brief Sets the tail parameters.
         *
         * @param duration_ms How long the outgoing player keeps playing after the fade.
         * @param level Tail volume as a fraction of the target volume.
         */
        public void set_tail_params (uint duration_ms, double level) {
            tail_duration_ms = duration_ms;
            tail_level = level;
        }

        /**
         * @brief Sets the silence gate parameters. The threshold is also used by the AUDIO_READY fade-in modes.
         *
         * @param threshold_db Level, in dB RMS, at or below which the stream counts as silent.
         * @param timeout_ms Longest wait for silence before the crossfade starts anyway.
         */
        public void set_silence_gate_params (double threshold_db, uint timeout_ms) {
            silence_threshold_db = threshold_db;
            silence_gate_timeout_ms = timeout_ms;
        }

        /**
         * @brief Sets the beat sync parameters.
         *
         * @param window_ms Longest wait for a peak before the crossfade starts anyway.
         * @param poll_ms How often the stream level is checked.
         */
        public void set_beat_sync_params (uint window_ms, uint poll_ms) {
            beat_window_ms = window_ms;
            beat_poll_ms = poll_ms;
        }

        /**
         * @brief Fades the outgoing player out while fading the incoming player in.
         *
         * @param from_player Player to fade out and stop, or null to only fade in.
         * @param to_player Player to fade in. It is started by the fader.
         * @param target_volume Volume the incoming player ends at.
         * @param duration_ms Fade duration, or null to use the default from set_duration_ms.
         * @param interval_ms Time between volume steps.
         */
        public void crossfade (GstStreamPlayer? from_player, GstStreamPlayer to_player, double target_volume, uint? duration_ms = null, uint interval_ms = 50) {
            // Fade out the current player while fading in the new one.
            if (!prepare_transition (TransitionRequest.crossfade (from_player, to_player, target_volume, duration_ms, interval_ms))) {
                return;
            }

            this.from_player = from_player;
            this.to_player = to_player;
            this.target_volume = target_volume;
            if (duration_ms != null) {
                this.duration_ms = duration_ms;
            }
            this.interval_ms = interval_ms;
            this.elapsed_ms = 0;

            active_kind = TransitionKind.CROSSFADE;
            active_from_player = from_player;
            active_to_player = to_player;
            active_from_volume_start = from_player != null ? from_player.volume : 0.0;
            active_to_volume_start = 0.0;
            start_crossfade ();
        }

        /**
         * @brief Starts a player at zero volume and fades it in.
         *
         * The fade starts according to the FadeInMode.
         *
         * @param to_player Player to fade in.
         * @param target_volume Volume the player ends at.
         * @param duration_ms Fade duration, or null to use the default from set_duration_ms.
         * @param interval_ms Time between volume steps.
         */
        public void fade_in (GstStreamPlayer to_player, double target_volume, uint? duration_ms = null, uint interval_ms = 50) {
            if (!prepare_transition (TransitionRequest.fade_in (to_player, target_volume, duration_ms, interval_ms))) {
                return;
            }

            this.from_player = null;
            this.to_player = to_player;
            this.target_volume = target_volume;
            if (duration_ms != null) {
                this.duration_ms = duration_ms;
            }
            this.interval_ms = interval_ms;
            this.elapsed_ms = 0;

            active_kind = TransitionKind.FADE_IN;
            active_from_player = null;
            active_to_player = to_player;
            active_from_volume_start = 0.0;
            active_to_volume_start = 0.0;

            to_player.set_volume_level (0.0);
            if (fade_in_mode == FadeInMode.PREROLL_AUDIO_READY) {
                to_player.prepare ();
            }
            start_fade_in_gate ();
        }

        /**
         * @brief Fades a player out and then stops it.
         *
         * @param from_player Player to fade out.
         * @param start_volume Volume the fade starts from.
         * @param duration_ms Fade duration, or null to use the default from set_duration_ms.
         * @param interval_ms Time between volume steps.
         */
        public void fade_out (GstStreamPlayer from_player, double start_volume, uint? duration_ms = null, uint interval_ms = 50) {
            if (!prepare_transition (TransitionRequest.fade_out (from_player, start_volume, duration_ms, interval_ms))) {
                return;
            }

            this.from_player = from_player;
            this.to_player = null;
            this.target_volume = start_volume;
            if (duration_ms != null) {
                this.duration_ms = duration_ms;
            }
            this.interval_ms = interval_ms;
            this.elapsed_ms = 0;

            active_kind = TransitionKind.FADE_OUT;
            active_from_player = from_player;
            active_to_player = null;
            active_from_volume_start = start_volume;
            active_to_volume_start = 0.0;
            start_fade_out ();
        }

        private double apply_curve (double t) {
            if (t <= 0.0) {
                return 0.0;
            }
            if (t >= 1.0) {
                return 1.0;
            }
            switch (curve) {
            case FadeCurve.EXPONENTIAL:
                return t * t;
            case FadeCurve.LOGARITHMIC:
                return Math.sqrt (t);
            case FadeCurve.SMOOTHSTEP:
                return t * t * (3.0 - 2.0 * t);
            case FadeCurve.EQUAL_POWER:
                return Math.sin (t * Math.PI / 2.0);
            case FadeCurve.LINEAR:
            default:
                return t;
            }
        }

        private void start_crossfade () {
            in_transition = true;
            to_player.set_volume_level (0.0);
            if (preroll_enabled) {
                to_player.prepare ();
            }

            if (silence_gate_enabled && from_player != null) {
                gate_timeout_id = GLib.Timeout.add (interval_ms, () => {
                    elapsed_ms += interval_ms;
                    if (from_player.last_rms_db <= silence_threshold_db || elapsed_ms >= silence_gate_timeout_ms) {
                        begin_fade ();
                        gate_timeout_id = 0;
                        return false;
                    }
                    return true;
                });
            } else if (beat_sync_enabled && from_player != null) {
                gate_timeout_id = GLib.Timeout.add (beat_poll_ms, () => {
                    elapsed_ms += beat_poll_ms;
                    if (is_on_beat (from_player.last_rms_db) || elapsed_ms >= beat_window_ms) {
                        begin_fade ();
                        gate_timeout_id = 0;
                        return false;
                    }
                    return true;
                });
            } else {
                begin_fade ();
            }
        }

        private void begin_fade () {
            elapsed_ms = 0;
            in_transition = true;
            to_player.play ();
            if (loudness_trim_enabled) {
                if (from_player == null) {
                    // Avoid a perceived jump on fade-in by applying trim after fade completes.
                    apply_trim_after_fade = true;
                    pending_trim_to_db = compute_trim_db (to_player.last_rms_db);
                    to_player.set_trim_db_level (0.0);
                } else {
                    to_player.set_trim_db_level (compute_trim_db (to_player.last_rms_db));
                    from_player.set_trim_db_level (compute_trim_db (from_player.last_rms_db));
                }
            } else {
                to_player.set_trim_db_level (0.0);
                if (from_player != null) {
                    from_player.set_trim_db_level (0.0);
                }
            }

            if (this.duration_ms == 0) {
                to_player.set_volume_level (target_volume);
                finalize_fade ();
                return;
            }

            timeout_id = GLib.Timeout.add (interval_ms, () => {
                // Ramp based on elapsed time and selected curve.
                elapsed_ms += interval_ms;
                double progress = (double) elapsed_ms / (double) duration_ms;
                if (progress > 1.0) {
                    progress = 1.0;
                }

                double curved = apply_curve (progress);

                double to_volume = target_volume * curved;
                double from_volume = active_from_volume_start * (1.0 - curved);
                if (from_player == null) {
                    from_volume = 0.0;
                }

                if (limiter_enabled && from_player != null) {
                    double sum = to_volume + from_volume;
                    if (sum > 1.0) {
                        double scale = 1.0 / sum;
                        to_volume *= scale;
                        from_volume *= scale;
                    }
                }

                to_player.set_volume_level (to_volume);
                if (from_player != null) {
                    from_player.set_volume_level (from_volume);
                }

                if (progress >= 1.0) {
                    finalize_fade ();
                    timeout_id = 0;
                    return false;
                }
                return true;
            });
        }

        private void start_fade_in_gate () {
            elapsed_ms = 0;
            in_transition = true;

            if (fade_in_mode == FadeInMode.UNBUFFERED) {
                begin_fade ();
                return;
            }

            to_player.play ();

            gate_timeout_id = GLib.Timeout.add (interval_ms, () => {
                elapsed_ms += interval_ms;

                bool ready = false;
                switch (fade_in_mode) {
                case FadeInMode.PLAYING_READY:
                    ready = (to_player.play_state == StreamPlayer.State.PLAYING);
                    break;
                case FadeInMode.AUDIO_READY:
                case FadeInMode.PREROLL_AUDIO_READY:
                    ready = (to_player.last_rms_db > silence_threshold_db);
                    break;
                case FadeInMode.UNBUFFERED:
                default:
                    ready = true;
                    break;
                }

                if (ready || elapsed_ms >= fade_in_timeout_ms) {
                    gate_timeout_id = 0;
                    begin_fade ();
                    return false;
                }
                return true;
            });
        }

        private void start_fade_out () {
            in_transition = true;
            if (this.duration_ms == 0) {
                from_player.set_volume_level (0.0);
                from_player.stop ();
                fade_completed (from_player);
                in_transition = false;
                consume_queued_request ();
                return;
            }
            timeout_id = GLib.Timeout.add (interval_ms, () => {
                elapsed_ms += interval_ms;
                double progress = (double) elapsed_ms / (double) duration_ms;
                if (progress > 1.0) {
                    progress = 1.0;
                }
                double curved = apply_curve (progress);
                double from_volume = target_volume * (1.0 - curved);
                from_player.set_volume_level (from_volume);

                if (progress >= 1.0) {
                    from_player.stop ();
                    fade_completed (from_player);
                    in_transition = false;
                    consume_queued_request ();
                    timeout_id = 0;
                    return false;
                }
                return true;
            });
        }

        private void finalize_fade () {
            if (from_player == null) {
                if (to_player != null) {
                    if (apply_trim_after_fade) {
                        to_player.set_trim_db_level (pending_trim_to_db);
                        apply_trim_after_fade = false;
                    }
                    fade_completed (to_player);
                    in_transition = false;
                    consume_queued_request ();
                }
                return;
            }
            if (tail_enabled) {
                from_player.set_volume_level (target_volume * tail_level);
                tail_timeout_id = GLib.Timeout.add (tail_duration_ms, () => {
                    from_player.stop ();
                    fade_completed (from_player);
                    in_transition = false;
                    consume_queued_request ();
                    tail_timeout_id = 0;
                    return false;
                });
            } else {
                from_player.stop ();
                fade_completed (from_player);
                in_transition = false;
                consume_queued_request ();
            }
        }

        private bool is_on_beat (double rms_db) {
            // Simple energy gate: treat strong RMS spikes as beat candidates.
            return rms_db > -18.0;
        }

        private double compute_trim_db (double rms_db) {
            if (rms_db <= -90.0) {
                return 0.0;
            }
            double delta = target_rms_db - rms_db;
            if (delta > max_trim_db) {
                return max_trim_db;
            }
            if (delta < -max_trim_db) {
                return -max_trim_db;
            }
            return delta;
        }

        /**
         * @brief Stops any running transition and drops any queued request. Players are left as they are.
         */
        public void cancel () {
            // Stop any active fade.
            if (timeout_id != 0) {
                GLib.Source.remove (timeout_id);
                timeout_id = 0;
            }
            if (tail_timeout_id != 0) {
                GLib.Source.remove (tail_timeout_id);
                tail_timeout_id = 0;
            }
            if (gate_timeout_id != 0) {
                GLib.Source.remove (gate_timeout_id);
                gate_timeout_id = 0;
            }
            in_transition = false;
            queued_request = null;
        }

        /**
         * @brief Cancels any running transition and stops the players it was using.
         *
         * @param keep_player Player to leave running, or null to stop both.
         */
        public void cancel_and_stop (GstStreamPlayer? keep_player) {
            // Cancel any transition and stop any non-kept active players.
            cancel ();
            if (active_from_player != null && active_from_player != keep_player) {
                active_from_player.stop ();
            }
            if (active_to_player != null && active_to_player != keep_player) {
                active_to_player.stop ();
            }
        }

        private bool prepare_transition (TransitionRequest request) {
            if (!in_transition) {
                cancel ();
                return true;
            }
            switch (transition_policy) {
            case TransitionPolicy.IGNORE_DURING_FADE:
                return false;
            case TransitionPolicy.CANCEL_AND_START:
                cancel ();
                return true;
            case TransitionPolicy.QUEUE_LATEST:
            default:
                queued_request = request;
                return false;
            }
        }

        private void consume_queued_request () {
            if (queued_request == null) {
                return;
            }
            var req = queued_request;
            queued_request = null;

            switch (req.kind) {
            case TransitionKind.CROSSFADE:
                crossfade (req.from_player, req.to_player, req.target_volume, req.has_duration ? req.duration_ms : (uint?) null, req.interval_ms);
                break;
            case TransitionKind.FADE_IN:
                fade_in (req.to_player, req.target_volume, req.has_duration ? req.duration_ms : (uint?) null, req.interval_ms);
                break;
            case TransitionKind.FADE_OUT:
                fade_out (req.from_player, req.target_volume, req.has_duration ? req.duration_ms : (uint?) null, req.interval_ms);
                break;
            default:
                break;
            }
        }
    }

    private enum TransitionKind {
        CROSSFADE,
        FADE_IN,
        FADE_OUT
    }

    private class TransitionRequest : GLib.Object {
        public TransitionKind kind { get; construct; }
        public GstStreamPlayer? from_player { get; construct; }
        public GstStreamPlayer? to_player { get; construct; }
        public double target_volume { get; construct; }
        public uint duration_ms { get; construct; }
        public bool has_duration { get; construct; }
        public uint interval_ms { get; construct; }

        private TransitionRequest (TransitionKind kind, GstStreamPlayer? from_player, GstStreamPlayer? to_player, double target_volume, uint? duration_ms, uint interval_ms) {
            Object (
                kind: kind,
                from_player: from_player,
                to_player: to_player,
                target_volume: target_volume,
                duration_ms: duration_ms != null ? duration_ms : 0,
                has_duration: duration_ms != null,
                interval_ms: interval_ms
            );
        }

        /**
         * @brief Request for a deferred crossfade() call.
         */
        public static TransitionRequest crossfade (GstStreamPlayer? from_player, GstStreamPlayer to_player, double target_volume, uint? duration_ms, uint interval_ms) {
            return new TransitionRequest (TransitionKind.CROSSFADE, from_player, to_player, target_volume, duration_ms, interval_ms);
        }

        /**
         * @brief Request for a deferred fade_in() call.
         */
        public static TransitionRequest fade_in (GstStreamPlayer to_player, double target_volume, uint? duration_ms, uint interval_ms) {
            return new TransitionRequest (TransitionKind.FADE_IN, null, to_player, target_volume, duration_ms, interval_ms);
        }

        /**
         * @brief Request for a deferred fade_out() call.
         */
        public static TransitionRequest fade_out (GstStreamPlayer from_player, double target_volume, uint? duration_ms, uint interval_ms) {
            return new TransitionRequest (TransitionKind.FADE_OUT, from_player, null, target_volume, duration_ms, interval_ms);
        }
    } // TransitionRequest
} // Ext