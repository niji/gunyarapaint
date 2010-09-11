package com.github.niji.gunyarapaint.ui.v1
{
    import com.oysteinwika.ui.SWFMouseWheel;
    
    import flash.display.BitmapData;
    import flash.events.EventPhase;
    import flash.events.MouseEvent;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;
    
    import mx.containers.TitleWindow;
    import mx.controls.Alert;
    import mx.controls.HScrollBar;
    import mx.controls.VScrollBar;
    import mx.controls.scrollClasses.ScrollBar;
    import mx.controls.scrollClasses.ScrollThumb;
    import mx.core.Application;
    import mx.core.Container;
    import mx.core.UIComponent;
    import mx.events.MoveEvent;
    import mx.events.ResizeEvent;
    import mx.events.ScrollEvent;
    import mx.managers.CursorManager;
    
    import com.github.niji.framework.AuxLineView;
    import com.github.niji.framework.AuxPixelView;
    import com.github.niji.framework.LayerCollection;
    import com.github.niji.framework.Pen;
    import com.github.niji.framework.TransparentBitmap;
    import com.github.niji.framework.modules.DropperModule;
    import com.github.niji.framework.modules.ICanvasModule;
    import com.github.niji.framework.ui.IApplication;
    import com.github.niji.framework.ui.IController;
    import com.github.niji.gunyarapaint.ui.events.CanvasModuleEvent;
    import com.github.niji.gunyarapaint.ui.utils.ComponentResizer;
    
    public class CanvasController extends TitleWindow implements IController
    {
        public function CanvasController()
        {
            m_contentContainer = new Container();
            m_contentContainer.setStyle("borderStyle", "none");
            m_contentContainer.horizontalScrollPolicy = "off";
            m_contentContainer.verticalScrollPolicy = "off";
            m_contentContainer.percentWidth = 100;
            m_contentContainer.percentHeight = 100;
            m_contentContainer.addEventListener(MouseEvent.CLICK, onClickContentContainer);
            m_canvasContainer = new Container();
            m_canvasContainer.mouseEnabled = false;
            m_canvasContainer.setStyle("borderStyle", "none");
            m_canvasContainer.horizontalScrollPolicy = "off";
            m_canvasContainer.verticalScrollPolicy = "off";
            m_hScrollBar = new HScrollBar();
            m_vScrollBar = new VScrollBar();
            m_hScrollBar.height = ScrollBar.THICKNESS;
            m_vScrollBar.width = ScrollBar.THICKNESS;
            m_hScrollBar.addEventListener(ScrollEvent.SCROLL, onScrollHorizontally);
            m_vScrollBar.addEventListener(ScrollEvent.SCROLL, onScrollVertically);
            m_hScrollBar.lineScrollSize = 1;
            m_vScrollBar.lineScrollSize = 1;
            m_statusDefault = _("Coordinates:(%s, %s) Opacity:%s Color:(%s,%s,%s)", 0, 0, 0, 0, 0, 0);
            m_preDegree = 0;
            super();
        }
        
        public function init(app:IApplication):void
        {
            setStyle("backgroundColor", 0x0);
            horizontalScrollPolicy = "off";
            verticalScrollPolicy = "off";
            addChild(m_contentContainer);
            validateNow(); // percentWidth/Height -> width/heightに更新
            m_canvasContainer.width = m_contentContainer.width - m_vScrollBar.width;
            m_canvasContainer.height = m_contentContainer.height - m_hScrollBar.height;
            m_canvasWidth = app.canvasWidth;
            m_canvasHeight = app.canvasHeight;
            m_canvasX = m_canvasY = 0;
            m_canvasScaleX = m_canvasScaleY = 0.5;
            m_canvasScale = 1;
            initCanvas(app);
            m_contentContainer.addChild(m_canvasContainer);
            m_contentContainer.addChild(m_hScrollBar);
            m_contentContainer.addChild(m_vScrollBar);
            m_initRectangle = new Rectangle(x, y, width, height);
            status = m_statusDefault;
            ComponentResizer.addResize(this, new Point(100, 100));
            resize();
            update();
            addEventListener(MoveEvent.MOVE, onMove);
            addEventListener(ResizeEvent.RESIZE, onResize);
        }
        
        public function load(data:Object):void
        {
            var rect:Object = data.rectangle;
            move(rect.x, rect.y);
            width = rect.width;
            height = rect.height;
            auxBoxVisible = data.auxBoxVisible;
            auxSkewVisible = data.auxSkewVisible;
            auxDivideCount = data.auxDivideCount;
            auxLineAlpha = data.auxLineAlpha;
            auxLineColor = data.auxLineColor;
            enableAuxPixel = data.enableAuxPixel;
        }
        
        public function save(data:Object):void
        {
            data.rectangle = new Rectangle(x, y, width, height);
            data.auxBoxVisible = auxBoxVisible;
            data.auxSkewVisible = auxSkewVisible;
            data.auxDivideCount = auxDivideCount;
            data.auxLineAlpha = auxLineAlpha;
            data.auxLineColor = auxLineColor;
            data.enableAuxPixel = enableAuxPixel;
        }
        
        public function resetWindow():void
        {
            move(m_initRectangle.x, m_initRectangle.y);
            width = m_initRectangle.width;
            height = m_initRectangle.height;
            rotate(0);
            transform.matrix = new Matrix(
                1, 0, 0, 1, m_initRectangle.x, m_initRectangle.y
            );
        }
        
        public function zoom(value:Number):void
        {
            var magnification:Number = value >= 1 ? value : (1.0 / (-value + 2));
            var maxX:Number = m_canvasWidth * magnification - m_canvasContainer.width;
            var maxY:Number = m_canvasHeight * magnification - m_canvasContainer.height;
            m_canvasX = m_canvasScaleX * maxX;
            m_canvasY = m_canvasScaleY * maxY;
            m_canvas.scaleX = m_canvas.scaleY = m_canvasScale = magnification;
            resize();
            update();
        }
        
        public function rotate(value:int):void
        {
            var pb:Rectangle = transform.pixelBounds;
            var p:Point = new Point(pb.x + pb.width / 2, pb.y + pb.height / 2);
            var m:Matrix = transform.matrix;
            m.translate(-p.x, -p.y);
            m.rotate((value - m_preDegree) * (Math.PI / 180));
            m.translate(p.x, p.y);
            transform.matrix = m;
            m_preDegree = value;
            if (value == 0)
                transform.matrix = new Matrix(1, 0, 0, 1, m.tx, m.ty);
        }
        
        public function scroll(x:Number, y:Number):void
        {
            var maxX:Number = m_canvasWidth * m_canvasScale - m_canvasContainer.width;
            var maxY:Number = m_canvasHeight * m_canvasScale - m_canvasContainer.height;
            m_canvasScaleX = x / maxX;
            m_canvasScaleY = x / maxY;
            m_canvasX = x;
            m_canvasY = y;
            update();
        }
        
        public function exportBitmapData():BitmapData
        {
            var bitmapData:BitmapData = new BitmapData(m_canvasWidth, m_canvasHeight);
            bitmapData.draw(m_canvasContainer);
            return bitmapData;
        }
        
        public function get canvasScrollPosition():Point
        {
            return new Point(m_canvasX, m_canvasY);
        }
        
        public function get canvasScale():Number
        {
            return m_canvasScale;
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
            updateAuxViews();
        }
        
        public function set auxSkewVisible(value:Boolean):void
        {
            m_auxLine.skewVisible = m_auxPixel.skewVisible = value;
            updateAuxViews();
        }
        
        public function set auxDivideCount(value:uint):void
        {
            m_auxLine.divideCount = m_auxPixel.divideCount = value;
            updateAuxViews();
        }
        
        public function set auxLineAlpha(value:Number):void
        {
            m_auxLine.lineAlpha = m_auxPixel.lineAlpha = value;
            updateAuxViews();
        }
        
        public function set auxLineColor(value:uint):void
        {
            m_auxLine.lineColor = m_auxPixel.lineColor = value;
            updateAuxViews();
        }
        
        public function set enableAuxPixel(value:Boolean):void
        {
            m_auxLine.visible = value ? false : true;
            m_auxPixel.visible = value ? true : false;
        }
        
        public function set enablePixelInfo(value:Boolean):void
        {
            status = value ? m_statusDefault : "";
            m_contentContainer.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove2);
            if (value)
                m_contentContainer.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove2);
        }
        
        public function set statusText(value:String):void
        {
            status = value;
        }
        
        private function onScrollHorizontally(event:ScrollEvent):void
        {
            var maxX:Number = m_canvasWidth * m_canvasScale - m_canvasContainer.width;
            m_canvasX = m_hScrollBar.scrollPosition;
            m_canvasScaleX = m_canvasX / maxX;
            update();
        }
        
        private function onScrollVertically(event:ScrollEvent):void
        {
            var maxY:Number = m_canvasHeight * m_canvasScale - m_canvasContainer.height;
            m_canvasY = m_vScrollBar.scrollPosition;
            m_canvasScaleY = m_canvasY / maxY;
            update();
        }
        
        private function onResize(event:ResizeEvent):void
        {
            resize();
            update();
        }
        
        private function onMove(event:MoveEvent):void
        {
            x = int(x);
            y = int(y);
        }
        
        private function onClickContentContainer(event:MouseEvent):void
        {
            if (event.eventPhase == EventPhase.AT_TARGET && event.shiftKey) {
                var pen:Pen = IApplication(Application.application).pen;
                setStyle("backgroundColor", pen.color);
                auxLineColor = pen.color;
                auxLineAlpha = pen.alpha;
            }
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
            var layers:LayerCollection = app.layers;
            var x:Number = layers.mouseX;
            var y:Number = layers.mouseY;
            try {
                // 例えば非表示あるいはロック状態のあるレイヤーに対して描写を行うと例外が送出されるので、
                // 必ず try/catch で囲む必要がある
                app.canvasModule.start(x, y);
                removeMouseEvents(layers);
                m_contentContainer.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
                m_contentContainer.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
                m_widthLimit = m_contentContainer.width - m_vScrollBar.width;
                m_heightLimit = m_contentContainer.height - m_hScrollBar.height;
                //addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
            } catch (e:Error) {
                removeMouseEvents(layers);
                Alert.show(e.message, app.canvasModuleName);
            }
        }
        
        private function onMouseMove(event:MouseEvent):void
        {
            if (event.target is ScrollThumb == false &&
                m_contentContainer.mouseX < m_widthLimit &&
                m_contentContainer.mouseY < m_heightLimit) {
                var app:IApplication = IApplication(Application.application);
                var layers:LayerCollection = app.layers;
                var x:Number = layers.mouseX;
                var y:Number = layers.mouseY;
                app.canvasModule.move(x, y);
            }
        }
        
        private function onMouseMove2(event:MouseEvent):void
        {
            var application:Object = Application.application;
            var app:IApplication = IApplication(application);
            var layers:LayerCollection = app.layers
            var x:Number = layers.mouseX;
            var y:Number = layers.mouseY;
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
            var layers:LayerCollection = app.layers;
            var x:Number = layers.mouseX;
            var y:Number = layers.mouseY;
            removeMouseEvents(layers);
            app.canvasModule.stop(x, y);
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
        
        private function removeMouseEvents(layers:LayerCollection):void
        {
            m_contentContainer.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            m_contentContainer.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
        }
        
        private function initCanvas(app:IApplication):void
        {
            var rect:Rectangle = new Rectangle(0, 0, m_canvasWidth, m_canvasHeight);
            var transparent:TransparentBitmap = new TransparentBitmap(rect);
            m_auxLine = new AuxLineView(rect);
            m_auxPixel = new AuxPixelView(rect);
            m_auxLine.visible = true;
            m_auxPixel.visible = false;
            m_canvas = new UIComponent();
            m_canvas.addChild(transparent);
            app.layers.setView(m_canvas);
            m_canvas.addChild(m_auxLine);
            m_canvas.addChild(m_auxPixel);
            m_canvasContainer.addChild(m_canvas);
            app.addEventListener(CanvasModuleEvent.BEFORE_CHANGE, onModuleChangeBefore);
            app.addEventListener(CanvasModuleEvent.AFTER_CHANGE, onModuleChangeAfter);
            m_contentContainer.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
            m_contentContainer.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove2);
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
        }
        
        private function update():void
        {
            var maxX:Number = m_canvasWidth * m_canvasScale - m_canvasContainer.width;
            var maxY:Number = m_canvasHeight * m_canvasScale - m_canvasContainer.height;
            m_canvasX = Math.floor(m_canvasX);
            m_canvasY = Math.floor(m_canvasY);
            // 移動位置及び最大範囲を調整する
            if (maxX <= 0)
                maxX = 0;
            if (maxY <= 0)
                maxY = 0;
            if (m_canvasX < 0)
                m_canvasX = 0;
            if (m_canvasY < 0)
                m_canvasY = 0;
            if (m_canvasX > maxX)
                m_canvasX = maxX;
            if (m_canvasY > maxY)
                m_canvasY = maxY;
            // スクロールバーを移動先の位置に設定する
            m_hScrollBar.scrollPosition = m_canvasX;
            m_vScrollBar.scrollPosition = m_canvasY;
            // 拡大率によってスクロール量を決定する(拡大率が大きい程スクロール量も大きくなる)
            m_hScrollBar.lineScrollSize = m_canvasScale;
            m_vScrollBar.lineScrollSize = m_canvasScale;
            // スクロールバーの大きさを決定する(拡大率が大きい程スクロールバーが小さくなる)
            m_hScrollBar.setScrollProperties(m_canvasContainer.width, 0, maxX);
            m_vScrollBar.setScrollProperties(m_canvasContainer.height, 0, maxY);
            m_canvas.move(-m_canvasX, -m_canvasY);
        }
        
        private function resize():void
        {
            // 仮にサイズを狭める
            m_canvasContainer.width = 0;
            m_canvasContainer.height = 0;
            m_hScrollBar.width = 0;
            m_vScrollBar.height = 0;
            // _contentContainerのサイズを更新
            validateNow();
            // それを使って再設定
            var clientWidth:Number = m_contentContainer.width - m_vScrollBar.width;
            var clientHeight:Number = m_contentContainer.height - m_hScrollBar.height;
            m_hScrollBar.width = clientWidth;
            m_vScrollBar.height = clientHeight;
            // 拡大または縮小したキャンバスのサイズを求める
            var scaledCanvasWidth:Number = m_canvasWidth * m_canvasScale;
            var scaledCanvasHeight:Number = m_canvasHeight * m_canvasScale;
            // 拡大または縮小したキャンバスをキャンバスコンテナのサイズに収める必要がある
            m_canvasContainer.width = scaledCanvasWidth < clientWidth ? scaledCanvasWidth : clientWidth;
            m_canvasContainer.height = scaledCanvasHeight < clientHeight ? scaledCanvasHeight : clientHeight;                      
            // スクロールバーを所定の位置に移動
            m_hScrollBar.move(0, clientHeight);
            m_vScrollBar.move(clientWidth, 0);
            // キャンバスを所定の位置に移動
            m_canvasContainer.move(
                (clientWidth - m_canvasContainer.width) / 2,
                (clientHeight - m_canvasContainer.height) / 2
            );
        }
        
        private var m_statusDefault:String;
        private var m_canvas:UIComponent;
        private var m_canvasContainer:Container; // GPCanvasを直接格納するコンテナ
        private var m_contentContainer:Container; // GPCanvasと背景、スクロールバーを持つコンテナ
        private var m_hScrollBar:HScrollBar; // 横スクロールバー
        private var m_vScrollBar:VScrollBar; // 縦スクロールバー
        private var m_initRectangle:Rectangle; // 初期位置
        private var m_canvasWidth:Number; // キャンバスの幅 (IApplication#canvasWidth の値をキャッシュする)
        private var m_canvasHeight:Number; // キャンバスの高さ (IApplication#canvasHeight の値をキャッシュする)
        private var m_canvasX:Number; // キャンバスのスクロール位置
        private var m_canvasY:Number; 
        private var m_canvasScaleX:Number; // 拡大したキャンバスの幅に対する X 座標の相対率
        private var m_canvasScaleY:Number; // 拡大したキャンバスの高さに対する Y 座標の相対率
        private var m_canvasScale:Number; // キャンバスの倍率
        private var m_preDegree:int; // 前の回転角度
        private var m_auxLine:AuxLineView;
        private var m_auxPixel:AuxPixelView;
        private var m_widthLimit:Number;
        private var m_heightLimit:Number;
    }
}
