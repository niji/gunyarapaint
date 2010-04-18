package org.libspark.gunyarapaint.ui.v1
{
    import com.oysteinwika.ui.SWFMouseWheel;
    
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.IEventDispatcher;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;
    
    import mx.controls.Alert;
    import mx.core.Application;
    import mx.core.UIComponent;
    import mx.managers.CursorManager;
    
    import org.libspark.gunyarapaint.framework.AuxLineView;
    import org.libspark.gunyarapaint.framework.AuxPixelView;
    import org.libspark.gunyarapaint.framework.LayerBitmapCollection;
    import org.libspark.gunyarapaint.framework.TransparentBitmap;
    import org.libspark.gunyarapaint.framework.modules.CanvasModule;
    import org.libspark.gunyarapaint.framework.modules.DropperModule;
    import org.libspark.gunyarapaint.framework.modules.ICanvasModule;
    import org.libspark.gunyarapaint.framework.ui.IApplication;
    import org.libspark.gunyarapaint.ui.events.CanvasModuleEvent;
    
    internal class Canvas extends UIComponent
    {
        public function Canvas(app:IApplication)
        {
            var rect:Rectangle = new Rectangle(0, 0, app.canvasWidth, app.canvasHeight);
            var transparent:TransparentBitmap = new TransparentBitmap(rect);
            m_auxLine = new AuxLineView(rect);
            m_auxPixel = new AuxPixelView(rect);
            m_auxLine.visible = true;
            m_auxPixel.visible = false;
            m_rect = rect;
            // 透明画像、キャンバス本体、補助線(直線および斜線)の順番に追加される
            addChild(transparent);
            app.layers.setView(this);
            app.addEventListener(CanvasModuleEvent.BEFORE_CHANGE, onModuleChangeBefore);
            app.addEventListener(CanvasModuleEvent.AFTER_CHANGE, onModuleChangeAfter);
            addChild(m_auxLine);
            addChild(m_auxPixel);
            addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
            addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove2);
            // Capabilities.version で OS を判断するのは適切ではないが、
            // 少なくとも MacOSX ではマウスホイールを正しく感知することが出来無いので対処療法として
            if (Capabilities.version.indexOf("MAC") >= 0) {
                SWFMouseWheel.SWFMouseWheelHandler = function(delta:Number):void
                {
                    var module:MovableCanvasModule = app.canvasModule as MovableCanvasModule;
                    if (module != null)
                        module.wheel(0, 0, delta * 3)
                };
                SWFMouseWheel._init();
            }
            super();
        }
        
        public function updateAuxViews():void
        {
            m_auxLine.update();
            m_auxPixel.update();
        }
        
        public function get auxBoxVisible():Boolean
        {
            return m_auxLine.boxVisible;
        }
        
        public function get auxSkewVisible():Boolean
        {
            return m_auxLine.skewVisible;
        }
        
        public function get auxDivideCount():uint
        {
            return m_auxLine.divideCount;
        }
        
        public function get auxLineAlpha():Number
        {
            return m_auxLine.lineAlpha;
        }
        
        public function get auxLineColor():uint
        {
            return m_auxLine.lineColor;
        }
        
        public function get enableAuxPixel():Boolean
        {
            return m_auxPixel.visible;
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
        
        public function set enablePixelInfo(value:Boolean):void
        {
            removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove2);
            if (value)
                addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove2);
        }
        
        private function onModuleChangeBefore(event:CanvasModuleEvent):void
        {
            removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
        }
        
        private function onModuleChangeAfter(event:CanvasModuleEvent):void
        {
            var application:Object = Application.application;
            var app:IApplication = IApplication(application);
            var module:ICanvasModule = app.canvasModule;
            if (module is MovableCanvasModule)
                addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
            CursorManager.removeCursor(CursorManager.currentCursorID);
            switch (module.name) {
                case DropperModule.DROPPER:
                    CursorManager.setCursor(application.dropperIcon);
                    break;
                case MovableCanvasModule.MOVABLE_CANVAS:
                    CursorManager.setCursor(application.handOpenIcon);
                    break;
            }
        }
        
        private function onMouseDown(event:MouseEvent):void
        {
            var app:gunyarapaint = gunyarapaint(Application.application);
            var layers:LayerBitmapCollection = app.layers;
            try {
                var canvasModule:ICanvasModule = app.canvasModule;
                var x:Number = event.localX;
                var y:Number = event.localY;
                if (m_rect.contains(x, y)) {
                    // 例えば非表示あるいはロック状態のあるレイヤーに対して描写を行うと例外が送出されるので、
                    // 必ず try/catch で囲む必要がある
                    canvasModule.start(x, y);
                    layers.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
                    layers.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
                    layers.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
                }
            } catch (e:Error) {
                removeMouseEvents(layers);
                Alert.show(e.message, app.canvasModuleName);
            }
        }
        
        private function onMouseMove(event:MouseEvent):void
        {
            var x:Number = event.localX;
            var y:Number = event.localY;
            if (m_rect.contains(x, y)) {
                var app:IApplication = IApplication(Application.application);
                app.canvasModule.move(x, y);
            }
        }
        
        private function onMouseMove2(event:MouseEvent):void
        {
            var application:Object = Application.application;
            var app:IApplication = IApplication(application);
            var x:Number = event.localX;
            var y:Number = event.localY;
            var color:uint = app.canvasModule.getPixel32(x, y);
            var status:String = _(
                "Coordinates:(%s, %s) Opacity:%s Color:(%s,%s,%s)",
                x, y,
                Number(((color >> 24) & 0xff) / 255).toPrecision(2),
                ((color >> 16) & 0xff),
                ((color >> 8) & 0xff),
                ((color >> 0) & 0xff)
            );
            application.canvasController.statusText = status;
        }
        
        private function onMouseUp(event:MouseEvent):void
        {
            var app:IApplication = IApplication(Application.application);
            removeMouseEvents(app.layers);
            app.canvasModule.stop(event.localX, event.localY);
        }
        
        private function onMouseOut(event:MouseEvent):void
        {
            var app:IApplication = IApplication(Application.application);
            removeMouseEvents(app.layers);
            app.canvasModule.interrupt(event.localX, event.localY);
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
        
        private var m_auxLine:AuxLineView;
        private var m_auxPixel:AuxPixelView;
        private var m_rect:Rectangle;
    }
}
