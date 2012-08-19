package	com.net.http
{
	import com.net.rpc.Fault;
	import com.net.rpc.events.FaultEvent;
	import com.net.rpc.events.InvokeEvent;
	import com.net.rpc.events.ResultEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	//--------------------------------------
	//  Events
	//--------------------------------------
	/**
	 * Dispatched when the connection has canceled or an timeout has occurred.
	 * In addtion to wrap the IOError and SecurityError for the URLLoader events
	 */ 
	[Event(type="com.net.rpc.events.FaultEvent", name="fault")]
	
	/**
	 * Dispatched when the connection has opened
	 */ 
	[Event(type="com.net.rpc.events.InvokeEvent", name="invoke")]
	
	/**
	 * Dispacthed when the request has completed
	 */ 
	[Event(type="com.net.rpc.events.ResultEvent", name="result")]

	/**
	 * Dispacthed when a http status has been received
	 */ 
	[Event(type="flash.events.HTTPStatusEvent", name="httpStatus")]
	
	/**
	 * Dispacthed when a http status has been received
	 */ 
	[Event(type="flash.events.HTTPStatusEvent", name="httpResponseStatus")]
	
	/**
	 * Dispacthed whenever progress has been notified
	 */ 
	[Event(type="flash.events.ProgressEvent", name="progress")]
	
	/**
	 * HTTPService
	 * Emulates the HTTPService class used in the flex framework for pure as3 applications.
	 *
	 * @author		Cristobal Dabed
	 * @version		0.5
	 */
	public final class HTTPService extends EventDispatcher
	{
		
		//--------------------------------------------------------------------------
		//
		//  Class constants
		//
		//--------------------------------------------------------------------------
		
		/**
		 * @public
		 * 	Request methods
		 */ 
		public static const REQUEST_METHOD_GET:String      = URLRequestMethod.GET;
		public static const REQUEST_METHOD_POST:String     = URLRequestMethod.POST;
		
		/**
		 * @public
		 * 	Request formats
		 */
		public static const RESULT_FORMAT_XML:String       = "xml";
		public static const RESULT_FORMAT_TEXT:String      = URLLoaderDataFormat.TEXT;
		public static const RESULT_FORMAT_BINARY:String    = URLLoaderDataFormat.BINARY;
		public static const RESULT_FORMAT_VARIABLES:String = URLLoaderDataFormat.VARIABLES;

		/**
		 * @public
		 * 	Request methods
		 */
		public static const REQUEST_TIMEOUT_INTERVAL:int     = 180;
		public static const REQUEST_TIMEOUT_INTERVAL_MIN:int = 15;
		public static const REQUEST_TIMEOUT_INTERVAL_MAX:int = 240;
		
		/**
		 * @public
		 * 	Content types
		 */ 
		public static const CONTENT_TYPE_URL_ENCODED:String = "application/x-www-form-urlencoded";
		public static const CONTENT_TYPE_FILE_UPLOAD:String  = "multipart/form-data";
		public static const CONTENT_TYPE_OCTET_STREAM:String = "application/octet-stream";
		public static const CONTENT_TYPE_XML:String          = "text/xml";
		
		
		//--------------------------------------------------------------------------
		//
		//  Class variables
		//
		//--------------------------------------------------------------------------
		/**
		 * @private
		 * 	RegExp to test wether the url contains a query string
		 */ 
		private static var queryRe:RegExp = /\?/;

		//--------------------------------------------------------------------------
		//
		//  Class methods
		//
		//--------------------------------------------------------------------------

		/**
		 * Get timestamp
		 * 
		 * @return Timestamp in ms
		 */
		private static function getTime():String
		{
			return Math.round(new Date().time).toString();
		}
		
		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------
		
		/**
		 * HTTPService
		 * 	Constructor
		 */ 
		public function HTTPService(url:String = "", method:String = "GET", resultFormat:String = "text")
		{
			super();
			timer = new Timer(requestTimeout, 1);
			timer.addEventListener(TimerEvent.TIMER, handleTimeoutEvent);
			
			// Setup Url Request
			urlRequest = new URLRequest();
			urlRequest.url 	  = url;
			urlRequest.method = method;
			

			// Setup urlLoader
			urlLoader = new URLLoader();
			urlLoader.dataFormat = resultFormat; // Defaults to text.
			urlLoader.addEventListener(Event.COMPLETE, handleCompleteEvent);
			urlLoader.addEventListener(Event.OPEN, handleOpenEvent);
			
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSecurityError);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, handleIOError);
		}
		
		
		//--------------------------------------------------------------------------
		//
		//  Variables
		//
		//--------------------------------------------------------------------------
		private var timeout:Boolean = false;
		private var timer:Timer 	= null;
		
		private var urlLoader:URLLoader   = null;
		private var urlRequest:URLRequest = null;
		
		//--------------------------------------------------------------------------
		//
		//  Properties
		//
		//--------------------------------------------------------------------------
		
		//----------------------------------
		//  contentType
		//---------------------------------- 
		
		/**
		 * @readwrite contentType
		 */
		public function get contentType():String {
			return urlRequest.contentType;
		}
		
		public function set contentType(value:String):void {
			urlRequest.contentType = value;
		}
		
		//----------------------------------
		//  executing
		//---------------------------------- 
		/**
		 * @private
		 * 	Internal value telling wether the current request is executing or not
		 */ 
		private var _executing:Boolean = false;
		
		/**
		 * @readonly executing
		 */
		public function get executing():Boolean {
			return _executing;
		}
		
		//----------------------------------
		//  method
		//---------------------------------- 
		
		/**
		 * @readwrite method
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
		
		//----------------------------------
		//  resultFormat
		//---------------------------------- 
		/**
		 * @private
		 * 	The internal result format 
		 */
		private var _internalResultFormat:String = RESULT_FORMAT_XML;
		
		/**
		 * @readwrite resultFormat.
		 */
		public function get resultFormat():String {
			return _internalResultFormat;
		}
		
		public function set resultFormat(value:String):void {
			if(!((resultFormat == RESULT_FORMAT_XML) || (value == RESULT_FORMAT_TEXT)) || (value == RESULT_FORMAT_BINARY) || (value == RESULT_FORMAT_VARIABLES)){
				throw new Error("Error: unsupported result format: " + value);
			}
			_internalResultFormat = value;
		}
		
		//----------------------------------
		//  requestTimeout
		//---------------------------------- 
		/**
		 * @private
		 * 	The timeout interval must be a value between: min =< x =< max, 
		 *  if not it will default to min or max if less or more than min, max.
		 */ 
		private var _requestTimeout:int = REQUEST_TIMEOUT_INTERVAL;
		
		/**
		 * @readwrite requestTimeout
		 */
		public function get requestTimeout():int {
			return _requestTimeout;
		}
		
		public function set requestTimeout(value:int):void {
			if (value < REQUEST_TIMEOUT_INTERVAL_MIN) {
				value = REQUEST_TIMEOUT_INTERVAL_MIN;
			}
			else if(value > REQUEST_TIMEOUT_INTERVAL_MAX) {
				value = REQUEST_TIMEOUT_INTERVAL_MAX;
			}
			_requestTimeout = value;
		}
		
		
		//----------------------------------
		//  url
		//---------------------------------- 
		/**
		 * @readwrite url
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
		
		//--------------------------------------------------------------------------
		//
		//  Override Methods
		//
		//--------------------------------------------------------------------------
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void 
		{
			if (type == ProgressEvent.PROGRESS || type == HTTPStatusEvent.HTTP_RESPONSE_STATUS || type == HTTPStatusEvent.HTTP_STATUS) {
				urlLoader.addEventListener(type, handleURLLoaderEvent, useCapture, priority, useWeakReference);
				return;
			}
			
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		//--------------------------------------------------------------------------
		//
		//  Request/Timeout Methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Start request.
		 * Called by the send method.
		 */ 
		private function startRequest():void {
			_executing = true;
			timeout    = false;
			startTimeout();
		}
		
		/**
		 *  Request Completed
		 * 	Called by Event UrlLoader Event Handlers and cancel.
		 */ 
		private function requestCompleted():void {
			if (!timeout) {
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
			
			timer.delay = requestTimeout * 1000; // multiply by 1000 since timer uses miliseconds.
			timer.start();
		}
		
		/**
		 * Stop timeout.
		 */ 
		private function stopTimeout():void {
			if (timer.running) {
				timer.stop();
			}
		}
		
		
		//--------------------------------------------------------------------------
		//
		//  Public Methods - API
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Cancel
		 */ 
		public function cancel():void{
			if (executing) {
				urlLoader.close();
				if (timeout) {
					dispatchEvent(new FaultEvent(FaultEvent.FAULT, false, false, new Fault("TimeoutError", "Timeout", "Request timed out after " + requestTimeout + " seconds")));
				} 
				else {
					dispatchEvent(new FaultEvent(FaultEvent.FAULT, false, false, new Fault("CancelError", "Cancel", "User cancelled the current request")));
				}
				requestCompleted();
			}
		}
		
		/**
		 * Send
		 * 	Executes an HTTPService request. 
		 * 	The parameters are optional, but if specified should be an Object containing name-value pairs or an XML object depending on the content
		 * 
		 * @param parameters An Object containing name-value pairs.
		 * @param cache Optional cache value if set to false it adds a new timestamp to the url request and make sures a new call is sent to the server bypassing cached values on the server.
		 */ 
		public function send(parameters:Object = null, cache:Boolean = true):void {
			// If already transmitting cancel the current request.
			if (executing) {
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
			*/
			urlRequest.data = null;
			if (parameters) {
				urlRequest.data = new URLVariables();
				for (var property:String in parameters) {
					urlRequest.data[property] = parameters[property];
				}
			}
			
			if (!cache) {
				var time:String = getTime();
				if (method == REQUEST_METHOD_GET) {
					if (!urlRequest.data) {
						urlRequest.data = new URLVariables();
					}
					urlRequest.data["time"] = time;
				} 
				else {
					urlRequest.url += (queryRe.test(urlRequest.url)  ? "&" : "?") + "time=" + time;	
				}
			}
			
			urlLoader.load(urlRequest);
			urlRequest.url = value; // restore the url in case cache was set to false.
		}
		
		/**
		 * Send data
		 * 	Executes an HTTPService request. The data parameter is required, which will be data for the request
		 * 		  
		 * @param data  An raw data object.
		 * @param cache Optional cache value if set to false it adds a new timestamp to the url request and make sures a new call is sent to the server bypassing cached values on the server.
		 */
		public function sendData(data:Object, cache:Boolean = true):void 
		{
			// If already transmitting cancel the current request.
			if (executing){
				cancel();
			}
			
			// Start the new request.
			startRequest();
			
			var value:String = urlRequest.url; // stash the url
			var oldRequestMethod:String = urlRequest.method;
			/*
			* 1. Set urlRequest.data to the passed data, 
			* 2. If parameters is set, then set the urlRequest.data = parameters.
			* 3. If do not cache then add a timestamp value.
			* 4. Send(load) the request.
			*/
			urlRequest.data = data;
			if ((contentType == CONTENT_TYPE_XML) && (urlRequest.method != REQUEST_METHOD_POST)) {
				urlRequest.method = REQUEST_METHOD_POST; // enforce post
			}

			if (!cache) {
				var time:String = getTime();
				if (method == REQUEST_METHOD_GET) {
					if (!urlRequest.data) {
						urlRequest.data = new URLVariables();
					}
					urlRequest.data["time"] = time;
				} 
				else {
					urlRequest.url += (queryRe.test(urlRequest.url)  ? "&" : "?") + "time=" + time;	
				}
			}
			
			urlLoader.load(urlRequest);
			urlRequest.url = value; 			  // restore the url in case cache was set to false.
			urlRequest.method = oldRequestMethod; // restore the method in case it was enforced to POST
		}
		
		/**
		 * Add header
		 * 
		 * @param name	The name of the header to append
		 * @param value The value of the header
		 */ 
		public function addHeader(name:String, value:String):void 
		{
			// rh => request header
			// orh => old Request header
			var rh:URLRequestHeader = new URLRequestHeader(name, value),
				orh:URLRequestHeader;
			var flag:Boolean = false;
			for(var i:int = 0, l:int = urlRequest.requestHeaders.length; i < l; i++){
				orh = URLRequestHeader(urlRequest.requestHeaders[i]);
				if(orh.name == rh.name){
					// Point to new requestHeader
					urlRequest[i] = rh;
					orh  = null;
					flag = true;
					break;
				}
			}
			if(!flag){
				urlRequest.requestHeaders.push(rh);
			}
			
		}
		
		/**
		 * Remove a header
		 * 
		 * @param name 	The name of the header to remove
		 */ 
		public function removeHeader(name:String):void
		{
			// rh => request header
			var rh:URLRequestHeader;
			for(var i:int = urlRequest.requestHeaders.length; i--;){
				rh = URLRequestHeader(urlRequest.requestHeaders[i]);
				if(rh.name == name){
					urlRequest.requestHeaders.splice(i, 1);
					break;
				}
			}
		}
		
		/**
		 * Clear headers
		 */ 
		public function clearHeaders():void 
		{
			urlRequest.requestHeaders = []; 
		}
		
		/**
		 * To curl string
		 * 
		 * @parameters
		 * 
		 * @return
		 * 	Returns an url compatible for curl execution from commandline.
		 */ 
		public function toCurlString(parameters:Object=null, cache:Boolean=true):String 
		{
			var urlVariables:URLVariables = new URLVariables();
			var args:Array = ["curl -d"], flag:Boolean = false;
			if(parameters){
				for(var property:String in parameters){
					urlVariables[property] = parameters[property];
					flag = true;
				}
			}
			
			var uri:String = urlRequest.url;
			if(!cache){
				var time:String = getTime();
				if (method == REQUEST_METHOD_GET) {
					if (!urlVariables) {
						urlVariables = new URLVariables();
					}
					urlVariables["time"] = time;
				} 
				else {
					uri += ((queryRe.test(uri) || flag) ? "&" : "?") + "time=" + getTime();
				}
			}
			
			var urlQuery:String = urlVariables.toString();
			if(!(!urlQuery || urlQuery == "")){
				args.push("\"" + urlQuery + "\"");
			}
			
			args.push(uri);
			return args.join(" ");
		}
		
		
		//--------------------------------------------------------------------------
		//
		//  Events
		//
		//--------------------------------------------------------------------------
		
		/**
		 * Handle url loader event
		 * 	Forwards events for the HTTPStatusEvent & ProgressEvent if event listeners have been bound
		 * 
		 * @param event The event
		 */ 
		private function handleURLLoaderEvent(event:Event):void
		{
			dispatchEvent(event); // forward the even
		}
		
		/**
		 * Handle Complete Event
		 * 
		 * @param event The event when the data has completed downloading.
		 */ 
		private function handleCompleteEvent(event:Event):void {
			var result:Object = urlLoader.data;
			switch(resultFormat) {
				case RESULT_FORMAT_BINARY: {
					result = result as ByteArray;
					break;
				}
				case RESULT_FORMAT_VARIABLES: {
					result = new URLVariables(String(result));
					break;
				}
				/* If resultformat is xml parse the object as XML*/
				case RESULT_FORMAT_XML: {
					result = new XML(result);
					break;
				}
			}
			
			if (willTrigger(ResultEvent.RESULT)){
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
			if (willTrigger(InvokeEvent.INVOKE)){
				dispatchEvent(new InvokeEvent(InvokeEvent.INVOKE));
			}
		}
		
		/**
		 * Handle Security Error
		 * 
		 * @param event The security error event.
		 */ 
		private function handleSecurityError(event:SecurityErrorEvent):void {
			if (willTrigger(FaultEvent.FAULT) ){
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
			if (willTrigger(FaultEvent.FAULT)) {
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
			if (executing){
				timeout = true;
				cancel(); // Cancel the transmision.
			}
		}
		
	}
}