package game.backend.system.net;

#if sys
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.FlxSignal;
import flixel.util.FlxStringUtil;

import haxe.CallStack;
import haxe.io.Bytes;
import haxe.io.Error;
import haxe.io.Path;
import haxe.ds.StringMap;

import openfl.events.Event;
import openfl.events.EventType;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.events.SecurityErrorEvent;
import openfl.net.URLRequest;
import openfl.net.URLStream;
import openfl.utils.ByteArray;

import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;
import sys.net.*;
import sys.ssl.Socket as SSLSocket;
import sys.thread.*;

import lime.app.Application;

using StringTools;

// from Psych-Online, but modified
class Downloader implements IFlxDestroyable
{
	static final DEFAULT_TEMP_FILE_EXT = ""; // ".dwl"

	public var url(default, set):String;
	public var outputFilePath(default, set):String;
	public var inProgress(default, null):Bool = false;
	public var cancelRequested(default, null):Bool = false;
	public var status(default, null):String;
	public var isConnected:Bool = false;
	public var isDownloading:Bool = false;
	public var isCompleted:Bool = false;
	public var deferredDowload:Bool = false;

	public var contentLength:Float = 0;
	public var gotContent:UInt = 0;
	public var maxTries:UInt = 10;
	public var bufferSize:UInt = 1024;
	public var delayOfConnection:Float = 5;
	public var urlFormat(default, null):URLFormat = null;
	public var currentFormat(default, null):URLFormat = null;

	public var onCanceled(get, never):FlxSignal;
	public var onProgress(get, never):FlxSignal;
	public var onCompleted(get, never):FlxSignal;
	public var gotHeaders(default, null):StringMap<String> = new StringMap();

	var _onCanceled:FlxSignal;
	var _onProgress:FlxSignal;
	var _onCompleted:FlxSignal;

	var socket:Socket;
	var file:FileOutput;
	var mutexSignal:Mutex = new Mutex();
	var thread:Thread;

	public static function downloadFileFromUrl(url:String, outputFilePath:String):Downloader
	{
		var downloader = new Downloader(url, outputFilePath);
		downloader.start();
		return downloader;
	}

	public function new(?url:String, ?outputFilePath:String)
	{
		this.url = url;
		this.outputFilePath = outputFilePath;
	}

	public function destroy()
	{
		url = null;
		mutexSignal = null;
		if (isConnected)
		{
			cancel();
		}
		else
		{
			closeProcesses();
		}
	}

	public function start(?requestHeaders:Map<String, String>)
	{
		if (thread != null || mutexSignal == null || isConnected)
			return;
		currentFormat = null;

		Application.current.onExit.add(onCloseApplication);
		thread = Thread.create(() -> {
			try
			{
				_start(urlFormat, requestHeaders);
			}
			catch (exc)
			{
				if (!cancelRequested)
				{
					trace(exc + "\n" + CallStack.toString(exc.stack) + "\n");
				}
				else
				{
					trace(exc);
				}
				doCancel();
			}
			thread = null;
		});
	}

	public function cancel() {
		if (isConnected) {
			cancelRequested = true;
			return;
		}

		doCancel();
	}

	public static function getURLFormat(url:String):URLFormat {
		var urlFormat:URLFormat = {
			isSSL: false,
			domain: "",
			port: 80,
			path: ""
		};

		if (url.startsWith("https://") || url.startsWith("wss://")) {
			urlFormat.isSSL = true;
			urlFormat.port = 443;
		}
		else if (url.startsWith("http://") || url.startsWith("ws://")) {
			urlFormat.isSSL = false;
			urlFormat.port = 80;
		}
		if (url.contains("://")) {
			url = url.substr(url.indexOf("://") + 3);
		}

		urlFormat.domain = url.substring(0, url.indexOf("/"));
		if (urlFormat.domain.indexOf(":") != -1) {
			var split = urlFormat.domain.split(":");
			urlFormat.domain = split[0];
			urlFormat.port = Std.parseInt(split[1]) ?? urlFormat.port;
		}
		urlFormat.path = url.substr(url.indexOf("/"));

		return urlFormat;
	}

