/**
 * SPDX-FileCopyrightText: Copyright © 2020-2024 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2024 technosf <https://github.com/technosf>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * @file HttpClient.vala
 * @author technosf
 * @date 2024-10-01
 * @since 1.5.4
 * @brief HTTP client implementation using Soup library
 */

using Gee;

/**
 * @class Tuner.HttpClient
 * @brief HTTP functions abstracting Soup library
 *
 * This class provides static methods for making HTTP requests using the Soup library.
 * It includes a singleton Soup.Session instance for efficient request handling.
 */
public class Tuner.Services.HttpClient : Object
{

    /**
     * @brief Singleton instance of Soup.Session
     *
     * This private static variable holds the single instance of Soup.Session
     * used for all HTTP requests in the application. It is initialized lazily
     * in the getSession() method.
     */
    private static Soup.Session _session;

    /** @brief Soup session idle timeout in seconds (also quoted in diagnostics) */
    private const int SESSION_TIMEOUT_S = 3;


    /**
     * @brief Milliseconds elapsed on a timer, for diagnostics.
     */
    private static uint elapsed_ms(Timer timer)
    {
        return (uint)(timer.elapsed() * 1000.0);
    } // elapsed_ms


    /**
     * @brief Describe an error as domain:code and message, for diagnostics.
     *
     * The domain/code pair distinguishes a timeout, a refused connection,
     * a DNS failure, a TLS failure or a cancellation.
     */
    private static string describe_error(Error e)
    {
        return @"$(e.domain.to_string()) code=$(e.code) '$(e.message)'";
    } // describe_error


    /**
     * @brief Get the singleton Soup.Session instance
     *
     * This method returns the singleton Soup.Session instance, creating it
     * if it doesn't already exist. The session is configured with a custom
     * user agent string and a timeout of 2 seconds, maximum 30 connections
     * with only one connection per host.
     * 
     *
     * @return The singleton Soup.Session instance
     */
    private static Soup.Session getSession()
    {
        if (_session == null)
        {
            _session = new Soup.Session.with_options(
               "max-conns", 50,
                "max-conns-per-host", 2 ,
                "timeout", SESSION_TIMEOUT_S,
                "user_agent", Tuner.user_agent ()
            );
        }
        return _session;
    } // getSession


    /**
     * @brief Perform a HEAD request to the specified URL
     *
     *  Does not sanity check the URL
     *
     * @param url_string The URL to send the GET request to     
     * @return status_code the HTTP status code of the response
     * @throws Error if there's an error sending the request or receiving the response
     */
     public static uint HEAD(Uri? uri) 
     {         
        if ( app().is_offline) return 0;

        if (uri == null)
        {
            warning("HEAD - Invalid URI (null)");
            return 0;
        }

        var msg = new Soup.Message.from_uri("HEAD", uri);
        if (msg == null)
        {
            warning(@"HEAD - Failed to create Soup.Message for URI: $(uri.to_string())");
            return 0;
        }
        /*
            Ignore all TLS certificate errors
        */
        msg.accept_certificate.connect ((msg, cert, errors) => {
            return true;
        });

        try { 
            getSession().send(msg);
            return msg.status_code;
        } catch (Error e) {
            warning("HEAD - Error accessing URL: %s (%s)",
            uri.to_string(),
                e.message);
        }

         return 0;
     } // HEAD


     /**
     * @brief Perform a GET request to the specified URL
     *
     * @param url_string The URL to send the GET request to
     * @param status_code Output parameter for the HTTP status code of the response
     * @return InputStream containing the response body, or null if the request failed
     * @throws Error if there's an error sending the request or receiving the response
     */
    public static InputStream? GET(Uri? uri, out uint status_code) 
    {
		status_code = 0;

		if (app().is_offline)
			return null;

        if (uri == null)
        {
            warning("GET - Invalid URI (null)");
            return null;
        }

		if (Tuner.debug_enabled ())
			debug(@"Get: $(uri.to_string()) ");

        var msg = new Soup.Message.from_uri("GET", uri);
        if (msg == null)
        {
            warning(@"GET - Failed to create Soup.Message for URI: $(uri.to_string())");
            return null;
        }

        /*
            Ignore all TLS certificate errors
        */
        msg.accept_certificate.connect ((msg, cert, errors) => {
            return true;
        });

        var timer = new Timer();   // Diagnostics: how long did the request take before it ended/failed
        try {
            var inputStream = getSession().send(msg);
            status_code = msg.status_code;
            string reason = msg.reason_phrase ?? "";   // null when no response line was parsed
            if (Tuner.debug_enabled ())
                debug(@"GET - $(status_code) $(reason) in $(elapsed_ms(timer))ms: $(uri.to_string())");
            return inputStream;
        } catch (Error e) {
            // status_code stays 0 here - no HTTP response was received at all. Report why.
            string reason = msg.reason_phrase ?? "";   // null when no response line was parsed
            debug(@"GET - No response after $(elapsed_ms(timer))ms (session timeout $(SESSION_TIMEOUT_S)s): $(uri.to_string()) - $(describe_error(e)); http_status=$(msg.status_code) reason='$(reason)'");
        }

        return null;
    } // GET


    /**
     * @brief Perform an asynchronous GET request to the specified URL
     *
     * @param url_string The URL to send the GET request to
     * @param status_code Output parameter for the HTTP status code of the response
     * @return InputStream containing the response body, or null if the request failed
     */
    public static async InputStream? GETasync(Uri? uri, int priority, out uint status_code) 
    {
        status_code = 0;

		if (app().is_offline)
			return null;

        if (uri == null)
        {
            warning("GETasync - Invalid URI (null)");
            return null;
        }

        var msg = new Soup.Message.from_uri("GET", uri);
        if (msg == null)
        {
            warning(@"GETasync - Failed to create Soup.Message for URI: $(uri.to_string())");
            return null;
        }


        /*
            Ignore all TLS certificate errors
        */
        msg.accept_certificate.connect ((msg, cert, errors) => {
            return true;
        });

		uint loop = 1;
		do
		/*
		    Try three times
		 */
		{
			var timer = new Timer();   // Diagnostics: time taken by this attempt
			try
			{
				var inputStream = yield getSession().send_async(msg, priority, app().offline_cancel);
				status_code = msg.status_code;
				if (status_code >= 200 && status_code < 300)
					return inputStream;
				string reason = msg.reason_phrase ?? "";   // null when no response line was parsed
				debug(@"GETasync - Try $(loop)/3 got HTTP $(status_code) '$(reason)' after $(elapsed_ms(timer))ms: $(uri.to_string())");
			} catch (Error e)
			{
				debug(@"GETasync - Try $(loop)/3 no response after $(elapsed_ms(timer))ms (session timeout $(SESSION_TIMEOUT_S)s): $(uri.to_string()) - $(describe_error(e)); cancelled=$(app().offline_cancel.is_cancelled())");
			}
			yield nap(200 * loop);
		} while (loop++ < 3);

        debug(@"GETasync - gave up after 3 tries, last http_status=$(status_code): $(uri.to_string())");
        return null;
    } // GETasync
}
