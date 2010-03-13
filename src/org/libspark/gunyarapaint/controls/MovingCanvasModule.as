package org.libspark.gunyarapaint.controls
{
    import flash.geom.Point;
    
    import org.libspark.gunyarapaint.framework.Recorder;
    import org.libspark.gunyarapaint.framework.modules.CanvasModule;
    import org.libspark.gunyarapaint.framework.modules.ICanvasModule;
    
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
             m_scrollPosition = m_canvas.canvasScrollPosition;
             setCoordinate(x, y);
        }
        
        public function move(x:Number, y:Number):void
        {
            var scale:Number = m_canvas.scaleX;
            if (scale < 1)
                scale = 1.0 / (-scale + 2);
            var x:Number = m_scrollPosition.x + (coordinateX - x) * scale;
            var y:Number = m_scrollPosition.y + (coordinateY - y) * scale;
            m_canvas.scroll(x, y);
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
        private var m_scrollPosition:Point;
    }
}