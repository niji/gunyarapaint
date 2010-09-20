package com.github.niji.gunyarapaint.ui.v1
{
    import com.adobe.images.PNGEncoder;
    
    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.net.FileReference;
    import flash.utils.ByteArray;
    
    /**
     * BitmapData を PNG に変換するクラス.
     * 
     * このクラスは FileReference を内部で呼び出すため、暗黙的にイベントが登録され、
     * ファイルの保存処理が終了すると暗黙的にイベントが解除されます。また、ファイル名は
     * 現在の時間のタイムスタンプに拡張子である png をつけたものになります。
     */
    public final class PNGExporter extends EventDispatcher
    {
        /**
         * BitmapData を PNG に変換し、ファイルダイアログを呼び出します
         * 
         * @param bitmapData 変換対象のビットマップ画像
         */
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
