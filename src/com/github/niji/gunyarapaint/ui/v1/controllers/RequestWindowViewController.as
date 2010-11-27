package com.github.niji.gunyarapaint.ui.v1.controllers
{
    
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.SharedObject;
    import flash.net.URLLoader;
    
    import mx.core.IMXMLObject;
    import mx.managers.PopUpManager;
    import com.github.niji.gunyarapaint.ui.v1.net.Parameters;
    import com.github.niji.gunyarapaint.ui.v1.net.Request;
    import com.github.niji.gunyarapaint.ui.v1.views.RequestWindowView;
    
    public class RequestWindowViewController implements IMXMLObject
    {
        public function initialized(document:Object, id:String):void
        {
            m_parent = RequestWindowView(document);
        }
        
        public function post(parameters:Parameters, app:RootViewController):void
        {
            var request:Request = new Request();
            request.addEventListener(ProgressEvent.PROGRESS, onProgress);
            request.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
            request.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
            request.addEventListener(Event.COMPLETE, onComplete);
            m_app = app;
            m_request = request;
            try {
                request.post(app.getParameter("postUrl"), parameters);
            }
            catch (e:Error) {
                removeEvents();
                throw e;
            }
        }
        
        public function handleCancel():void
        {
            URLLoader(m_request.loader).close();
            removeEvents();
            m_app.showAlert(_("Requested post has been canceled, but the post will not be able to rollback."), m_parent.title);
        }
        
        private function onProgress(event:ProgressEvent):void
        {
            m_parent.progressBar.setProgress(event.bytesLoaded, event.bytesTotal);
        }
        
        private function onComplete(event:Event):void
        {
            try {
                var data:String = String(URLLoader(m_request.loader).data);
                if (data != "") {
                    m_app.showAlert(data, m_parent.title);
                }
                else {
                    var so:SharedObject = SharedObject.getLocal(m_app.hashForSharedObject);
                    if (so != null)
                        so.clear();
                    m_app.shouldAlertOnUnload = false;
                    Request.redirect(m_app.getParameter("redirectUrl"));
                }
            }
            catch (e:Error) {
                m_app.showAlert(_("Failed your post for something wrong. Try again."), m_parent.title);
            }
            finally {
                removeEvents();
            }
        }
        
        private function onIOError(event:IOErrorEvent):void
        {
            removeEvents();
            m_app.showAlert(_("IO error has occured. Try again: %s", event.text), m_parent.title);
        }
        
        private function onSecurityError(event:SecurityErrorEvent):void
        {
            removeEvents();
            m_app.showAlert(_("Security error has occured. This error should not be occured: %s", event.text), m_parent.title);
        }
        
        private function removeEvents():void
        {
            m_request.removeEventListener(ProgressEvent.PROGRESS, onProgress);
            m_request.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
            m_request.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
            m_request.removeEventListener(Event.COMPLETE, onComplete);
            PopUpManager.removePopUp(m_parent);
        }
        
        private var m_parent:RequestWindowView;
        private var m_app:RootViewController;
        private var m_request:Request;
    }
}
