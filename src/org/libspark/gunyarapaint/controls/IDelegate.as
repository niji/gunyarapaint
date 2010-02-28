package org.libspark.gunyarapaint.controls
{
    import org.libspark.gunyarapaint.framework.Recorder;
    import org.libspark.gunyarapaint.framework.modules.IDrawable;

    public interface IDelegate
    {
        function get recorder():Recorder;
        function get module():IDrawable;
        function get supportedBlendModes():Array;
        function set module(value:IDrawable):void;
    }
}
