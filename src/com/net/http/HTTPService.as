package com.net.http
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.media.Camera;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Timer;
	
	import com.net.rpc.Fault;
	import com.net.rpc.events.FaultEvent;
	import com.net.rpc.events.InvokeEvent;
	import com.net.rpc.events.ResultEvent;
	
	/**
	 * HTTPService
	 * Emulates the HTTPService class used in the flex framework for pure as3 applications.
	 *
	 * @author		Cristobal Dabed
	 * @version		0.2
	 */
	public final class HTTPService extends EventDispatcher
	{
		// TODO: Add support for URLLoaderDataFormat.BINARY or URLLoaderDataFormat.VARIABLES
		// TODO: Add support for XML or URLVariables as parameters for send.
		// TODO: Add a progress wrapper for the ProgressEvent
		// TODO: Add event for HTTPStatusEvent?
		
		/* Constants */
		public static const REQUEST_METHOD_GET:String = URLRequestMethod.GET;
		public static const REQUEST_METHOD_POST:String = URLRequestMethod.POST;
		public static const RESULT_FORMAT_XML:String = "xml";
		public static const RESULT_FORMAT_TEXT:String = URLLoaderDataFormat.TEXT;
		
		public static const REQUEST_TIMEOUT_INTERVAL:int = 180;
		public static const REQUEST_TIMEOUT_INTERVAL_MIN:int = 30;
		public static const REQUEST_TIMEOUT_INTERVAL_MAX:int = 240;
		
		/* Variables */
		private var _internalResultFormat:String = RESULT_FORMAT_XML;	// xml|text
		
		private var _requestTimeout:int = REQUEST_TIMEOUT_INTERVAL;
		private var _executing:Boolean = false;
		private var timeout:Boolean = false;
		
		private var urlLoader:URLLoader = new URLLoader();
		private var urlRequest:URLRequest = new URLRequest();
		private var timer:Timer = new Timer(_requestTimeout, 1);
		
		private static var queryRe:RegExp = /\?/;
		
		/* @group  Constructor + Getter & Setters */
		/**
		 * HTTPService
		 * 	Constructor
		 */ 
		public function HTTPService(url:String="", method:String="GET", resultFormat:String="text")
		{
			super();
			
			// Set defaults
			urlRequest.url = url;
			urlRequest.method = method;
			urlLoader.dataFormat = resultFormat; // Defaults to text.
			
			// Add Event listeners.
			urlLoader.addEventListener(Event.COMPLETE, handleCompleteEvent);
			urlLoader.addEventListener(Event.OPEN, handleOpenEvent);
			
			// urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, handleHTTPStatusEvent); 	// Not Implemented
			// urlLoader.addEventListener(ProgressEvent.PROGRESS, handleProgressEvent); 		// Not Implemented
				
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSecurityError);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, handleIOError);
		}
		
		/**
		 * @read method value.
		 */
		public function get method():String {
			return urlRequest.method;
		}
		
		/**
		 * @write method value.
		 */ 
		public function set method(value:String):void {
			if(!((value == REQUEST_METHOD_GET) || (value == REQUEST_METHOD_POST))){
				throw new Error("Error: unsupported format: " + value);
			}
			urlRequest.method = value;
		}
		
		/**
		 * @read method value.
		 */
		public function get resultFormat():String {
			return _internalResultFormat;
		}
		
		/**
		 * @write method value.
		 */ 
		public function set resultFormat(value:String):void {
			if(!((resultFormat == RESULT_FORMAT_XML) || (value == RESULT_FORMAT_TEXT))){
				throw new Error("Error: unsupported result format: " + value);
			}
			_internalResultFormat = value;
		}

		/**
		 * @read method value.
		 */
		public function get url():String {
			return urlRequest.url;
		}
		
		/**
		 * @write method value.
		 */ 
		public function set url(value:String):void {
			urlRequest.url = value;
		}

		/**
		 * @read method value.
		 */
		public function get requestTimeout():int {
			return _requestTimeout;
		}
		
		/**
		 * Set timeout
		 * 
		 * @param timeout The timeout interval must be a value between: min =< x =< max, if not it will default to min or max if less or more than min, max.
		 */ 
		public function set requestTimeout(value:int):void {
			if(value < REQUEST_TIMEOUT_INTERVAL_MIN){
				value = REQUEST_TIMEOUT_INTERVAL_MIN;
			}else if(value > REQUEST_TIMEOUT_INTERVAL_MAX){
				value = REQUEST_TIMEOUT_INTERVAL_MAX;
			}
			_requestTimeout = value;
		}
		
		/**
		 * @read method value.
		 */
		public function get executing():Boolean {
			return _executing;
		}
		
		/**
		 * Cancel
		 */ 
		public function cancel():void{
			if(executing){
				urlLoader.close();
				if(timeout){
					dispatchEvent(new FaultEvent(FaultEvent.FAULT, false, false, new Fault("TimeoutError", "Timeout", "Request timed out after " + requestTimeout + " seconds")));
				} else {
					dispatchEvent(new FaultEvent(FaultEvent.FAULT, false, false, new Fault("CancelError", "Cancel", "User cancelled the current request")));
				}
				requestCompleted();
			}
		}
		
		/* @end */
		
		
		/* @group  Public Api */
		
		/**
		 * Send
		 * 	Executes an HTTPService request. The parameters are optional, but if specified should be an Object containing name-value pairs or an XML object depending on the cont
		 * 
		 * @param parameters An Object containing name-value pairs.
		 * @param cache Optional cache value if set to false it adds a new timestamp to the url request and make sures a new call is sent to the server bypassing cached values on the server.
		 */ 
		public function send(parameters:Object=null, cache:Boolean=true):void {
			// If already transmitting cancel the current request.
			if(executing){
				cancel();
			}
			
			// Start the new request.
			startRequest();
			
			var value:String = urlRequest.url; // stash the url
			/*
			 * 1. Set urlRequest.data to default empty {}, 
			 * 2. If parameters is set, then set the urlRequest.data = parameters.
			 * 3. If do not cache then add a timestamp value.
			 * 4. Send(load) the request.
			 * 
			 */
			urlRequest.data = null;
			if(parameters){
				urlRequest.data = new URLVariables();
				for(var property:String in parameters){
					urlRequest.data[property] = parameters[property];
				}
			}
			if(!cache){
				urlRequest.url += (queryRe.test(urlRequest.url) ? "&" : "?") + "time=" + Math.round(new Date().getTime()).toString();
			}
			
			urlLoader.load(urlRequest);
			urlRequest.url = value; // restore the url in case cache was set to false.
		}
		
		/* @end */
		
		
		/* @group Events */
		
		/**
		 * Handle Complete Event
		 * 
		 * @param event The event when the data has completed downloading.
		 */ 
		private function handleCompleteEvent(event:Event):void {
			var result:Object = urlLoader.data;
			/* If resultformat is xml parse the object as XML*/
			if(resultFormat == RESULT_FORMAT_XML){
				result = new XML(result);
			}
			if(willTrigger(ResultEvent.RESULT)){
				dispatchEvent(new ResultEvent(ResultEvent.RESULT, false, false, result));
			}
			requestCompleted();
		}
		
		/**
		 * Handle Open Event.
		 * 
		 * @param event The event when the connection has started downloading after the send method succesfully connects to the remote end. 
		 */ 
		private function handleOpenEvent(event:Event):void {
			if(willTrigger(InvokeEvent.INVOKE)){
				dispatchEvent(new InvokeEvent(InvokeEvent.INVOKE));
			}
		}
		
		/**
		 *  Handle HTTP status event.
		 * 
		 * @param event The httpStatus event.
		 */ 
		private function handleHTTPStatusEvent(event:HTTPStatusEvent):void {
			// TODO: Add code implementation here.
		}
		
		/**
		 * Handle Security Error
		 * 
		 * @param event The security error event.
		 */ 
		private function handleSecurityError(event:SecurityErrorEvent):void {
			if(willTrigger(FaultEvent.FAULT)){
				dispatchEvent(new FaultEvent(FaultEvent.FAULT, false, false, new Fault("SecurityError", event.type, event.text)));
			}
			requestCompleted();
		}
		
		/**
		 * Handle IO Error.
		 * 
		 * @param event The io error event.
		 */ 
		private function handleIOError(event:IOErrorEvent):void {
			if(willTrigger(FaultEvent.FAULT)){
				dispatchEvent(new FaultEvent(FaultEvent.FAULT, false, false, new Fault("IOError", event.type, event.text)));
			}
			requestCompleted();
		}
		
		/**
		 * Handle Timeout event
		 * 
		 * @param event The timerevent.
		 */ 
		private function handleTimeoutEvent(event:TimerEvent):void {
			/* Do not process here if request was already finished. */
			if(executing){
				timeout = true;
				cancel(); // Cancel the transmision.
			}
		}
		
		/* @end */
		
		
		/* @group Private methods */
		
		/**
		 * Start request.
		 * Called by the send method.
		 */ 
		private function startRequest():void {
			_executing = true;
			timeout = false;
			startTimeout();
		}
		
		/**
		 *  Request Completed
		 * 	Called by Event UrlLoader Event Handlers and cancel.
		 */ 
		private function requestCompleted():void {
			if(!timeout){
				stopTimeout();
			}
			_executing = false;
			timeout = false;
		}
		
		/**
		 * Start timeout
		 */ 
		private function startTimeout():void {
			timeout = false;
			if(timer){
				timer = null;
			}
		
			timer = new Timer(requestTimeout * 1000, 1); // multiply by 1000 since timer uses miliseconds.
			timer.addEventListener(TimerEvent.TIMER, handleTimeoutEvent);
			timer.start();
		}
		
		/**
		 * Stop timeout.
		 */ 
		private function stopTimeout():void {
			if(timer.running){
				timer.stop();
			}
		}
		
		/* @end */
		
	}
}