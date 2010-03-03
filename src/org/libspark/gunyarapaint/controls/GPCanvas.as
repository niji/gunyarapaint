package org.libspark.gunyarapaint.controls
{
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    
    import mx.core.UIComponent;
    
    import org.libspark.gunyarapaint.controls.IDelegate;
    import org.libspark.gunyarapaint.framework.AuxBitmap;
    import org.libspark.gunyarapaint.framework.TransparentBitmap;
    
    internal class GPCanvas extends UIComponent
    {
        private var m_aux:AuxBitmap;
        private var m_delegate:IDelegate;
        
        public function GPCanvas(delegate:IDelegate)
        {
            var rect:Rectangle = new Rectangle(0, 0, delegate.recorder.width, delegate.recorder.height);
            var transparent:TransparentBitmap = new TransparentBitmap(rect);
            m_aux = new AuxBitmap(rect);
            m_delegate = delegate;
            
            addChild(transparent);
            addChild(delegate.recorder.painter.view);
            addChild(m_aux);
            
            addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
            addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
            addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
            
            super();
        }
        
        public function get auxBitmap():AuxBitmap
        {
            return m_aux;
        }
        
        private function mouseDownHandler(evt:MouseEvent):void
        {
            m_delegate.module.start(evt.localX, evt.localY);
            m_delegate.recorder.painter.view.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
        }
        
        private function mouseMoveHandler(evt:MouseEvent):void
        {
            m_delegate.module.move(evt.localX, evt.localY);
        }
        
        private function mouseUpHandler(evt:MouseEvent):void
        {
            m_delegate.recorder.painter.view.removeEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
            m_delegate.module.stop(evt.localX, evt.localY);
        }
        
        private function mouseOutHandler(evt:MouseEvent):void
        {
            m_delegate.module.interrupt(evt.localX, evt.localY);
        }
    }
}