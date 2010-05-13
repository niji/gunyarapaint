package org.libspark.gunyarapaint.ui.v1.net
{
    import com.adobe.serialization.json.JSON;
    
    import flash.net.URLVariables;
    import flash.utils.ByteArray;
    
    import org.libspark.gunyarapaint.framework.net.IParameters;

    public final class Parameters implements IParameters
    {
        public var magic:String;
        
        public var cookie:String;
        
        public var name:String;
        
        public var title:String;
        
        public var message:String;
        
        public var shouldAddWatchList:Boolean;
        
        public var refererId:uint;
        
        public var imageBytes:ByteArray;
        
        public var layerImageBytes:ByteArray;
        
        public var logBytes:ByteArray;
        
        public var metadata:Object;
        
        public function serialize():ByteArray
        {
            if (!title)
                throw new ArgumentError(_("The title is empty."));
            if (!message)
                throw new ArgumentError(_("The message is empty."));
            var vars:URLVariables = new URLVariables();
            var bytes:ByteArray = new ByteArray();
            var data:ByteArray = new ByteArray();
            var info:ByteArray = new ByteArray();
            info.writeUTFBytes(JSON.encode(metadata));
            vars.cookie = cookie;
            vars.magic = magic;
            vars.FROM = name;
            vars.title = title;
            vars.MESSAGE = message;
            vars.watchlist = shouldAddWatchList ? "t" : "";
            vars.ref_oekaki_id = refererId;
            vars.log_count = metadata.log_count;
            var encoded:String = vars.toString();
            bytes.writeUTFBytes(":" + encoded.length + "=" + encoded);
            bytes.writeUTFBytes("&IMAGE:" + imageBytes.length + "=");
            bytes.writeBytes(imageBytes);
            bytes.writeUTFBytes("&IMAGE_LOG:" + logBytes.length + "=");
            bytes.writeBytes(logBytes);
            bytes.writeUTFBytes("&IMAGE_LAYERS:" + layerImageBytes.length + "=");
            bytes.writeBytes(layerImageBytes);
            bytes.writeUTFBytes("&IMAGE_INFO:" + data.length);
            bytes.writeBytes(info);
            return bytes;
        }
    }
}
