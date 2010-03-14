package org.libspark.gunyarapaint.controls
{
    import flash.events.MouseEvent;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import mx.containers.TitleWindow;
    import mx.controls.HScrollBar;
    import mx.controls.VScrollBar;
    import mx.controls.scrollClasses.ScrollBar;
    import mx.core.Application;
    import mx.core.Container;
    import mx.events.FlexEvent;
    import mx.events.ResizeEvent;
    import mx.events.ScrollEvent;
    
    import org.libspark.gunyarapaint.framework.AuxBitmap;
    import org.libspark.gunyarapaint.framework.Pen;
    import org.libspark.gunyarapaint.framework.ui.IApplication;
    
    public class GPCanvasWindowControl extends TitleWindow
    {
        public function GPCanvasWindowControl()
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
            
            m_preDegree = 0;
            
            addEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
            super();
        }
        
        public function zoom(value:Number):void
        {
            var mag:Number = value >= 1 ? value : (1.0 / (-value + 2));
            m_canvasScale = mag;
            m_canvas.scaleX = m_canvas.scaleY = mag;
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
            m_canvasX = x;
            m_canvasY = y;
            update();
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
        
        public function set statusText(value:String):void
        {
            status = value;
        }
        
        private function onCreationComplete(event:FlexEvent):void
        {
            setStyle("backgroundColor", 0x0);
            horizontalScrollPolicy = "off";
            verticalScrollPolicy = "off";
            
            addChild(m_contentContainer);
            validateNow(); // percentWidth/Height -> width/heightに更新
            
            m_canvasContainer.width = m_contentContainer.width - m_vScrollBar.width;
            m_canvasContainer.height = m_contentContainer.height - m_hScrollBar.height;
            m_canvasX = m_canvasY = 0;
            m_canvasScale = 1;
            
            m_canvas = new GPCanvas();
            m_canvasContainer.addChild(m_canvas);
            m_contentContainer.addChild(m_canvasContainer);
            m_contentContainer.addChild(m_hScrollBar);
            m_contentContainer.addChild(m_vScrollBar);
            m_resizable = new ResizableComponent(this, new Point(100, 100));
            
            resize();
            update();
            
            addEventListener(ResizeEvent.RESIZE, onResize);
            removeEventListener(FlexEvent.CREATION_COMPLETE, onCreationComplete);
        }
        
        private function onScrollHorizontally(evt:ScrollEvent):void
        {
            m_canvasX = m_hScrollBar.scrollPosition;
            update();
        }
        
        private function onScrollVertically(evt:ScrollEvent):void
        {
            m_canvasY = m_vScrollBar.scrollPosition;
            update();
        }
        
        private function onResize(evt:ResizeEvent):void
        {
            resize();
            update();
        }
        
        private function onClickContentContainer(e:MouseEvent):void
        {
            if (e.eventPhase == flash.events.EventPhase.AT_TARGET) {
                var pen:Pen = IApplication(Application.application).pen;
                setStyle("backgroundColor", pen.color);
                m_canvas.auxLineColor = pen.color;
                m_canvas.auxLineAlpha = pen.alpha;
                m_canvas.updateAuxViews();
            }
        }
        
        private function update():void
        {
            var application:IApplication = IApplication(Application.application);
            var maxX:Number = application.canvasWidth * m_canvasScale - m_canvasContainer.width;
            var maxY:Number = application.canvasHeight * m_canvasScale - m_canvasContainer.height;
            m_canvasX = Math.floor(m_canvasX);
            m_canvasY = Math.floor(m_canvasY);
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
            m_hScrollBar.scrollPosition = m_canvasX;
            m_vScrollBar.scrollPosition = m_canvasY;
            m_hScrollBar.lineScrollSize = m_canvasScale;
            m_vScrollBar.lineScrollSize = m_canvasScale;
            m_hScrollBar.setScrollProperties(m_canvasContainer.width, 0, maxX, 0);
            m_vScrollBar.setScrollProperties(m_canvasContainer.height, 0, maxY, 0);
            m_canvas.move(-m_canvasX, -m_canvasY);
        }
        
        private function resize():void
        {
            // 仮にサイズを狭める
            m_canvasContainer.width = m_canvasContainer.height = 
                m_hScrollBar.width = m_vScrollBar.height = 0;
            validateNow(); // _contentContainerのサイズを更新
            
            // それを使って再設定
            var clientWidth:Number = m_contentContainer.width - m_vScrollBar.width;
            var clientHeight:Number = m_contentContainer.height - m_hScrollBar.height;
            
            m_hScrollBar.width = clientWidth;
            m_vScrollBar.height = clientHeight;
            
            var application:IApplication = IApplication(Application.application);
            var canvasWidth:uint = application.canvasWidth;
            var canvasHeight:uint = application.canvasHeight;
            // TODO: minでいいやん
            if (canvasWidth * m_canvasScale < clientWidth)
                m_canvasContainer.width = canvasWidth * m_canvasScale;
            else
                m_canvasContainer.width = clientWidth;
            
            if (canvasHeight * m_canvasScale < clientHeight)
                m_canvasContainer.height = canvasHeight * m_canvasScale;
            else
                m_canvasContainer.height = clientHeight;          
            
            m_hScrollBar.move(0, clientHeight);
            m_vScrollBar.move(clientWidth, 0);
            
            m_canvasContainer.move((clientWidth - m_canvasContainer.width) / 2,
                (clientHeight - m_canvasContainer.height) / 2);
        }
        
        private var m_canvasContainer:Container; // GPCanvasを直接格納するコンテナ
        private var m_contentContainer:Container; // GPCanvasと背景、スクロールバーを持つコンテナ
        private var m_hScrollBar:HScrollBar; // 横スクロールバー
        private var m_vScrollBar:VScrollBar; // 縦スクロールバー
        private var m_canvasX:Number, m_canvasY:Number; // キャンバスのスクロール位置
        private var m_canvasScale:Number; // キャンバスの倍率
        private var m_preDegree:int; // 前の回転角度
        private var m_scrollDragStartPoint:Point;
        private var m_resizable:ResizableComponent;
        private var m_canvas:GPCanvas;
    }
}
