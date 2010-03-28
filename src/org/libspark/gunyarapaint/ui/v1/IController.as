package org.libspark.gunyarapaint.ui.v1
{
    import flash.utils.ByteArray;
    
    import org.libspark.gunyarapaint.framework.ui.IApplication;

    public interface IController
    {
        function init(app:IApplication):void
        function load(data:Object):void;
        function save(data:Object):void;
        function resetWindow():void;
        function get name():String;
    }
}
