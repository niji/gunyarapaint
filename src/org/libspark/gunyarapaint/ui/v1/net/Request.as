package org.libspark.gunyarapaint.ui.v1.net
{
    import flash.events.Event;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.navigateToURL;
    
    import org.libspark.gunyarapaint.framework.net.IParameters;
    import org.libspark.gunyarapaint.framework.net.IRequest;
    
    public final class Request extends URLLoader implements IRequest
    {
        public function Request()
        {
            dataFormat = URLLoaderDataFormat.BINARY;
        }
        
        public function post(url:String, parameters:IParameters):void
        {
            var request:URLRequest = new URLRequest(url);
            request.method = URLRequestMethod.POST;
            request.contentType = "application/x-nicopedia-oekaki";
            request.data = parameters.serialize();
            load(request);
        }
        
        public function redirect(url:String):void
        {
            var request:URLRequest = new URLRequest();
            request.url = url;
            request.method = URLRequestMethod.GET;
            navigateToURL(request, "_top");
        }
    }
}
