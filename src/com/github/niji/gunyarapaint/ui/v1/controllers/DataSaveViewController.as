package com.github.niji.gunyarapaint.ui.v1.controllers
{
    import com.github.niji.gunyarapaint.ui.v1.views.DataSaveView;
    
    import flash.net.SharedObject;
    import flash.net.SharedObjectFlushStatus;
    import flash.system.System;
    import flash.utils.ByteArray;
    
    import mx.core.Application;
    import mx.core.IMXMLObject;
    import mx.managers.PopUpManager;
    import mx.utils.SHA256;
    
    public class DataSaveViewController implements IMXMLObject
    {
        public function initialized(document:Object, id:String):void
        {
            m_parent = DataSaveView(document);
        }
        
        public function trySave():Boolean
        {
            var root:RootViewController = Application.application.controller;
            try {
                var bytes:ByteArray = new ByteArray();
                var so:SharedObject = null;
                root.save(bytes, generatedPassword);
                so = SharedObject.getLocal(root.hashForSharedObject);
                so.data.bytes = bytes;
                return so.flush(so.size) == SharedObjectFlushStatus.FLUSHED;
            }
            catch (e:Error) {
                root.showAlert(e.message, m_parent.title);
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
        
        public function get generatedPassword():String
        {
            if (m_password == null) {
                var bytes:ByteArray = new ByteArray();
                for (var i:uint = 0; i < 5; i++) {
                    bytes.writeDouble(Math.random());
                    bytes.writeUTFBytes(SHA256.computeDigest(bytes));
                }
                m_password = SHA256.computeDigest(bytes);
            }
            return m_password;
        }
        
        private var m_parent:DataSaveView;
        private var m_password:String;
    }
}
