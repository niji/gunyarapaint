/**
* SWFMouseWheel v1.0 alpha4 
* http://oysteinwika.com/swfmousewheel/
* Copyright (c) 2007 Øystein Wika
*
* This software is released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
*/


var sp = document.getElementsByTagName('script'), cs = sp[sp.length - 1], qs = cs.src.replace(/^[^\?]+\??/,''), parameters = parse(qs);
function parse(query) {
   var tmpParameters = new Object ();
   if (!query) return tmpParameters;
   var tmpPairs = query.split(/[;&]/);
   for (var i = 0; i < tmpPairs.length; i++) {
      var tmpArray = tmpPairs[i].split('=');
      if (!tmpArray || tmpArray.length != 2) continue;
      var k = unescape(tmpArray[0]);
      var v = unescape(tmpArray[1]);
      v = v.replace(/\+/g, ' ');
      tmpParameters[k] = v;
   }
   return tmpParameters;
}
var id = parameters['id'];

var jsReady = false;
function isReady() {return jsReady;}
function pageInit() {jsReady = true;}

function handler(delta) {
	if (delta<0) sendToAS(delta); else sendToAS(delta);
}

function wheel(event){
	var delta = 0;
	if (!event) event = window.event;
	if (event.wheelDelta) { 
		delta = event.wheelDelta/120;
		if (window.opera) delta = delta;
	} else if (event.detail) { 
		delta = -event.detail/3;
	}
	if (delta) handler(delta);
	if (event.preventDefault) event.preventDefault();
	event.returnValue = false;
}

if (window.addEventListener) window.addEventListener('DOMMouseScroll', wheel, false);
window.onmousewheel = document.onmousewheel = wheel;

function callMovie(id) {
	if (navigator.appName.indexOf("Microsoft") != -1) {
		return window[id];
	} else {
		return document[id];
	}
}

function sendToAS(val) {
	if (val>0) callMovie(id).jsdelta(1); else if (val<0) callMovie(id).jsdelta(-1);
}