	public var allowedMediaTypes:Array<String> = null;

	public function isMediaTypeAllowed(file:String) {
		if (file == null || allowedMediaTypes == null) return true;
		file = file.trim();
		for (item in allowedMediaTypes) {
			if (file == item)
				return true;
		}
		return false;
	}

	public function toString()
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("bufferSize", bufferSize),
			LabelValuePair.weak("cancelRequested", cancelRequested),
			LabelValuePair.weak("contentLength", contentLength),
			LabelValuePair.weak("delayOfConnection", delayOfConnection),
			LabelValuePair.weak("gotContent", gotContent),
			LabelValuePair.weak("inProgress", inProgress),
			LabelValuePair.weak("isConnected", isConnected),
			LabelValuePair.weak("isDownloading", isDownloading),
			LabelValuePair.weak("isCompleted", isCompleted),
			LabelValuePair.weak("maxTries", maxTries),
			LabelValuePair.weak("outputFilePath", outputFilePath),
			LabelValuePair.weak("status", status),
			LabelValuePair.weak("url", url),
			LabelValuePair.weak("urlFormat", urlFormat),
		]);
	}


	function _start(urlFormat:URLFormat, ?requestHeaders:Map<String, String>)
	{
		_resetParameters();

		if (urlFormat == null)
			return;

		isConnected = true;
		currentFormat = urlFormat;
		var headers = new StringBuf();
		headers.add('\nHost: '); headers.add(urlFormat.domain);
		if (urlFormat.port != 80 && urlFormat.port != 443)
		{
			headers.add(":"); headers.add(urlFormat.port);
		}
		headers.add('\nUser-Agent: haxe');
		if (requestHeaders != null)
		{
			for (key => value in requestHeaders)
			{
				headers.add('\n'); headers.add(key); headers.add(": "); headers.add(value);
			}
		}

		socket = urlFormat.isSSL ? new SSLSocket() : new Socket();
		socket.setTimeout(delayOfConnection);
		socket.setBlocking(true);

		status = "Connecting to the server..";
		var tries:UInt = 0;
		while (!cancelRequested) {
			tries++;

			try {
				socket.connect(new Host(urlFormat.domain), urlFormat.port);

				socket.write('GET ${urlFormat.path} HTTP/1.1${headers.toString()}\n\n');

				var httpStatus:String = socket.input.readLine();
				httpStatus = httpStatus.substr(httpStatus.indexOf(" ")).ltrim();

				if (httpStatus.startsWith("4") || httpStatus.startsWith("5")) {
					status = 'Server Error: $httpStatus (Retry #$tries)...';
					continue;
				}

				break;
			}
			catch (exc) {
				status = 'Failed to connect! (Retry #${tries})\n${exc.message}';

				if (tries >= maxTries) {
					trace(exc + "\n" + CallStack.toString(exc.stack) + "\n");
					cancelRequested = true;
					break;
				}

				Sys.sleep(delayOfConnection);
			}
		}

		if (cancelRequested) {
			doCancel();
			return;
		}

		status = "Reading server response headers...";
		gotHeaders.clear();
		var readLine:String;
		var splitHeader:Array<String>;
		while (!cancelRequested) {
			readLine = socket.input.readLine();
			if (readLine.trim().length == 0) {
				break;
			}
			splitHeader = readLine.split(": ");
			gotHeaders.set(splitHeader[0].toLowerCase(), splitHeader[1]);
		}
		readLine = null;
		splitHeader = null;

		status = "Parsing server response headers...";

		if (cancelRequested) {
			doCancel();
			return;
		}

		if (gotHeaders.exists("location")) {
			_start(getURLFormat(gotHeaders.get("location")), requestHeaders);
			return;
		}

		if (gotHeaders.exists("content-length")) {
			contentLength = Std.parseFloat(gotHeaders.get("content-length"));
		}

		if (!isMediaTypeAllowed(gotHeaders.get("content-type"))) {
			doCancel();
			return;
		}

		status = "Waiting for the download process";

		while(deferredDowload)
		{
			// while loop
		}

		if (cancelRequested) {
			doCancel();
			return;
		}

		try {
			File.saveContent(outputFilePath, ""); // cleans the file if it already exists
			file = File.write(outputFilePath, true);
		}
		catch (exc) {
			file = null;
			trace(exc);
			doCancel();
			return;
		}

		var buffer:Bytes = Bytes.alloc(bufferSize);
		var _bytesWritten:Int = 1;
		var _lastLine = '';

		status = "Dowloading";

		isDownloading = true;
		if (contentLength > 0) {
			while (gotContent < contentLength && !cancelRequested) {
				try {
					_bytesWritten = socket.input.readBytes(buffer, 0, buffer.length);
					file.writeBytes(buffer, 0, _bytesWritten);
					gotContent += _bytesWritten;
					dispatchProgressSignal();
				}
				catch (e:Dynamic) {
					if (Std.string(e).toLowerCase() == "eof" || e == Error.Blocked) {
						// Eof and Blocked will be ignored
						continue;
					}
					throw e;
				}
			}
		}
		else {
			//while (_bytesWritten > 0) {
			while (_lastLine != '0') {
				try {
					_bytesWritten = Std.parseInt('0x' + (_lastLine = socket.input.readLine()));
					file.writeBytes(socket.input.read(_bytesWritten), 0, _bytesWritten);
					gotContent += _bytesWritten;
					dispatchProgressSignal();
				}
				catch (e:Dynamic) {
					if (Std.string(e).toLowerCase() == "eof" || e == Error.Blocked) {
						// Eof and Blocked will be ignored
						continue;
					}
					throw e;
				}
			}
		}
		buffer = null;
		isDownloading = false;

		doCancel(!cancelRequested);
	}

	function dispatchProgressSignal()
	{
		if (_onProgress == null)
			return;
		var mutexSignal = mutexSignal;
		mutexSignal.acquire();
		_onProgress.dispatch();
		mutexSignal.release();
	}

	function onCloseApplication(code:Int)
	{
		trace("блять");
		cancel();
	}

	function doCancel(?callOnFinished:Bool = false) {
		closeProcesses();
		var mutexSignal = mutexSignal;
		mutexSignal.acquire();
		if (callOnFinished)
		{
			isCompleted = true;
			_onCompleted?.dispatch();
		}
		else
		{
			_onCanceled?.dispatch();
		}
		mutexSignal.release();
		isConnected = false;
		currentFormat = null;
		Application.current.onExit.remove(onCloseApplication);
	}

	function _resetParameters() {
		isConnected = false;
		isDownloading = false;
		isCompleted = false;
		contentLength = 0;
		gotContent = 0;
		status = null;
		currentFormat = null;
	}

	function closeProcesses() {
		try {
			if (socket != null) {
				socket.close();
				socket = null;
			}
		}
		catch (exc) {}

		try {
			if (file != null) {
				file.close();
				file = null;
			}
		}
		catch (exc) {}
	}

	@:noCompletion
	function get_onCompleted()
	{
		return _onCompleted ??= new FlxSignal();
	}

	@:noCompletion
	function get_onProgress()
	{
		return _onProgress ??= new FlxSignal();
	}

	@:noCompletion
	function get_onCanceled()
	{
		return _onCanceled ??= new FlxSignal();
	}

	@:noCompletion
	function set_url(newUrl:String):String
	{
		if (!inProgress)
		{
			if (urlFormat == null || this.url != newUrl)
				urlFormat = getURLFormat(newUrl);
			this.url = newUrl;
		}
		return newUrl;
	}

	@:noCompletion
	function set_outputFilePath(newPath:String):String
	{
		if (!inProgress)
		{
			if (newPath == null)
			{
				// if (url != null)
				// {
				// 	var regexPath = ~//i
				// 	this.outputFilePath = ;
				// }
				// else
				{
					this.outputFilePath = null;
				}
			}
			else
			{
				var pathObj = new Path(newPath);
				pathObj.ext ??= DEFAULT_TEMP_FILE_EXT;
				this.outputFilePath = Path.normalize(pathObj.toString());
			}
		}
		return newPath;
	}
}
typedef URLFormat = {
	var isSSL:Bool;
	var domain:String;
	var port:Int;
	var path:String;
}
#end