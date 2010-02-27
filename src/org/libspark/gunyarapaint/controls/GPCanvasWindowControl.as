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
    import mx.core.Container;
    import mx.events.MoveEvent;
    import mx.events.ResizeEvent;
    import mx.events.ScrollEvent;
    
    import org.libspark.gunyarapaint.framework.Pen;
    import org.libspark.gunyarapaint.controls.IDelegate;
    import org.libspark.gunyarapaint.utils.ComponentResizer;
    
    public class GPCanvasWindowControl extends TitleWindow
    {
        private var _canvasContainer:Container; // GPCanvasを直接格納するコンテナ
        private var _contentContainer:Container; // GPCanvasと背景、スクロールバーを持つコンテナ
        
        private var hScrollBar:HScrollBar; // 横スクロールバー
        private var vScrollBar:VScrollBar; // 縦スクロールバー
        private var canvasX:Number, canvasY:Number; // キャンバスのスクロール位置
        private var _canvasScale:Number; // キャンバスの倍率
        private var _preDegree:int; // 前の回転角度
        private var scrollDragStartPoint:Point;
        
        private var m_delegate:IDelegate;
        
        public function GPCanvasWindowControl()
        {
            super();
            
            backgroundColor = 0x000000;
            
            // setStyle('backgroundAlpha', 0);
            horizontalScrollPolicy = 'off';
            verticalScrollPolicy = 'off';
            
            addEventListener(ResizeEvent.RESIZE, resizeHandler);
            addEventListener(MoveEvent.MOVE, moveHandler);
            
            ComponentResizer.addResize(this, new Point(100, 100));
            _preDegree = 0;
        }
        
        
        public function zoomCanvas(m:Number):void
        {
            var rm:Number;
            rm = m >= 1 ? m : 1.0 / (-m + 2);
            _canvasScale = rm;
            //_logger.eventCanvasScale(rm);
            resizeContainer();
            moveCanvas();
        }
        
        public function rotateCanvas(deg:int):void
        {
            var br:Rectangle = transform.pixelBounds;
            var p:Point = new Point(br.x + br.width / 2, br.y + br.height / 2);
            var m:Matrix = transform.matrix;
            m.translate(-p.x, -p.y);
            m.rotate((deg - _preDegree) * (Math.PI / 180));
            m.translate(p.x, p.y);
            transform.matrix = m;
            _preDegree = deg;
            if (deg == 0)
                transform.matrix = new Matrix(1, 0, 0, 1, m.tx, m.ty);
        }
        
        public function set delegate(value:IDelegate):void
        {    
            _contentContainer = new Container();
            _contentContainer.setStyle('borderStyle', 'none');
            _contentContainer.horizontalScrollPolicy = 'off';
            _contentContainer.verticalScrollPolicy = 'off';
            _contentContainer.percentWidth = 100;
            _contentContainer.percentHeight = 100;
            addChild(_contentContainer);
            
            validateNow(); // percentWidth/Height -> width/heightに更新
            
            hScrollBar = new HScrollBar();
            vScrollBar = new VScrollBar();
            hScrollBar.height = ScrollBar.THICKNESS;
            vScrollBar.width = ScrollBar.THICKNESS;
            hScrollBar.addEventListener(ScrollEvent.SCROLL, hScrollHandler);
            vScrollBar.addEventListener(ScrollEvent.SCROLL, vScrollHandler);
            hScrollBar.lineScrollSize = 1;
            vScrollBar.lineScrollSize = 1;
            
            _canvasContainer = new Container();
            _canvasContainer.width = _contentContainer.width - vScrollBar.width;
            _canvasContainer.height = _contentContainer.height - hScrollBar.height;
            _canvasContainer.setStyle('borderStyle', 'none');
            _canvasContainer.horizontalScrollPolicy = 'off';
            _canvasContainer.verticalScrollPolicy = 'off';
            
            _canvasContainer.addChild(value.recorder.painter.view);
            _contentContainer.addChild(_canvasContainer);
            _contentContainer.addChild(hScrollBar);
            _contentContainer.addChild(vScrollBar);
            
            _canvasContainer.mouseEnabled = false;
            _contentContainer.addEventListener(MouseEvent.CLICK, contentContainerClickHandler);
            
            /*
            mouseChildren = false;
            addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
            addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
            addEventListener(MouseEvent.MOUSE_UP, mouseUp);
            addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
            */
            m_delegate = value;
            
            canvasX = canvasY = 0;
            _canvasScale = 1;
            resizeContainer();
            moveCanvas();
        }
        
        private function moveCanvas():void
        {
            var maxX:Number = 0 * _canvasScale - _canvasContainer.width;
            var maxY:Number = 0 * _canvasScale - _canvasContainer.height;
            canvasX = Math.floor(canvasX);
            canvasY = Math.floor(canvasY);
            if (maxX <= 0)
                maxX = 0;
            if (maxY <= 0)
                maxY = 0;
            if (canvasX < 0)
                canvasX = 0;
            if (canvasY < 0)
                canvasY = 0;
            if (canvasX > maxX)
                canvasX = maxX;
            if (canvasY > maxY)
                canvasY = maxY;
            hScrollBar.scrollPosition = canvasX;
            vScrollBar.scrollPosition = canvasY;
            hScrollBar.lineScrollSize = _canvasScale;
            vScrollBar.lineScrollSize = _canvasScale;
            hScrollBar.setScrollProperties(_canvasContainer.width, 0, maxX, 0);
            vScrollBar.setScrollProperties(_canvasContainer.height, 0, maxY, 0);
            //_logger.eventCanvasMove(-canvasX, -canvasY);
        }
        
        private function hScrollHandler(evt:ScrollEvent):void
        {
            canvasX = hScrollBar.scrollPosition;
            moveCanvas();
        }
        
        private function vScrollHandler(evt:ScrollEvent):void
        {
            canvasY = vScrollBar.scrollPosition;
            moveCanvas();
        }
        
        public function scrollCanvas(x:Number, y:Number):void
        {
            canvasX = x;
            canvasY = y;
            moveCanvas();
        }
        
        private function set backgroundColor(c:uint):void
        {
            setStyle('backgroundColor', c);      
        }
        
        private function contentContainerClickHandler(e:MouseEvent):void
        {
            if (e.eventPhase == flash.events.EventPhase.AT_TARGET) {
                var pen:Pen = m_delegate.recorder.painter.pen;
                backgroundColor = pen.color;
                //_logger.additionalColor = backgroundColor;
                //_logger.additionalAlpha = m_delegate.module.alpha;
                //_logger.eventRefreshAdditional();
            }
        }
        
        private function resizeContainer():void
        {
            // 仮にサイズを狭める
            _canvasContainer.width = _canvasContainer.height = 
                hScrollBar.width = vScrollBar.height = 0;
            
            validateNow(); // _contentContainerのサイズを更新
            
            // それを使って再設定
            var clientWidth:Number = _contentContainer.width - vScrollBar.width;
            var clientHeight:Number = _contentContainer.height - hScrollBar.height;
            
            hScrollBar.width = clientWidth;
            vScrollBar.height = clientHeight;
            
            var canvasWidth:uint = m_delegate.recorder.width;
            var canvasHeight:uint = m_delegate.recorder.height;
            // TODO: minでいいやん
            if (canvasWidth * _canvasScale < clientWidth)
                _canvasContainer.width = canvasWidth * _canvasScale;
            else
                _canvasContainer.width = clientWidth;
            
            if (canvasHeight * _canvasScale < clientHeight)
                _canvasContainer.height = canvasHeight * _canvasScale;
            else
                _canvasContainer.height = clientHeight;          
            
            hScrollBar.move(0, clientHeight);
            vScrollBar.move(clientWidth, 0);
            
            _canvasContainer.move((clientWidth - _canvasContainer.width) / 2,
                (clientHeight - _canvasContainer.height) / 2);
        }
        
        private function resizeHandler(evt:ResizeEvent):void
        {
            resizeContainer();
            moveCanvas();
        }
        
        private function moveHandler(evt:MoveEvent):void
        {
            // 整数化して、shape->bitmapのズレをなくす
            x = int(x);
            y = int(y);
        }
        
        public function get canvasScrollPosition():Point
        {
            return new Point(canvasX, canvasY);
        }
        
        public function get canvasScale():Number
        {
            return _canvasScale;
        }
        
        public function set statusText(value:String):void
        {
            status = value;
        }
    }
}
