/**
 * ResultEvent  
 * 	Emulates the ResultEvent class used in the flex framework for pure as3 applications.
 *
 * @author		Cristobal Dabed
 * @version		0.1
 * @url			http://livedocs.adobe.com/flex/3/langref/mx/rpc/events/ResultEvent.html
 */
package com.net.rpc.events
{
	import flash.events.Event;
	
	// TODO: Parse http code for result if any.
	
	public final class ResultEvent extends Event
	{
		// Public Constants 
		/**
		 * @static The RESULT event type.
		 */ 
		public static const RESULT:String = "result";
		
		// Public mutable properties.
		public var headers:Object = null; // In certain circumstances, headers may also be returned with a result to provide further context.
		
		// Private readonly (non-mutable) properties.
		private var _result:Object = null;
		private var _statusCode:int = 0;

		/**
		 *  Creates a new ResultEvent
		 * 	  The event that indicates an RPC operation has successfully returned a result.
		 */ 
		public function ResultEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false, result:Object = null)
		{
			super(type, bubbles, cancelable);
			this._result = result;
		}
		
		/**
		 * @readonly result value that the RPC call returns.
		 */ 
		public function get result():Object
		{
			return _result;
		}
		
		/**
		 * @override clone
		 */ 
		override public function clone():Event
		{
			return new ResultEvent(type, bubbles, cancelable, result);
		}
		
		/**
		 * @override toString
		 */
		override public function toString():String 
		{
			return '[ResultEvent type="' + type + '" bubbles=' + bubbles + ' cancelable=' + cancelable + '"]';
		}
	}
}