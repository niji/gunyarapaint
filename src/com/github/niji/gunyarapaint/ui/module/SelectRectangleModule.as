package com.github.niji.gunyarapaint.ui.module
{
    import com.github.niji.framework.Recorder;
    import com.github.niji.framework.modules.CanvasModule;
    import com.github.niji.framework.modules.ICanvasModule;
    import com.github.niji.gunyarapaint.ui.thirdparty.DashLine;
    import com.github.niji.gunyarapaint.ui.v1.CanvasController;
    
    import flash.display.CapsStyle;
    import flash.display.Graphics;
    import flash.display.LineScaleMode;
    import flash.display.Shape;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    public final class SelectRectangleModule extends CanvasModule implements ICanvasModule
    {
        public static const SELECT_RECTANGLE:String = Constant.NAMESPACE + "selectRectangle";
        
        public function SelectRectangleModule(recorder:Recorder, canvas:CanvasController)
        {
            super(recorder);
            m_canvas = canvas;
            m_rect = new Rectangle();
        }
        
        /**
         * @inheritDoc
         */
        public override function load():void
        {
            var shape:Shape = m_canvas.selectShape;
            m_offset = 0;
            m_drag = new Point();
            m_topLeft = null;
            shape.graphics.clear();
            shape.addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
        
        /**
         * @inheritDoc
         */
        public override function unload():void
        {
            var shape:Shape = m_canvas.selectShape;
            m_offset = 0;
            shape.graphics.clear();
            shape.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
        
        /**
         * @inheritDoc
         */
        public function start(x:Number, y:Number):void
        {
            if (m_rect.contains(x, y)) {
                m_topLeft = m_rect.topLeft.clone();
                m_drag.x = x;
                m_drag.y = y;
            }
            else {
                m_drag.x = 0;
                m_drag.y = 0;
                setCoordinate(x, y);
            }
        }
        
        /**
         * @inheritDoc
         */
        public function move(x:Number, y:Number):void
        {
            draw(x, y);
        }
        
        /**
         * @inheritDoc
         */
        public function stop(x:Number, y:Number):void
        {
            draw(x, y);
        }
        
        /**
         * @inheritDoc
         */
        public function interrupt(x:Number, y:Number):void
        {
            draw(x, y);
        }
        
        /**
         * @inheritDoc
         */
        public function get name():String
        {
            return SELECT_RECTANGLE;
        }
        
        private function draw(x:Number, y:Number):void
        {
            var width:int = 0;
            var height:int = 0;
            var offsetX:int = 0;
            var offsetY:int = 0;
            if (m_drag.x != 0 || m_drag.y != 0) {
                offsetX = m_topLeft.x - (m_drag.x - x);
                offsetY = m_topLeft.y - (m_drag.y - y);
                width = m_rect.width;
                height = m_rect.height;
                m_rect = new Rectangle(offsetX, offsetY, width, height);
            }
            else {
                offsetX = coordinateX;
                offsetY = coordinateY;
                width = Math.floor(x - offsetX);
                height = Math.floor(y - offsetY);
                if (width >= 0 && height >= 0)
                    m_rect = new Rectangle(offsetX, offsetY, width, height);
                else if (width >= 0)
                    m_rect = new Rectangle(offsetX, y, width, -height);
                else if (height >= 0)
                    m_rect = new Rectangle(x, offsetY, -width, height);
                else
                    m_rect = new Rectangle(x, y, -width, -height);
            }
        }
        
        private function onEnterFrame(event:Event):void
        {
            var g:Graphics = m_canvas.selectShape.graphics;
            var dashline:DashLine = new DashLine(g, 5);
            m_offset += 2;
            m_offset %= 10;
            g.clear();
            if (!m_rect.isEmpty()) {
                var width:int = m_rect.width;
                var height:int = m_rect.height;
                g.lineStyle(1.0, 0.0, 1.0, true, LineScaleMode.NORMAL, CapsStyle.NONE);
                dashline.moveTo(m_rect.left, m_rect.top, m_offset);
                dashline.lineTo(m_rect.right, m_rect.top);
                dashline.lineTo(m_rect.right, m_rect.bottom);
                dashline.lineTo(m_rect.left, m_rect.bottom);
                dashline.lineTo(m_rect.left, m_rect.top);
            }
        }
        
        private var m_canvas:CanvasController;
        private var m_drag:Point;
        private var m_topLeft:Point;
        private var m_rect:Rectangle;
        private var m_offset:uint = 0;
    }
}