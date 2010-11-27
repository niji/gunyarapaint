package com.github.niji.gunyarapaint.ui.v1.data
{
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
