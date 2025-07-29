package game.backend.utils;

import game.backend.data.EngineData;
import haxe.Http;
import haxe.io.Bytes;

import lime.app.Future;

class HttpUtil
{
	public static var userAgent:String = 'TwistEngine-${EngineData.engineVersion}-${EngineData.modVersion}-Request';
	public static function requestText(url:String):String
	{
		var r:String = null;
		var h = new Http(url);
		h.setHeader("User-Agent", userAgent);

		h.onStatus = function(s)
		{
			if (isRedirect(s))
				r = requestText(h.responseHeaders.get("Location"));
		};

		h.onData = function(d)
		{
			if (r == null)
				r = d;
		}
		h.onError = function(e)
		{
			throw e;
		}

		h.request(false);
		return r;
	}
	public static function aSyncRequestText(url:String):Future<String>
	{
		return new Future<String>(requestText.bind(url), true);
	}

	public static function requestBytes(url:String):Bytes
	{
		var r:Bytes = null;
		var h = new Http(url);
		h.setHeader("User-Agent", userAgent);

		h.onStatus = function(s)
		{
			if (isRedirect(s))
				r = requestBytes(h.responseHeaders.get("Location"));
		};

		h.onBytes = function(d)
		{
			if (r == null)
				r = d;
		}
		h.onError = function(e)
		{
			throw e;
		}

		h.request(false);
		return r;
	}
	public static function aSyncRequestBytes(url:String):Future<Bytes>
	{
		return new Future<Bytes>(requestBytes.bind(url), true);
	}

	private static function isRedirect(status:Int):Bool
	{
		switch (status)
		{
			// 301: Moved Permanently, 302: Found (Moved Temporarily), 307: Temporary Redirect, 308: Permanent Redirect  - Nex
			case 301 | 302 | 307 | 308:
				trace('[Connection Status] Redirected with status code: $status');
				return true;
		}
		return false;
	}
	public static function prettyStatus(statusCode:Dynamic) {
		var str = Std.string(statusCode);

		static var requestStatusEReg = new EReg("\\d{3}", "");
		if (requestStatusEReg.match(str))
		{
			switch (Std.parseInt(requestStatusEReg.matched(0))) {
				// informational (1XX)
				case 100:
					str += " (Continue)";
				case 101:
					str += " (Switching Protocols)";
				case 102:
					str += " (Processing)";
				case 103:
					str += " (Early Hints)";
				//successful (2XX)
				case 200:
					str += " (OK)";
				case 201:
					str += " (Created)";
				case 202:
					str += " (Accepted)";
				case 203:
					str += " (Non-Authoritative Information)";
				case 204:
					str += " (No Content)";
				case 205:
					str += " (Reset Content)";
				case 206:
					str += " (Partial Content)";
				case 207:
					str += " (Multi-Status)";
				case 208:
					str += " (Already Reported)";
				case 226:
					str += " (IM Used)";
				// redirect (3XX)
				case 300:
					str += " (Multiple Choices)";
				case 301:
					str += " (Moved Permanently)";
				case 302:
					str += " (Found)";
				case 303:
					str += " (See Other)";
				case 304:
					str += " (Not Modified)";
				case 305:
					str += " (Use Proxy)";
				case 306:
					str += " (Switch Proxy)";
				case 307:
					str += " (Temporary Redirect)";
				case 308:
					str += " (Permanent Redirect)";
				// bad request (4XX)
				case 400:
					str += " (Bad Request)";
				case 401:
					str += " (Unauthorized)";
				case 402:
					str += " (Payment Required)";
				case 403:
					str += " (Forbidden)";
				case 404:
					str += " (Not Found)";
				case 405:
					str += " (Method Not Allowed)";
				case 406:
					str += " (Not Acceptable)";
				case 407:
					str += " (Proxy Authentication Required)";
				case 408:
					str += " (Request Timeout)";
				case 409:
					str += " (Conflict)";
				case 410:
					str += " (Gone)";
				case 411:
					str += " (Length Required)";
				case 412:
					str += " (Precondition Failed)";
				case 413:
					str += " (Content Too Large)";
				case 414:
					str += " (URI Too Long)";
				case 415:
					str += " (Unsupported Media Type)";
				case 416:
					str += " (Range Not Satisfiable)";
				case 417:
					str += " (Expectation Failed)";
				case 418:
					str += " (I'm a teapot)";
				case 421:
					str += " (Misdirected Request)";
				case 422:
					str += " (Unprocessable Content)";
				case 423:
					str += " (Locked)";
				case 424:
					str += " (Failed Dependency)";
				case 425:
					str += " (Too Early)";
				case 426:
					str += " (Upgrade Required)";
				case 428:
					str += " (Precondition Required)";
				case 429:
					str += " (Too Many Requests)";
				case 431:
					str += " (Request Header Fields Too Large)";
				case 451:
					str += " (Unavailable For Legal Reasons)";
				// server error (5XX)
				case 500:
					str += " (Internal Server Error)";
				case 501:
					str += " (Not Implemented)";
				case 502:
					str += " (Bad Gateway)";
				case 503:
					str += " (Service Unavailable)";
				case 504:
					str += " (Gateway Timeout)";
				case 505:
					str += " (HTTP Version Not Supported)";
				case 506:
					str += " (Variant Also Negotiates)";
				case 507:
					str += " (Insufficient Storage)";
				case 508:
					str += " (Loop Detected)";
				case 510:
					str += " (Not Extended)";
				case 511:
					str += " (Network Authentication Required)";
			}
		}

		return str;
	}
}
