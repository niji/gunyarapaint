/*
Copyright (c) 2007, Øystein Wika. All rights reserved.
This software is released under the MIT License:
http://www.opensource.org/licenses/mit-license.php
version: 1.0 alpha 4
*/

package com.oysteinwika.ui{

	import flash.external.ExternalInterface;
	import flash.utils.Timer;
	import flash.events.TimerEvent;

	/**
	* Utility to get incoming ExternalInterface mousewheel calls.
	*
	* @langversion ActionScript 3.0
	* @playerversion Flash 9
	* @author Øystein Wika 12/09/2007
	*
	* @see flash.external.ExternalInterface
	*/



	public class SWFMouseWheel {

		public static var SWFMouseWheelHandler:Function;
		
		public static function _init():void {
			/**
			* Set up ExternalInterface
			*/
			if (ExternalInterface.available) {
				try {
					ExternalInterface.addCallback("jsdelta", SWFMouseWheelHandler);
					if (checkJavaScriptReady()) {
					} else {
						// JavaScript not ready yet, creating timer
						var readyTimer:Timer = new Timer(100, 10);
						readyTimer.addEventListener(TimerEvent.TIMER, timerHandler);
						readyTimer.start();
					}
				} catch (error:SecurityError) {
				} catch (error:Error) {
				}
			} else {
			}
		}
		/**
		* Functions needed by ExternalInterface
		*/
		public static function receivedFromJavaScript(value:String):void {
		}
		public static function checkJavaScriptReady():Boolean {
			var isReady:Boolean = ExternalInterface.call("isReady");
			return isReady;
		}
		public static function timerHandler(event:TimerEvent):void {
			var isReady:Boolean = checkJavaScriptReady();
			if (isReady) {
				// ExternalInterface ready
				Timer(event.target).stop();
			}
		}

	}
}