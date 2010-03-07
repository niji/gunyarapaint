package org.libspark.gunyarapaint.controls
{
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    
    import mx.controls.Alert;
    import mx.core.UIComponent;
    
    import org.libspark.gunyarapaint.framework.AuxLineView;
    import org.libspark.gunyarapaint.framework.AuxPixelView;
    import org.libspark.gunyarapaint.framework.TransparentBitmap;
    import org.libspark.gunyarapaint.framework.ui.IApplication;
    
    internal class GPCanvas extends UIComponent
    {
        public function GPCanvas(application:IApplication)
        {
            var rect:Rectangle = new Rectangle(0, 0, application.canvasWidth, application.canvasHeight);
            var transparent:TransparentBitmap = new TransparentBitmap(rect);
            m_auxLine = new AuxLineView(rect);
            m_auxPixel = new AuxPixelView(rect);
            m_application = application;
            m_auxLine.visible = true;
            m_auxPixel.visible = false;
            
            addChild(transparent);
            addChild(application.canvasView);
            addChild(m_auxLine);
            addChild(m_auxPixel);
            addEventListener(Event.REMOVED, onRemove);
            addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
            addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            
            super();
        }
        
        public function updateAuxViews():void
        {
            m_auxLine.update();
            m_auxPixel.update();
        }
        
        public function set auxBoxVisible(value:Boolean):void
        {
            m_auxLine.boxVisible = m_auxPixel.boxVisible = value;
        }
        
        public function set auxSkewVisible(value:Boolean):void
        {
            m_auxLine.skewVisible = m_auxPixel.skewVisible = value;
        }
        
        public function set auxDivideCount(value:uint):void
        {
            m_auxLine.divideCount = m_auxPixel.divideCount = value;
        }
        
        public function set auxLineAlpha(value:Number):void
        {
            m_auxLine.lineAlpha = m_auxPixel.lineAlpha = value;
        }
        
        public function set auxLineColor(value:uint):void
        {
            m_auxLine.lineColor = m_auxPixel.lineColor = value;
        }
        
        public function set enableAuxPixel(value:Boolean):void
        {
            m_auxLine.visible = value ? false : true;
            m_auxPixel.visible = value ? true : false;
        }
        
        private function onRemove(event:Event):void
        {
            removeMouseEvents(m_application.canvasView);
            removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
            removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            removeEventListener(Event.REMOVED, onRemove);
        }
        
        private function onMouseDown(event:MouseEvent):void
        {
            var cv:Sprite = m_application.canvasView;
            try {
                m_application.module.start(event.localX, event.localY);
                cv.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
                cv.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
            } catch (e:Error) {
                removeMouseEvents(cv);
                Alert.show(e.message, e.name);
            }
        }
        
        private function onMouseMove(event:MouseEvent):void
        {
            m_application.module.move(event.localX, event.localY);
        }
        
        private function onMouseUp(event:MouseEvent):void
        {
            removeMouseEvents(m_application.canvasView);
            m_application.module.stop(event.localX, event.localY);
        }
        
        private function onMouseOut(event:MouseEvent):void
        {
            removeMouseEvents(m_application.canvasView);
            m_application.module.interrupt(event.localX, event.localY);
        }
        
        private function removeMouseEvents(cv:Sprite):void
        {
            cv.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            cv.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
        }
        
        private var m_auxLine:AuxLineView;
        private var m_auxPixel:AuxPixelView;
        private var m_application:IApplication;
    }
}
