package com.github.niji.gunyarapaint.ui.events
{
    import flash.events.Event;
    
    public final class CheckBoxEditorEvent extends Event
    {
        public static const DATA_CHANGED:String = "dataChanged";
        
        public function CheckBoxEditorEvent(type:String, data:Object, column:String)
        {
            m_data = data;
            m_column = column;
            super(type, false, false);
        }
        
        public function get data():Object
        {
            return m_data;
        }
        
        public function get column():String
        {
            return m_column;
        }
        
        private var m_data:Object;
        
        private var m_column:String;
    }
}
