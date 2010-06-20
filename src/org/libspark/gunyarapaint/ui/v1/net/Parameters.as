package org.libspark.gunyarapaint.ui.v1.net
{
    import com.adobe.serialization.json.JSON;
    
    import flash.net.URLVariables;
    import flash.utils.ByteArray;
    
    import org.libspark.gunyarapaint.framework.net.IParameters;
    
    /**
     * ニコニコ大百科のお絵カキコの投稿に必要なパラメータクラス
     */
    public final class Parameters implements IParameters
    {
        /**
         * マジックトークン
         */
        public var magic:String;
        
        /**
         * クッキー
         */
        public var cookie:String;
        
        /**
         * お絵カキコの投稿者名
         */
        public var name:String;
        
        /**
         * お絵カキコのタイトル名
         */
        public var title:String;
        
        /**
         * お絵カキコの本文
         */
        public var message:String;
        
        /**
         * ウォッチリストに登録するかどうか
         */
        public var shouldAddWatchList:Boolean;
        
        /**
         * お絵カキコの参照元となるID
         */
        public var refererId:uint;
        
        /**
         * 描いた画像を ByteArray に変換したオブジェクト
         */
        public var imageBytes:ByteArray;
        
        /**
         * 縦に連結したレイヤー画像を ByteArray に変換したオブジェクト
         */
        public var layerImageBytes:ByteArray;
        
        /**
         * 描いた絵のログオブジェクト
         */
        public var logBytes:ByteArray;
        
        /**
         * 描いた絵のログの記録数
         */
        public var logCount:uint;
        
        /**
         * 描いた絵の付随情報
         */
        public var metadata:Object;
        
        /**
         * @inheritDoc
         */ 
        public function serialize():ByteArray
        {
            if (!title)
                throw new ArgumentError(_("The title is empty."));
            if (!message)
                throw new ArgumentError(_("The message is empty."));
            var vars:URLVariables = new URLVariables();
            var bytes:ByteArray = new ByteArray();
            var info:ByteArray = new ByteArray();
            info.writeUTFBytes(JSON.encode(metadata));
            vars.cookie = cookie;
            vars.magic = magic;
            vars.FROM = name;
            vars.title = title;
            vars.MESSAGE = message;
            vars.watchlist = shouldAddWatchList ? "t" : "";
            vars.ref_oekaki_id = refererId;
            vars.log_count = logCount;
            var encoded:String = vars.toString();
            bytes.writeUTFBytes(":" + encoded.length + "=" + encoded);
            bytes.writeUTFBytes("&IMAGE:" + imageBytes.length + "=");
            bytes.writeBytes(imageBytes);
            bytes.writeUTFBytes("&IMAGE_LOG:" + logBytes.length + "=");
            bytes.writeBytes(logBytes);
            bytes.writeUTFBytes("&IMAGE_LAYERS:" + layerImageBytes.length + "=");
            bytes.writeBytes(layerImageBytes);
            bytes.writeUTFBytes("&IMAGE_INFO:" + info.length + "=");
            bytes.writeBytes(info);
            return bytes;
        }
    }
}
