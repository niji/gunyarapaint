package org.libspark.gunyarapaint.ui.v1.net
{
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.navigateToURL;
    
    import org.libspark.gunyarapaint.framework.net.IParameters;
    import org.libspark.gunyarapaint.framework.net.IRequest;
    
    public final class Request implements IRequest
    {
        public function Request()
        {
            m_loader = EventDispatcher(new URLLoader());
        }
        
        public function post(url:String, parameters:IParameters):void
        {
            var request:URLRequest = new URLRequest(url);
            request.method = URLRequestMethod.POST;
            request.contentType = "application/x-nicopedia-oekaki";
            request.data = parameters.serialize();
            var loader:URLLoader = URLLoader(m_loader);
            loader.dataFormat = URLLoaderDataFormat.BINARY;
            loader.load(request);
        }
        
        public function get(url:String):void
        {
            var request:URLRequest = new URLRequest(url);
            request.method = URLRequestMethod.GET;
            var loader:URLLoader = URLLoader(m_loader);
            loader.dataFormat = URLLoaderDataFormat.BINARY;
            loader.load(request);
        }
        
        public function load(url:String):void
        {
            var request:URLRequest = new URLRequest(url);
            request.method = URLRequestMethod.GET;
            var loader:Loader = LoaderInfo(m_loader).loader;
            loader.load(request);
        }
        
        public static function redirect(url:String):void
        {
            var request:URLRequest = new URLRequest();
            request.url = url;
            request.method = URLRequestMethod.GET;
            navigateToURL(request, "_top");
        }
        
        public function addEventListener(type:String,
                                         listener:Function,
                                         useCapture:Boolean=false,
                                         priority:int=0,
                                         useWeakReference:Boolean=false):void
        {
            m_loader.addEventListener(type, listener, useCapture, priority, useWeakReference);
        }
        
        public function removeEventListener(type:String,
                                            listener:Function,
                                            useCapture:Boolean=false):void
        {
            m_loader.removeEventListener(type, listener, useCapture);
        }
        
        public function dispatchEvent(event:Event):Boolean
        {
            return m_loader.dispatchEvent(event);
        }
        
        public function hasEventListener(type:String):Boolean
        {
            return m_loader.hasEventListener(type);
        }
        
        public function willTrigger(type:String):Boolean
        {
            return m_loader.willTrigger(type);
        }
        
        public function get loader():EventDispatcher
        {
            return m_loader;
        }
        
        public function set loader(value:EventDispatcher):void
        {
            if (value is LoaderInfo || value is URLLoader)
                m_loader = value;
            else
                throw new ArgumentError("Only LoaderInfo or URLLoader is accepted.");
        }
        
        private var m_loader:EventDispatcher;
    }
}
