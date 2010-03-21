package org.libspark.gunyarapaint.ui.v1
{
    import flash.events.Event;
    import flash.events.MouseEvent;
    
    import mx.controls.CheckBox;
    import mx.controls.dataGridClasses.DataGridListData;
    import mx.events.FlexEvent;
    
    public class CheckBoxEditor extends CheckBox
    {
        private var m_ownerData:Object;
        private var m_text:String;
        
        override public function set data(value:Object):void
        {
            m_ownerData = value;
            if (m_ownerData) {
                var col:DataGridListData = DataGridListData(listData);
                selected = m_ownerData[col.dataField];
                updateCheckText();
                dispatchEvent(new FlexEvent(FlexEvent.DATA_CHANGE));
            }
        }
        
        override public function get data():Object
        {
            return m_ownerData;
        }
        
        public function set text(value:String):void
        {
            // pass
        }
        
        public function get text():String
        {
            return m_text;
        }
        
        override protected function clickHandler(event:MouseEvent):void
        {
            super.clickHandler(event);
            var col:DataGridListData = DataGridListData(listData);
            m_ownerData[col.dataField] = selected;
            var toggleEvent:Event = new Event("describeChange");
            owner.dispatchEvent(toggleEvent);
            updateCheckText();
        }
        
        private function updateCheckText():void
        {
            m_text = selected ? 'on' : 'off';
        }
    }
}
