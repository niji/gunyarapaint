package org.libspark.gunyarapaint.ui.v1
{
    import flash.utils.ByteArray;

    public interface IController
    {
        function load(data:Object):void;
        function save(data:Object):void;
        function resetWindow():void;
        function get name():String;
    }
}
