package org.libspark.gunyarapaint.controls
{
    import flash.display.Sprite;
    
    import org.libspark.gunyarapaint.framework.LayerBitmapCollection;
    import org.libspark.gunyarapaint.framework.Pen;
    import org.libspark.gunyarapaint.framework.modules.IDrawable;

    public interface IDelegate
    {
        function setModule(value:String):void;
        function get module():IDrawable;
        function get layers():LayerBitmapCollection;
        function get pen():Pen;
        function get supportedBlendModes():Array;
        function get canvasWidth():uint;
        function get canvasHeight():uint;
        function get canvasView():Sprite;
    }
}
