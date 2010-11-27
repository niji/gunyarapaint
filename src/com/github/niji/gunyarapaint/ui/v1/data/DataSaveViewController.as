package com.github.niji.gunyarapaint.ui.v1.data
{
    import flash.net.SharedObject;
    import flash.net.SharedObjectFlushStatus;
    import flash.system.System;
    import flash.utils.ByteArray;
    
    import mx.core.Application;
    import mx.core.IFlexDisplayObject;
    import mx.core.IMXMLObject;
    import mx.managers.PopUpManager;
    import mx.utils.SHA256;
    
    public class DataSaveViewController implements IMXMLObject
    {
        public function initialized(document:Object, id:String):void
        {
            m_parent = IFlexDisplayObject(document);
        }
        
        public function trySave(password:String):Boolean
        {
            var bytes:ByteArray = new ByteArray();
            var so:SharedObject = null;
            Application.application.save(bytes, password);
            so = SharedObject.getLocal(Application.application.hashForSharedObject);
            so.data.bytes = bytes;
            return so.flush(so.size) == SharedObjectFlushStatus.FLUSHED;
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
        
        private var m_parent:IFlexDisplayObject;
        private var m_password:String;
    }
}
