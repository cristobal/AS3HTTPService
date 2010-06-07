/**
 * FaultEvent  
 * 	Emulates the FaultEvent class used in the flex framework for pure as3 applications.
 *
 * @author		Cristobal Dabed
 * @version		0.1
 * @url			http://livedocs.adobe.com/flex/3/langref/mx/rpc/events/FaultEvent.html
 */
package com.net.rpc.events
{
	import flash.events.Event;
	
	import com.net.rpc.Fault;
	
	public final class FaultEvent extends Event
	{
		// Public Constants 
		/**
		 * @static The FAULT event type.
		 */ 
		public static const FAULT:String = "fault";
		
		// Public mutable properties
		public var headers:Object = null; // In certain circumstances, headers may also be returned with a fault to provide further context to the failure.

		// Private readonly (non-mutable) properties.
		private var _fault:Fault;
		private var _statusCode:int = 0; // If the source message was sent via HTTP, this property provides access to the HTTP response status code (if available), otherwise the value is 0.
		

		/**
		 * Creates a new FaultEvent
		 */  
		public function FaultEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, fault:Fault=null)
		{
			super(type, bubbles, cancelable);
			this._fault = fault;
			// TODO: Add more logic here.
		}
		
		/**
		 * @readonly fault value.
		 */ 
		public function get fault():Fault
		{
			return _fault;
		}
		
		/**
		 * @readonly status code.
		 */ 
		public function get statusCode():int
		{
			return _statusCode;
		}
		
		/**
		 * @override clone
		 */ 
		override public function clone():Event
		{
			return new FaultEvent(type, bubbles, cancelable, fault);
		}
		
		/**
		 *  @override toString
		 */
		override public function toString():String 
		{
			return '[FaultEvent type="' + type + '" bubbles='+ bubbles +' cancelable=' + cancelable +' eventPhase=' + eventPhase + ' Fault="' + fault.toString() + '"]';
		}
		
		// TODO: Implement createEvent ?; Given a Fault, this method constructs and returns a FaultEvent.
		// TODO: Implement createEventFromMessageFault ?; Given a MessageFaultEvent, this method constructs and returns a FaultEvent.
		
	}
}