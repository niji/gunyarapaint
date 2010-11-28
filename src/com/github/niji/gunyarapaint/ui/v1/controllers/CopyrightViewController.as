package com.github.niji.gunyarapaint.ui.v1.controllers
{
    import mx.core.IMXMLObject;
    import mx.managers.PopUpManager;
    
    public class CopyrightViewController implements IMXMLObject
    {
        public function initialized(document:Object, id:String):void
        {
            view = IFlexDisplayObject(document);
        }
        
        public function handleOnClose():void
        {
            PopUpManager.removePopUp(view);
        }
        
        private var view:IFlexDisplayObject;
    }
}
