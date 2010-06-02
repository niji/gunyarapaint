package org.libspark.gunyarapaint.ui.v1
{
    import flash.display.BitmapData;
    import flash.events.EventPhase;
    import flash.events.MouseEvent;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    
    import mx.containers.TitleWindow;
    import mx.controls.HScrollBar;
    import mx.controls.VScrollBar;
    import mx.controls.scrollClasses.ScrollBar;
    import mx.core.Application;
    import mx.core.Container;
    import mx.events.FlexEvent;
    import mx.events.MoveEvent;
    import mx.events.ResizeEvent;
    import mx.events.ScrollEvent;
    
    import org.libspark.gunyarapaint.framework.Pen;
    import org.libspark.gunyarapaint.framework.ui.IApplication;
    import org.libspark.gunyarapaint.ui.utils.ComponentResizer;
    
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
            m_canvas = new Canvas(app, this);
            m_canvasContainer.addChild(m_canvas);
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
            m_canvas.auxBoxVisible = data.auxBoxVisible;
            m_canvas.auxSkewVisible = data.auxSkewVisible;
            m_canvas.auxDivideCount = data.auxDivideCount;
            m_canvas.auxLineAlpha = data.auxLineAlpha;
            m_canvas.auxLineColor = data.auxLineColor;
            m_canvas.enableAuxPixel = data.enableAuxPixel;
        }
        
        public function save(data:Object):void
        {
            data.rectangle = new Rectangle(x, y, width, height);
            data.auxBoxVisible = m_canvas.auxBoxVisible;
            data.auxSkewVisible = m_canvas.auxSkewVisible;
            data.auxDivideCount = m_canvas.auxDivideCount;
            data.auxLineAlpha = m_canvas.auxLineAlpha;
            data.auxLineColor = m_canvas.auxLineColor;
            data.enableAuxPixel = m_canvas.enableAuxPixel;
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
            bitmapData.draw(m_canvas);
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
        
        public function set auxBoxVisible(value:Boolean):void
        {
            m_canvas.auxBoxVisible = value;
            m_canvas.updateAuxViews();
        }
        
        public function set auxSkewVisible(value:Boolean):void
        {
            m_canvas.auxSkewVisible = value;
            m_canvas.updateAuxViews();
        }
        
        public function set auxDivideCount(value:uint):void
        {
            m_canvas.auxDivideCount = value;
            m_canvas.updateAuxViews();
        }
        
        public function set enableAuxPixel(value:Boolean):void
        {
            m_canvas.enableAuxPixel = value;
            m_canvas.updateAuxViews();
        }
        
        public function set enablePixelInfo(value:Boolean):void
        {
            status = value ? m_statusDefault : "";
            m_canvas.enablePixelInfo = value;
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
                m_canvas.auxLineColor = pen.color;
                m_canvas.auxLineAlpha = pen.alpha;
                m_canvas.updateAuxViews();
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
            // キャンバスを移動させる
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
        private var m_scrollDragStartPoint:Point;
        private var m_canvas:Canvas;
    }
}
