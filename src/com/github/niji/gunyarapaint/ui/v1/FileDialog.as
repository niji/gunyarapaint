package com.github.niji.gunyarapaint.ui.v1
{
    import com.github.niji.gunyarapaint.ui.v1.controllers.RootViewController;
    
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.FileReference;
    import flash.utils.ByteArray;
    
    import mx.core.Application;

    public final class FileDialog extends EventDispatcher
    {
        public function FileDialog(title:String)
        {
            m_app = Application.application.controller;
            m_title = title;
        }
        
        public function openToSave(bytes:ByteArray):void
        {
            createFileReferenceEvents();
            m_file.addEventListener(Event.COMPLETE, onSaveComplete);
            m_file.save(bytes);
        }
        
        public function openToLoad():void
        {
            createFileReferenceEvents();
            m_file.addEventListener(Event.SELECT, onSelectLoad);
            m_file.addEventListener(Event.COMPLETE, onLoadComplete);
            m_file.browse();
        }
        
        private function onSelectLoad(event:Event):void
        {
            var file:FileReference = FileReference(event.target);
            file.load();
        }
        
        private function onLoadComplete(event:Event):void
        {
            var file:FileReference = FileReference(event.target);
            var bytes:ByteArray = file.data;
            // m_app.load(bytes);
            removeFileReference();
        }
        
        private function onSaveComplete(event:Event):void
        {
            m_app.showAlert(_("Saving data to the file has been completed."), m_title);
            removeFileReference();
        }
        
        private function onCancel(event:Event):void
        {
            removeFileReference();
        }
        
        private function onError(event:ErrorEvent):void
        {
            m_app.showAlert(event.text, m_title);
            removeFileReference();
        }
        
        private function createFileReferenceEvents():void
        {
            m_file = new FileReference();
            m_file.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
            m_file.addEventListener(IOErrorEvent.IO_ERROR, onError);
            m_file.addEventListener(Event.CANCEL, onCancel);
        }
        
        private function removeFileReference():void
        {
            m_file.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
            m_file.removeEventListener(IOErrorEvent.IO_ERROR, onError);
            m_file.removeEventListener(Event.CANCEL, onCancel);
            m_file.removeEventListener(Event.SELECT, onSelectLoad);
            m_file.removeEventListener(Event.COMPLETE, onLoadComplete);
            m_file.removeEventListener(Event.COMPLETE, onSaveComplete);
            m_file = null;
            if (hasEventListener(Event.COMPLETE))
                dispatchEvent(new Event(Event.COMPLETE));
        }
        
        private var m_app:RootViewController;
        private var m_title:String;
        // FileReferenceの参照を確実に持つ必要があるため、クラス属性として定義している
        // そうしないとダイアログを開いた後 Event.COMPLETEのイベントが呼ばれなくなる
        private var m_file:FileReference;
    }
}