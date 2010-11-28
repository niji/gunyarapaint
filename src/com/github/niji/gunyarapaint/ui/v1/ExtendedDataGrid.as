package com.github.niji.gunyarapaint.ui.v1
{
    import mx.controls.DataGrid;
    
    public class ExtendedDataGrid extends DataGrid
    {
        public function ExtendedDataGrid()
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
