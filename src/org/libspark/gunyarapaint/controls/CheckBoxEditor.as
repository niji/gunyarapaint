package org.libspark.gunyarapaint.controls
{
    import mx.controls.CheckBox;
    import mx.events.FlexEvent;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import mx.controls.dataGridClasses.DataGridListData;
    
    public class CheckBoxEditor extends CheckBox
    {
        private var _ownerData:Object;
        private var _text:String;
        
        override public function set data(value:Object):void
        {
            _ownerData = value;
            if (_ownerData) {
                var col:DataGridListData = DataGridListData(listData);
                selected = (_ownerData[col.dataField] == 'on');
                
                updateCheckText();
                dispatchEvent(new FlexEvent(FlexEvent.DATA_CHANGE));
            }
        }
        
        override public function get data():Object
        {
            return _ownerData;
        }
        
        public function set text(value:String):void
        {
            // pass
        }
        
        public function get text():String
        {
            return _text;
        }
        
        override protected function clickHandler(event:MouseEvent):void
        {
            super.clickHandler(event);
            var col:DataGridListData = DataGridListData(listData);
            _ownerData[col.dataField] = selected ? 'on' : 'off';
            var toggleEvent:Event = new Event("describeChange");
            owner.dispatchEvent(toggleEvent);
            updateCheckText();
        }
        
        private function updateCheckText():void
        {
            _text = selected ? 'on' : 'off';
        }
    }
}
