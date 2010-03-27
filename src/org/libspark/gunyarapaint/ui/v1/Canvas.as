package org.libspark.gunyarapaint.ui.v1
{
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.IEventDispatcher;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    
    import mx.controls.Alert;
    import mx.core.Application;
    import mx.core.UIComponent;
    import mx.managers.CursorManager;
    
    import org.libspark.gunyarapaint.framework.AuxLineView;
    import org.libspark.gunyarapaint.framework.AuxPixelView;
    import org.libspark.gunyarapaint.framework.LayerBitmapCollection;
    import org.libspark.gunyarapaint.framework.TransparentBitmap;
    import org.libspark.gunyarapaint.framework.modules.DropperModule;
    import org.libspark.gunyarapaint.framework.modules.ICanvasModule;
    import org.libspark.gunyarapaint.framework.ui.IApplication;
    import org.libspark.gunyarapaint.ui.events.CanvasModuleEvent;
    
    internal class Canvas extends UIComponent
    {
        public function Canvas()
        {
            var app:IApplication = IApplication(Application.application);
            var rect:Rectangle = new Rectangle(0, 0, app.canvasWidth, app.canvasHeight);
            var transparent:TransparentBitmap = new TransparentBitmap(rect);
            m_auxLine = new AuxLineView(rect);
            m_auxPixel = new AuxPixelView(rect);
            m_auxLine.visible = true;
            m_auxPixel.visible = false;
            // 透明画像、キャンバス本体、補助線(直線および斜線)の順番に追加される
            addChild(transparent);
            app.layers.setView(this);
            addChild(m_auxLine);
            addChild(m_auxPixel);
            addEventListener(Event.REMOVED_FROM_STAGE, onRemove);
            addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
            var dispatcher:IEventDispatcher = IEventDispatcher(app);
            dispatcher.addEventListener(CanvasModuleEvent.BEFORE_CHANGE, onModuleChangeBefore);
            dispatcher.addEventListener(CanvasModuleEvent.AFTER_CHANGE, onModuleChangeAfter);
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
        
        private function onModuleChangeBefore(event:CanvasModuleEvent):void
        {
            removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
        }
        
        private function onModuleChangeAfter(event:CanvasModuleEvent):void
        {
            var module:ICanvasModule = IApplication(Application.application).module;
            if (module is MovableCanvasModule)
                addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
            CursorManager.removeCursor(CursorManager.currentCursorID);
            switch (module.name) {
                case DropperModule.DROPPER:
                    CursorManager.setCursor(m_dropperIcon);
                    break;
                case MovableCanvasModule.MOVABLE_CANVAS:
                    CursorManager..setCursor(m_handOpenIcon);
                    break;
            }
        }
        
        private function onRemove(event:Event):void
        {
            var app:IApplication = IApplication(Application.application);
            app.layers.removeView(this);
            removeEventListener(Event.REMOVED_FROM_STAGE, onRemove);
            var dispatcher:IEventDispatcher = IEventDispatcher(app);
            dispatcher.removeEventListener(CanvasModuleEvent.BEFORE_CHANGE, onModuleChangeBefore);
            dispatcher.removeEventListener(CanvasModuleEvent.AFTER_CHANGE, onModuleChangeAfter);
        }
        
        private function onMouseDown(event:MouseEvent):void
        {
            var app:gunyarapaint = gunyarapaint(Application.application);
            var layers:LayerBitmapCollection = app.layers;
            try {
                // 例えば非表示あるいはロック状態のあるレイヤーに対して描写を行うと例外が送出されるので、
                // 必ず try/catch で囲む必要がある
                app.module.start(event.localX, event.localY);
                layers.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
                layers.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
                layers.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
            } catch (e:Error) {
                removeMouseEvents(layers);
                Alert.show(e.message, app.moduleName);
            }
        }
        
        private function onMouseMove(event:MouseEvent):void
        {
            var app:IApplication = IApplication(Application.application);
            app.module.move(event.localX, event.localY);
        }
        
        private function onMouseUp(event:MouseEvent):void
        {
            var app:IApplication = IApplication(Application.application);
            removeMouseEvents(app.layers);
            app.module.stop(event.localX, event.localY);
        }
        
        private function onMouseOut(event:MouseEvent):void
        {
            var app:IApplication = IApplication(Application.application);
            removeMouseEvents(app.layers);
            app.module.interrupt(event.localX, event.localY);
        }
        
        private function onMouseWheel(event:MouseEvent):void
        {
            var module:MovableCanvasModule = MovableCanvasModule(Application.application.module);
            module.wheel(event.localX, event.localY, event.delta);
        }
        
        private function removeMouseEvents(layers:LayerBitmapCollection):void
        {
            layers.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            layers.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            layers.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
        }
        
        [Embed(source="../../../../../../imgs/icon_dropper.png")]
        private var m_dropperIcon:Class;
        
        [Embed(source="../../../../../../imgs/icon_hand_open.png")]
        private var m_handOpenIcon:Class;
        
        private var m_auxLine:AuxLineView;
        private var m_auxPixel:AuxPixelView;
    }
}
