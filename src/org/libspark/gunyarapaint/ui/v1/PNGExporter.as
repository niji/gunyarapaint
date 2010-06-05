package org.libspark.gunyarapaint.ui.v1
{
    import com.adobe.images.PNGEncoder;
    
    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.net.FileReference;
    import flash.utils.ByteArray;
    
    import mx.controls.Alert;

    public final class PNGExporter extends EventDispatcher
    {
        public function save(bitmapData:BitmapData):void
        {
            if (m_file == null) {
                var name:String = (new Date()).getTime() + ".png";
                var data:ByteArray = PNGEncoder.encode(bitmapData);
                var file:FileReference = new FileReference();
                file.addEventListener(Event.CANCEL, onExportCancel);
                file.addEventListener(Event.COMPLETE, onExportComplete);
                file.save(data, name);
                m_file = file;
            }
        }
        
        private function onExportCancel(event:Event):void
        {
            dispose();
        }
        
        private function onExportComplete(event:Event):void
        {
            dispose();
            dispatchEvent(new Event(Event.COMPLETE));
        }
        
        private function dispose():void
        {
            m_file.removeEventListener(Event.CANCEL, onExportCancel);
            m_file.removeEventListener(Event.COMPLETE, onExportComplete);
            m_file = null;
        }
        
        private var m_file:FileReference;
    }
}
