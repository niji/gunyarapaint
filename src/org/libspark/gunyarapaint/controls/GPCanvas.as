package org.libspark.gunyarapaint.controls
{
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    
    import mx.controls.Alert;
    import mx.core.UIComponent;
    
    import org.libspark.gunyarapaint.framework.AuxLineView;
    import org.libspark.gunyarapaint.framework.AuxPixelView;
    import org.libspark.gunyarapaint.framework.TransparentBitmap;
    
    internal class GPCanvas extends UIComponent
    {
        private var m_auxLine:AuxLineView;
        private var m_auxPixel:AuxPixelView;
        private var m_delegate:IDelegate;
        
        public function GPCanvas(delegate:IDelegate)
        {
            var rect:Rectangle = new Rectangle(0, 0, delegate.canvasWidth, delegate.canvasHeight);
            var transparent:TransparentBitmap = new TransparentBitmap(rect);
            m_auxLine = new AuxLineView(rect);
            m_auxPixel = new AuxPixelView(rect);
            m_delegate = delegate;
            m_auxLine.visible = true;
            m_auxPixel.visible = false;
            
            addChild(transparent);
            addChild(delegate.canvasView);
            addChild(m_auxLine);
            addChild(m_auxPixel);
            
            addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
            addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
            addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
            
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
        
        private function mouseDownHandler(evt:MouseEvent):void
        {
            try {
                m_delegate.module.start(evt.localX, evt.localY);
                m_delegate.canvasView.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
            } catch (e:Error) {
                Alert.show(e.message, e.name);
            }
        }
        
        private function mouseMoveHandler(evt:MouseEvent):void
        {
            m_delegate.module.move(evt.localX, evt.localY);
        }
        
        private function mouseUpHandler(evt:MouseEvent):void
        {
            m_delegate.canvasView.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
            m_delegate.module.stop(evt.localX, evt.localY);
        }
        
        private function mouseOutHandler(evt:MouseEvent):void
        {
            m_delegate.module.interrupt(evt.localX, evt.localY);
        }
    }
}