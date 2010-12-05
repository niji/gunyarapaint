package com.github.niji.gunyarapaint.ui.v1.controllers
{
    import com.github.niji.gunyarapaint.ui.errors.DecryptError;
    import com.github.niji.gunyarapaint.ui.v1.views.DataLoadView;
    
    import flash.errors.IOError;
    import flash.net.SharedObject;
    
    import mx.core.Application;
    import mx.core.IMXMLObject;
    import mx.managers.PopUpManager;
    
    public class DataLoadViewController implements IMXMLObject
    {
        public function initialized(document:Object, id:String):void
        {
            m_parent = DataLoadView(document);
        }
        
        public function load(password:String):void
        {
            var root:RootViewController = Application.application.controller;
            try {
                var so:SharedObject = SharedObject.getLocal(root.hashForSharedObject);
                root.load(so.data.bytes, password);
                handleOnClose();
            }
            catch (e:DecryptError) {
                root.showAlert(_("Input password is incorrect."), m_parent.title);
            }
            catch (e:IOError) {
                root.showAlert(_("Loaded file is invalid saved data."), m_parent.title);
                handleOnClose();
            }
            catch (e:Error) {
                root.showAlert(e.message, m_parent.title);
                handleOnClose();
            }
        }
        
        public function handleOnClose():void
        {
            PopUpManager.removePopUp(m_parent);
        }
        
        public function handleOnClick(password:String):void
        {
            load(password);
        }
        
        private var m_parent:DataLoadView;
    }
}
