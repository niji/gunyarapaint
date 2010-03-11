package org.libspark.gunyarapaint.controls
{
    import org.libspark.gunyarapaint.framework.Recorder;
    import org.libspark.gunyarapaint.framework.modules.ICanvasModule;
    import org.libspark.gunyarapaint.framework.modules.CanvasModule;
    
    public final class MovingCanvasModule extends CanvasModule implements ICanvasModule
    {
        public static const MOVING_CANVAS:String = "movingCanvas";
        
        public function MovingCanvasModule(recorder:Recorder, canvas:GPCanvasWindowControl)
        {
            m_canvas = canvas;
            super(recorder);
        }
        
        public function start(x:Number, y:Number):void
        {
        }
        
        public function move(x:Number, y:Number):void
        {
        }
        
        public function stop(x:Number, y:Number):void
        {
        }
        
        public function interrupt(x:Number, y:Number):void
        {
        }
        
        public function get name():String
        {
            return MOVING_CANVAS;
        }
        
        private var m_canvas:GPCanvasWindowControl;
    }
}