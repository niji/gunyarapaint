package com.github.niji.gunyarapaint.ui.v1.controllers
{
    import com.github.niji.gunyarapaint.ui.v1.views.DataSaveView;
    
    import flash.display.Sprite;
    import flash.net.SharedObject;
    import flash.net.SharedObjectFlushStatus;
    import flash.system.System;
    import flash.utils.ByteArray;
    
    import mx.controls.Alert;
    import mx.core.Application;
    import mx.core.IFlexDisplayObject;
    import mx.core.IMXMLObject;
    import mx.events.CloseEvent;
    import mx.managers.PopUpManager;
    import mx.utils.SHA256;
    
    public class DataSaveViewController implements IMXMLObject
    {
        public const PASSWORD_SEED_COUNT:uint = 5;
        
        public function initialized(document:Object, id:String):void
        {
            var keyBytes:ByteArray = new ByteArray();
            m_app = Application.application.controller;
            m_parent = DataSaveView(document);
            m_so = SharedObject.getLocal(m_app.hashForSharedObject);
            for (var i:uint = 0; i < PASSWORD_SEED_COUNT; i++) {
                keyBytes.writeDouble(Math.random());
                keyBytes.writeDouble(new Date().getMilliseconds());
                keyBytes.writeUTFBytes(SHA256.computeDigest(keyBytes));
            }
            m_password = SHA256.computeDigest(keyBytes);
        }
        
        public function confirm(callback:Function):void
        {
            if (m_so.size > 0) {
                Alert.show(_("Are you sure to save previous data?"),
                    m_parent.title, Alert.YES | Alert.NO, Sprite(m_app.parentView),
                    callback, null, Alert.YES | Alert.NO);
            }
            else {
                callback(new CloseEvent(CloseEvent.CLOSE, false, false, Alert.YES));
            }
        }
        
        public function trySave():Boolean
        {
            try {
                var bytes:ByteArray = new ByteArray();
                m_app.save(bytes, generatedPassword);
                m_so.data.bytes = bytes;
                return m_so.flush(m_so.size) == SharedObjectFlushStatus.FLUSHED;
            }
            catch (e:Error) {
                m_app.showAlert(e.message, m_parent.title);
            }
            return false;
        }
        
        public function handleOnClose():void
        {
            PopUpManager.removePopUp(m_parent);
        }
        
        public function handleOnClick(password:String):void
        {
            System.setClipboard(password);
        }
        
        public function get parentView():IFlexDisplayObject
        {
            return m_parent;
        }
        
        public function get generatedPassword():String
        {
            return m_password;
        }
        
        private var m_app:RootViewController;
        private var m_parent:DataSaveView;
        private var m_so:SharedObject;
        private var m_password:String;
    }
}
