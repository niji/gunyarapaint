package org.libspark.gunyarapaint.ui.v1
{
    import flash.display.BitmapData;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import flash.utils.Endian;
    
    import org.libspark.gunyarapaint.framework.LayerBitmapCollection;
    import org.libspark.gunyarapaint.framework.UndoStack;
    
    /**
     * ふっかつのじゅもんのデータとして保存するクラス.
     * 
     * <p>以下のフォーマットに基づいて zlib 形式で圧縮して保存されます。</p>
     * <pre>
     * 1:uint          version
     * n:ByteArray     logData
     * n:Rectangle     rectangle
     * n:Vector.<uint> pixelData
     * n:Object        metadata
     * n:Object        undoData
     * n:Object        controllerData
     * </pre>
     */
    public final class ApplicationData
    {
        /**
         * ログのバージョン番号
         */
        public static const VERSION:uint = 1;
        
        public function ApplicationData(layers:LayerBitmapCollection,
                                        undoStack:UndoStack,
                                        controllers:Vector.<IController>)
        {
            m_layers = layers;
            m_undoStack = undoStack;
            m_controllers = controllers;
        }
        
        /**
         * ふっかつのじゅもんを保存します
         * 
         * @param bytes お絵描きログ
         * @param toBytes 保存先となる ByteArray
         */
        public function load(bytes:ByteArray, toBytes:ByteArray):void
        {
            bytes.position = 0;
            bytes.endian = Endian.BIG_ENDIAN;
            bytes.inflate();
            var version:uint = bytes.readUnsignedByte();
            var dataBytes:ByteArray = ByteArray(bytes.readObject());
            var rect:Object = bytes.readObject();
            var pixels:Vector.<uint> = Vector.<uint>(bytes.readObject());
            var metadata:Object = bytes.readObject();
            var undoData:Object = bytes.readObject();
            var controllerData:Object = bytes.readObject();
            var w:uint = rect.width;
            var h:uint = rect.height;
            var bitmapData:BitmapData = new BitmapData(w, h, true, 0x0);
            bitmapData.setVector(new Rectangle(0, 0, w, h), pixels);
            dataBytes.readBytes(toBytes);
            m_layers.load(bitmapData, metadata);
            m_undoStack.load(undoData);
            toBytes.position = toBytes.length;
            var count:uint = m_controllers.length;
            for (var i:uint = 0; i < count; i++) {
                var controller:IController = m_controllers[i];
                var value:Object = controllerData[controller.name];
                controller.load(value);
            }
        }
        
        /**
         * ふっかつのじゅもんを復元します
         * 
         * @param bytes お絵描きログ
         * @param fromoBytes 保存元となる ByteArray
         */
        public function save(bytes:ByteArray, fromBytes:ByteArray):void
        {
            var bitmapData:BitmapData = m_layers.newLayerBitmapData;
            var metadata:Object = {};
            var undoData:Object = {};
            var rect:Rectangle = bitmapData.rect;
            m_layers.save(bitmapData, metadata);
            m_undoStack.save(undoData);
            bytes.endian = Endian.BIG_ENDIAN;
            bytes.writeByte(VERSION);
            bytes.writeObject(fromBytes);
            bytes.writeObject(rect);
            bytes.writeObject(bitmapData.getVector(rect));
            bytes.writeObject(metadata);
            bytes.writeObject(undoData);
            var controllerData:Object = {};
            var count:uint = m_controllers.length;
            for (var i:uint = 0; i < count; i++) {
                var value:Object = {};
                var controller:IController = m_controllers[i];
                controller.save(value);
                controllerData[controller.name] = value;
            }
            bytes.writeObject(controllerData);
            bytes.deflate();
            bytes.position = 0;
        }
        
        private var m_layers:LayerBitmapCollection;
        private var m_undoStack:UndoStack;
        private var m_controllers:Vector.<IController>;
    }
}
