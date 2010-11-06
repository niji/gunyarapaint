package com.github.niji.gunyarapaint.ui.module
{
    import flash.geom.Point;
    
    import com.github.niji.framework.Recorder;
    import com.github.niji.framework.modules.CanvasModule;
    import com.github.niji.framework.modules.ICanvasModule;
    import com.github.niji.gunyarapaint.ui.v1.CanvasController;
    
    public final class MovableCanvasModule extends CanvasModule implements ICanvasModule
    {
        public static const MOVABLE_CANVAS:String = Constant.NAMESPACE + "movableCanvas";
        
        public function MovableCanvasModule(recorder:Recorder, canvas:CanvasController)
        {
            super(recorder);
            m_canvas = canvas;
        }
        
        public function start(x:Number, y:Number):void
        {
             m_scrollPosition = m_canvas.canvasScrollPosition;
             setCoordinate(x, y);
        }
        
        public function move(x:Number, y:Number):void
        {
            moveCanvas(x, y);
        }
        
        public function stop(x:Number, y:Number):void
        {
            saveCoordinate(x, y);
        }
        
        public function interrupt(x:Number, y:Number):void
        {
            moveCanvas(x, y);
        }
        
        public function wheel(x:Number, y:Number, delta:int):void
        {
            // チルト操作には対応していない。ショートカットキーで対応する?
            y ||= m_canvas.canvasScrollPosition.y;
            var toY:Number = y + delta * m_canvas.canvasScale;
            start(x, y);
            move(x, toY);
            stop(x, toY);
        }
        
        public function get name():String
        {
            return MOVABLE_CANVAS;
        }
        
        private function moveCanvas(x:Number, y:Number):void
        {
            var scale:Number = m_canvas.scaleX;
            if (scale < 1)
                scale = 1.0 / (-scale + 2);
            var x:Number = m_scrollPosition.x + (coordinateX - x) * scale;
            var y:Number = m_scrollPosition.y + (coordinateY - y) * scale;
            m_canvas.scroll(x, y);
        }
        
        private var m_canvas:CanvasController;
        private var m_scrollPosition:Point;
    }
}