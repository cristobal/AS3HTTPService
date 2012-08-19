/**
 * InvokeEvent  
 * 	Emulates the InvokeEvent class used in the flex framework for pure as3 applications.
 *
 * @author		Cristobal Dabed
 * @version		0.1
 * @url			http://livedocs.adobe.com/flex/3/langref/mx/rpc/events/InvokeEvent.html
 */
package com.net.rpc.events
{
	import flash.events.Event;
	
	public final class InvokeEvent extends Event
	{
		// Public Constants 
		/**
		 * @static The INVOKE event type.
		 */ 
		public static const INVOKE:String = "invoke";
		
		/**
		 *  Creates a new InvokeEvent
		 * 	  The event that indicates an RPC operation has been invoked.
		 * 
		 */ 
		public function InvokeEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		/**
		 * @override clone
		 */ 
		override public function clone():Event
		{
			return new InvokeEvent(type, bubbles, cancelable);
		}
		
		/**
		 * @override toString
		 */
		override public function toString():String 
		{
			return '[InvokeEvent type="' + type + '" bubbles=' + bubbles + ' cancelable=' + cancelable + '"]';
		}
	}
}