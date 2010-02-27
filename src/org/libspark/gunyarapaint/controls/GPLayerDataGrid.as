package org.libspark.gunyarapaint.controls
{
    import flash.events.MouseEvent;
    
    import mx.controls.DataGrid;
    
    public class GPLayerDataGrid extends DataGrid
    {
        public function GPLayerDataGrid()
        {
            super();
            doubleClickEnabled = true;
        }
        
        override protected function mouseDoubleClickHandler(event:MouseEvent):void
        {
            super.mouseDoubleClickHandler(event);
            super.mouseDownHandler(event);
            super.mouseUpHandler(event);
        }
        
        override protected function mouseUpHandler(event:MouseEvent):void
        {
            var saved:Boolean = editable;
            editable = false;
            super.mouseUpHandler(event);
            editable = saved;
        }
    }
}
