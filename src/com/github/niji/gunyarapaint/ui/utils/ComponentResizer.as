package com.github.niji.gunyarapaint.ui.utils
{
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import mx.core.Application;
    import mx.core.UIComponent;
    
    public class ComponentResizer {
        /*
        private static var resizeCursor:Class;
        [Embed(source="/img/cur_vertical.png")]
        private static const CONST_CUR_VERTICAL:Class;
        [Embed(source="/img/cur_horizontal.png")]
        private static const CONST_CUR_HORIZONTAL:Class;
        [Embed(source="/img/cur_left_oblique.png")]
        private static const CONST_CUR_LEFT_OBLIQUE:Class;
        [Embed(source="/img/cur_right_oblique.png")]
        private static const CONST_CUR_RIGHT_OBLIQUE:Class;
        */
        
        private static const CONST_MODE_NONE:Number = 0;
        private static const CONST_MODE_LEFT:Number = 1;
        private static const CONST_MODE_RIGHT:Number = 2;
        private static const CONST_MODE_TOP:Number = 4;
        private static const CONST_MODE_BOTTOM:Number = 8;
        private static const CONST_MODE_MOVE:Number = 11;
        
        private static var resizeTarget:UIComponent;
        private static var resizeMode:Number = 0;
        private static var _isResizing:Boolean = false;
        private static var _resizeAreaMargin:Number = 4;
        
        private static var resizeRect:Rectangle;
        private static var oldRect:Rectangle;
        private static var oldPoint:Point;
        
        private static var rubberBand:UIComponent;
        
        /**
         * リサイズ機能を与えるオブジェクトを指定します。
         * @param target リサイズさせるUIComponentです。
         * @param minSize リサイズ可能な最小サイズをPointで指定します。
         *
         */
        public static function addResize(target:UIComponent, minSize:Point):void{
            target.setStyle("resizer_minSize", minSize);
            target.setStyle("resizer_isPopUp", target.isPopUp);
            target.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
            target.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            target.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
        }
        
        /**
         * リサイズ機能を無効にします。
         * @param target リサイズ機能を無効にするUIComponentです。
         *
         */
        public static function removeResize(target:UIComponent):void{
            target.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
            target.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            target.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
        }
        
        /**
         * リサイズ中のオブジェクトがある場合trueを返します。
         * @return
         *
         */
        public static function get isResizing():Boolean{
            return _isResizing;
        }
        
        /**
         * ドラッグ可能なエリアをオブジェクト端からの距離で指定します。
         * @param value
         *
         */
        public static function set resizeAreaMargin(value:Number):void{
            _resizeAreaMargin = value;
        }
        public static function get resizeAreaMargin():Number{
            return _resizeAreaMargin;
        }
        
        private static function onMouseDown(event:MouseEvent):void{
            if (event.currentTarget.rotation != 0) {
                // 回転してたらやめる
                return;
            }
            
            Application.application.parent.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            Application.application.parent.addEventListener(MouseEvent.MOUSE_MOVE, resize);
            
            if(resizeMode != CONST_MODE_NONE){
                resizeTarget = UIComponent(event.currentTarget);
                resizeRect = new Rectangle(resizeTarget.x,
                    resizeTarget.y,
                    resizeTarget.width,
                    resizeTarget.height);
                
                oldRect = resizeRect.clone();
                oldPoint = new Point(event.stageX,event.stageY);
                
                rubberBand = new UIComponent();
                Application.application.parent.addChild(rubberBand);
                drawRubberBand(rubberBand,resizeTarget,resizeRect);
            }
        }
        private static function onTitleMouseDown(event:MouseEvent):void{
            
            if(resizeMode == CONST_MODE_NONE){
                resizeMode = CONST_MODE_MOVE;
            }
        }
        private static function onMouseUp(event:MouseEvent):void{
            
            Application.application.parent.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            Application.application.parent.removeEventListener(MouseEvent.MOUSE_MOVE, resize);
            
            _isResizing = false;
            if(resizeTarget){
                resizeTarget.x = resizeRect.x;
                resizeTarget.y = resizeRect.y;
                resizeTarget.width = resizeRect.width;
                resizeTarget.height = resizeRect.height;
                Application.application.parent.removeChild(rubberBand);
            }
            
            resizeTarget = null;
        }
        
        private static function onMouseMove(event:MouseEvent):void{
            if (event.currentTarget.rotation != 0) {
                // 回転してたらやめる
                return;
            }
            
            var target:UIComponent = UIComponent(event.currentTarget);
            var point:Point = target.localToGlobal(new Point());
            
            _isResizing = true;
            
            if(!resizeTarget){
                var posX:Number = event.stageX;
                var posY:Number = event.stageY;
                if(posX >= (point.x + target.width - _resizeAreaMargin) &&
                    posY >= (point.y + target.height - _resizeAreaMargin)){
                    
                    //changeCursor(CONST_CUR_LEFT_OBLIQUE, -6, -6);
                    resizeMode = CONST_MODE_RIGHT | CONST_MODE_BOTTOM;
                    
                }else if(posX <= (point.x + _resizeAreaMargin) &&
                    posY <= (point.y + _resizeAreaMargin)){
                    
                    //changeCursor(CONST_CUR_LEFT_OBLIQUE, -6, -6);
                    resizeMode = CONST_MODE_LEFT | CONST_MODE_TOP;
                    
                }else if(posX <= (point.x + _resizeAreaMargin) &&
                    posY >= (point.y + target.height - _resizeAreaMargin)){
                    
                    //changeCursor(CONST_CUR_RIGHT_OBLIQUE, -6, -6);
                    resizeMode = CONST_MODE_LEFT | CONST_MODE_BOTTOM;
                    
                }else if(posX >= (point.x + target.width - _resizeAreaMargin) &&
                    posY <= (point.y + _resizeAreaMargin)){
                    
                    //changeCursor(CONST_CUR_RIGHT_OBLIQUE, -6, -6);
                    resizeMode = CONST_MODE_RIGHT | CONST_MODE_TOP;
                    
                }else if(posX >= (point.x + target.width - _resizeAreaMargin)){
                    
                    //changeCursor(CONST_CUR_HORIZONTAL, -9, -9);
                    resizeMode = CONST_MODE_RIGHT;
                    
                }else if(posX <= (point.x + _resizeAreaMargin)){
                    
                    //changeCursor(CONST_CUR_HORIZONTAL, -9, -9);
                    resizeMode = CONST_MODE_LEFT;
                    
                }else if(posY >= (point.y + target.height - _resizeAreaMargin)){
                    
                    //changeCursor(CONST_CUR_VERTICAL, -9, -9);
                    resizeMode = CONST_MODE_BOTTOM;
                    
                }else if(posY <= (point.y + _resizeAreaMargin)){
                    
                    //changeCursor(CONST_CUR_VERTICAL, -9, -9);
                    resizeMode = CONST_MODE_TOP;
                    
                }else{
                    
                    //changeCursor(null, 0, 0);
                    resizeMode = CONST_MODE_NONE;
                    _isResizing = false;
                    
                }
                
                if(target.getStyle("resizer_isPopUp")){
                    
                    if(resizeMode != CONST_MODE_NONE){
                        target.isPopUp = false;
                    }else{
                        target.isPopUp = true;
                    }
                }
            }
        }
        
        private static function onMouseOut(event:MouseEvent):void{
            if (event.currentTarget.rotation != 0) {
                // 回転してたらやめる
                return;
            }
            if(!resizeTarget){
                _isResizing = false;
                changeCursor(null, 0, 0);
                resizeMode = CONST_MODE_NONE;
            }
        }
        
        private static function resize(event:MouseEvent):void{
            
            if(resizeTarget){
                var sizeX:Number = event.stageX - oldPoint.x;
                var sizeY:Number = event.stageY - oldPoint.y;
                var minSize:Point = Point(resizeTarget.getStyle("resizer_minSize"));
                
                switch(resizeMode){
                    case CONST_MODE_RIGHT | CONST_MODE_BOTTOM:
                        resizeRect.width = oldRect.width + sizeX > minSize.x ? oldRect.width + sizeX : minSize.x;
                        resizeRect.height = oldRect.height + sizeY > minSize.y ? oldRect.height + sizeY : minSize.y;
                        break;
                    case CONST_MODE_LEFT | CONST_MODE_TOP:
                        resizeRect.width = oldRect.width - sizeX > minSize.x ? oldRect.width - sizeX : minSize.x;
                        resizeRect.height = oldRect.height - sizeY > minSize.y ? oldRect.height - sizeY : minSize.y;
                        resizeRect.x = sizeX < oldRect.width - minSize.x ? oldRect.x + sizeX: resizeRect.x;
                        resizeRect.y = sizeY < oldRect.height - minSize.y ? oldRect.y + sizeY : resizeRect.y;
                        break;
                    case CONST_MODE_LEFT | CONST_MODE_BOTTOM:
                        resizeRect.width = oldRect.width - sizeX > minSize.x ? oldRect.width - sizeX : minSize.x;
                        resizeRect.height = oldRect.height + sizeY > minSize.y ? oldRect.height + sizeY : minSize.y;
                        resizeRect.x = sizeX < oldRect.width - minSize.x ? oldRect.x + sizeX: resizeRect.x;
                        break;
                    case CONST_MODE_RIGHT | CONST_MODE_TOP:
                        resizeRect.width = oldRect.width + sizeX > minSize.x ? oldRect.width + sizeX : minSize.x;
                        resizeRect.height = oldRect.height - sizeY > minSize.y ? oldRect.height - sizeY : minSize.y;
                        resizeRect.y = sizeY < oldRect.height - minSize.y ? oldRect.y + sizeY : resizeRect.y;
                        break;
                    case CONST_MODE_RIGHT:
                        resizeRect.width = oldRect.width + sizeX > minSize.x ? oldRect.width + sizeX : minSize.x;
                        break;
                    case CONST_MODE_LEFT:
                        resizeRect.width = oldRect.width - sizeX > minSize.x ? oldRect.width - sizeX : minSize.x;
                        resizeRect.x = sizeX < oldRect.width - minSize.x ? oldRect.x + sizeX: resizeRect.x;
                        break;
                    case CONST_MODE_BOTTOM:
                        resizeRect.height = oldRect.height + sizeY > minSize.y ? oldRect.height + sizeY : minSize.y;
                        break;
                    case CONST_MODE_TOP:
                        resizeRect.height = oldRect.height - sizeY > minSize.y ? oldRect.height - sizeY : minSize.y;
                        resizeRect.y = sizeY < oldRect.height - minSize.y ? oldRect.y + sizeY : resizeRect.y;
                        break;
                }
                
                drawRubberBand(rubberBand,resizeTarget,resizeRect);
                event.updateAfterEvent();
            }
        }
        
        private static function changeCursor(curClass:Class,offX:Number,offY:Number):void{
            /*
            if(resizeCursor != curClass){
            CursorManager.removeCursor(CursorManager.currentCursorID);
            if(curClass){
            CursorManager.setCursor(curClass,2, offX, offY);
            }
            resizeCursor = curClass;
            }
            */
        }
        private static function drawRubberBand(rubberBandObj:UIComponent,baseObj:UIComponent,rect:Rectangle):void{
            
            var point:Point = baseObj.localToGlobal(new Point(rect.x-baseObj.x,rect.y-baseObj.y));
            
            rubberBandObj.x = point.x;
            rubberBandObj.y = point.y;
            rubberBandObj.graphics.clear();
            rubberBandObj.graphics.lineStyle(0,0x0000FF,0.3);
            rubberBandObj.graphics.beginFill(0x0000FF,0.1);
            rubberBandObj.graphics.drawRect(0,0,rect.width,rect.height);
            rubberBandObj.graphics.endFill();
        }
    }
}

