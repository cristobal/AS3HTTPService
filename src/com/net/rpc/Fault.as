package com.net.rpc
{
	/**
	 * Fault  
	 * 	Emulates the Fault class used in the flex framework for pure as3 applications.
	 *
	 * @author		Cristobal Dabed
	 * @version		0.1
	 * @url			http://livedocs.adobe.com/flex/3/langref/mx/rpc/Fault.html
	 */
	public final class Fault extends Error
	{
		// Public mutable properties.
		public var content:Object = null; 	// The raw content of the fault (if available), such as an HTTP response body.
		public var rootCause:Object = null; // The cause of the fault.
		
		// Private readonly (non-mutable) properties.
		private var _faultCode:String = "";
		private var _faultString:String = "";
		private var _faultDetail:String = "";
				
		
		/**
		 * Creates a new Fault object.
		 * 
		 * @param faultCode  A simple code describing the fault.
		 * @param faultString  Text description of the fault.
		 * @param faultDetail Any extra details of the fault.
		 */ 
		public function Fault(faultCode:String, faultString:String, faultDetail:String = null)
		{
			super(faultString, (faultCode as Number));
			this._faultCode = faultCode; 
			this._faultString = faultString;
			this._faultDetail = faultDetail;
			// TODO: Add more logic here.
		}
		
		/**
		 * @readonly get faultCode
		 */ 
		public function get faultCode():String 
		{
			return _faultCode;
		}
				
		/**
		 * @readonly get faultString
		 */ 
		public function get faultString():String 
		{
			return _faultString;
		}
		
		/**
		 * @readonly get faultDetail
		 */ 
		public function get faultDetail():String 
		{
			return _faultDetail;
		}
		
		/**
		 * @override toString()
		 * 
		 * @return 
		 * 	Returns the string representation of a Fault object.
		 */
		public function toString():String
		{
			return "{'FaultCode': \""+ faultCode + "\", 'faultString': \"" + faultString + "\", 'faultDetail': \"" + faultDetail + "\"}";
		}
	}
}