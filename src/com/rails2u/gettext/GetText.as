package com.rails2u.gettext  {
    import flash.system.Capabilities;

    public class GetText {
        public static var locale:String = Capabilities.language;
        public static var defaultLocale:String = 'en';

        public static function _(str:String, args:Array = null):String {
            var res:String;
            if (cacheLangStrings[locale] && cacheLangStrings[locale][str]) {
                res = cacheLangStrings[locale][str];
            } else if (cacheLangStrings[defaultLocale] && cacheLangStrings[defaultLocale][str]) {
                res = cacheLangStrings[defaultLocale][str];
            } else {
                res = str;
            }
            if (args) res = sprintf(res, args);
            return res;
        }

        public static function sprintf(str:String, args:Array = null):String {
            args = args.slice();
            return str.replace(/%s/g, function():String {
                return args.shift();
            });
        }

        private static var cacheLangStrings:Object = {};
        public static function initLangFile(xml:XML):void {
            var origIgnoreWhiteSpace:Boolean = XML.ignoreWhitespace;
            XML.ignoreWhitespace = false;
            try {
                for each (var lang:XML in xml.lang) {
                    var langname:String = lang.@lang.toString();
                    var res:Object = {};
                    for each (var message:XML in lang.message) {
                        res[message.msgid.toString()] =  message.msgstr.toString();
                    }
                    cacheLangStrings[langname] = res;
                }
            } finally {
                XML.ignoreWhitespace = origIgnoreWhiteSpace;
            }
        }
    }
}
