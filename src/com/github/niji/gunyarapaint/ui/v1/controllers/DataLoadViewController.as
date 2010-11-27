package com.github.niji.gunyarapaint.ui.v1.controllers
{
    import com.github.niji.gunyarapaint.ui.errors.DecryptError;
    
    import flash.errors.IOError;
    import flash.net.SharedObject;
    
    import mx.core.Application;
    import mx.core.IFlexDisplayObject;
    import mx.core.IMXMLObject;
    import mx.managers.PopUpManager;
    
    public class DataLoadViewController implements IMXMLObject
    {
        public function initialized(document:Object, id:String):void
        {
            m_parent = IFlexDisplayObject(document);
        }
        
        public function load(password:String):void
        {
            var root:RootViewController = Application.application.controller;
            var title:String = _("");
            try {
                var so:SharedObject = SharedObject.getLocal(root.hashForSharedObject);
                root.load(so.data.bytes, password);
            }
            catch (e:DecryptError) {
                root.showAlert(_("Input password is incorrect"), title);
            }
            catch (e:IOError) {
                root.showAlert(_("Loaded file is invalid saved data"), title);
            }
            catch (e:Error) {
                root.showAlert(e.message, title);
            }
            handleOnClose();
        }
        
        public function handleOnClose():void
        {
            PopUpManager.removePopUp(m_parent);
        }
        
        public function handleOnClick(password:String):void
        {
            load(password);
        }
        
        private var m_parent:IFlexDisplayObject;
    }
}
