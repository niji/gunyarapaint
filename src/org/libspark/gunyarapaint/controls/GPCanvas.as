package org.libspark.gunyarapaint.controls
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    
    import mx.core.UIComponent;
    import mx.managers.CursorManager;
    
    import org.libspark.gunyarapaint.entities.GPLogger;
    
    public class GPCanvas extends UIComponent
    {
        private var baseBitmap:Bitmap; // ベース画像（しましま） (0)
        // _logger.layerArray.view レイヤ統合画像 (1)
        private var additionalBox:Shape; // 縦横補助線 (2)
        private var additionalSkew:Shape; // 斜め補助線 (3)
        private var additionalNumber:uint = 4; // 補助線の分割数
        
        private var _logger:GPLogger; // 描画コマンド履歴
        
        public function GPCanvas(logger:GPLogger)
        {
            _logger = logger;
            var width:uint = logger.canvasWidth;
            var height:uint = logger.canvasHeight;
            
            // 透明時に表示されるbitmap
            baseBitmap = new Bitmap();
            baseBitmap.bitmapData = new BitmapData(width, height, false);
            for (var i:uint = 0; i < width; i++) {
                for (var j:uint = 0; j < height; j++) {
                    baseBitmap.bitmapData.setPixel(i, j, ((i ^ j) & 1) ? 0x999999 : 0xffffff);
                }
            }
            addChildAt(baseBitmap, 0);
            
            // レイヤ画像群
            addChildAt(_logger.layerArray.view, 1);
            
            // 補助線用shape
            additionalBox = new Shape();
            additionalSkew = new Shape();
            changeAdditional();
            additionalBox.visible = false;
            additionalSkew.visible = false;
            addChildAt(additionalBox, 2);
            addChildAt(additionalSkew, 3);
            
            this.mouseEnabled = true;
            this.mouseChildren = false;
            
            this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
            this.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
            this.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
            this.addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
            
            super();
        }
        
        // 20090906-haku2 upd start px単位指定対応、オブジェクト数削減
        private function changeAdditional():void {
            var maxWidth:Number = _logger.canvasWidth;
            var maxHeight:Number = _logger.canvasHeight;
            var addWidth:Number = maxWidth / additionalNumber;
            var addHeight:Number = maxHeight / additionalNumber;
            additionalBox.graphics.clear();
            additionalSkew.graphics.clear();
            additionalBox.graphics.lineStyle(0, _logger.additionalColor, _logger.additionalAlpha);
            additionalSkew.graphics.lineStyle(0, _logger.additionalColor, _logger.additionalAlpha);
            additionalBox.graphics.drawRect(0, 0, maxWidth, maxHeight);
            // 補助線種類判定
            if(_logger.additionalType == 0) {
                // 分割
                for (var i:uint = 0; i < additionalNumber; i++) {
                    if(i > 0){
                        additionalBox.graphics.moveTo(i * addWidth, 0);
                        additionalBox.graphics.lineTo(i * addWidth, maxHeight);
                        additionalBox.graphics.moveTo(0, i * addHeight);
                        additionalBox.graphics.lineTo(maxWidth, i * addHeight);
                        additionalSkew.graphics.moveTo(i * addWidth, 0);
                        additionalSkew.graphics.lineTo(0, i * addHeight);
                        additionalSkew.graphics.moveTo(maxWidth - (i * addWidth), 0);
                        additionalSkew.graphics.lineTo(maxWidth, i * addHeight);
                    }
                    additionalSkew.graphics.moveTo(maxWidth - ((i + 1) * addWidth), maxHeight);
                    additionalSkew.graphics.lineTo(maxWidth, maxHeight - ((i + 1) * addHeight));
                    additionalSkew.graphics.moveTo((i + 1) * addWidth, maxHeight);
                    additionalSkew.graphics.lineTo(0, maxHeight - ((i + 1) * addHeight));
                }
            } else {
                // px単位
                for (var i2:uint = additionalNumber; i2 < maxWidth; i2 += additionalNumber) {
                    additionalBox.graphics.moveTo(i2, 0);
                    additionalBox.graphics.lineTo(i2, maxHeight);
                }
                for (var j2:uint = additionalNumber; j2 < maxHeight; j2 += additionalNumber) {
                    additionalBox.graphics.moveTo(0, j2);
                    additionalBox.graphics.lineTo(maxWidth, j2);
                }
                var max:uint = (maxWidth > maxHeight) ? maxWidth : maxHeight;
                max += additionalNumber - (max % additionalNumber);
                for (var k2:uint = additionalNumber; k2 <= max; k2 += additionalNumber) {
                    additionalSkew.graphics.moveTo(k2 - additionalNumber, 0);
                    additionalSkew.graphics.lineTo(0, k2 - additionalNumber);
                    additionalSkew.graphics.moveTo(max - (k2 - additionalNumber), 0);
                    additionalSkew.graphics.lineTo(max, k2 - additionalNumber);
                    additionalSkew.graphics.moveTo(max, max - k2);
                    additionalSkew.graphics.lineTo(max - k2, max);
                    additionalSkew.graphics.moveTo(0, max - k2);
                    additionalSkew.graphics.lineTo(k2, max);
                }
                var clip:Rectangle = new Rectangle(0, 0, maxWidth, maxHeight);
                additionalSkew.scrollRect = clip;
            }
        }
        // 20090906-haku2 upd end
        
        // 描画関係のフラグ
        public var isMoveTo:Boolean = false;
        public var isDrawnLine:Boolean = false;
        
        private function isInCanvas(evt:MouseEvent):Boolean {
            return (evt.localX >= 0 && evt.localY >= 0 &&
                evt.localX < _logger.canvasWidth && evt.localY < _logger.canvasHeight);
        }
        
        private var isCursorChanged:Boolean = false; // マウスカーソルが変更されているかどうか。多重変更防止    
        public function setCursor(icon:Class):void {
            if (icon && !isCursorChanged) {
                CursorManager.setCursor(icon);
                isCursorChanged = true;
            } else {
                CursorManager.removeCursor(CursorManager.currentCursorID);
                isCursorChanged = false;
            }
        }
        
        public function setAdditionalNumber(num:uint):void {
            additionalNumber = num;
            changeAdditional();
        }
        public function setAdditionalBox(visible:Boolean):void {
            additionalBox.visible = visible;
        }
        public function setAdditionalSkew(visible:Boolean):void {
            additionalSkew.visible = visible;
        }
        // 20090906-haku2 ins start
        public function refreshAdditional():void {
            changeAdditional();
        }
        // 20090906-haku2 ins end
        
        /** new functions **/
        public function mouseDown(evt:MouseEvent):void {
            if (isInCanvas(evt)) {
                _logger.mouseDown(evt);
            }
        }
        public function mouseMove(evt:MouseEvent):void {
            if (isInCanvas(evt)) {
                _logger.mouseMove(evt);
            }
        }
        public function mouseUp(evt:MouseEvent):void {
            if (isInCanvas(evt)) {
                _logger.mouseUp(evt);
            }
        }
        public function mouseOut(evt:MouseEvent):void {
            _logger.mouseOut(evt);
        }
    }
}