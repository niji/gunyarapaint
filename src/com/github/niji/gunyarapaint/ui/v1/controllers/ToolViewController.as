package com.github.niji.gunyarapaint.ui.v1.controllers
{
    import com.github.niji.framework.Painter;
    import com.github.niji.framework.UndoStack;
    import com.github.niji.framework.events.UndoEvent;
    import com.github.niji.framework.modules.ICanvasModule;
    import com.github.niji.framework.ui.IApplication;
    import com.github.niji.framework.ui.IController;
    import com.github.niji.gunyarapaint.ui.v1.views.ToolView;
    
    import flash.display.DisplayObject;
    import flash.geom.Point;
    
    import mx.core.Application;
    import mx.core.IMXMLObject;
    
    public class ToolViewController implements IMXMLObject, IController
    {
        public function initialized(document:Object, id:String):void
        {
            m_parent = ToolView(document);
        }
        
        public function init(app:IApplication):void
        {
            var undo:UndoStack = app.undoStack;
            undo.addEventListener(UndoEvent.UNDO, onChangeUndo);
            undo.addEventListener(UndoEvent.REDO, onChangeUndo);
            undo.addEventListener(UndoEvent.PUSH, onChangeUndo);
            m_app = app;
            m_initPosition = new Point(m_parent.x, m_parent.y);
        }
        
        public function load(data:Object):void
        {
            var point:Object = data.point;
            m_parent.move(point.x, point.y);
            updateUndoCount(m_app.undoStack);
            setRotate(data.rotate);
            setZoom(data.zoom);
        }
        
        public function save(data:Object):void
        {
            data.point = new Point(m_parent.x, m_parent.y);
            data.rotate = m_parent.canvasRotate.value;
            data.zoom = m_parent.canvasZoom.value;
        }
        
        public function resetWindow():void
        {
            m_parent.move(m_initPosition.x, m_initPosition.y);
            setRotate(0);
            setZoom(1);
        }
        
        public function setRotate(value:Number):void
        {
            m_parent.canvasRotate.value = value;
            m_parent.canvasRotateValue.text = String(-m_parent.canvasRotate.value);
            Application.application.canvasController.rotate(m_parent.canvasRotate.value);
        }
        
        public function setZoom(value:Number):void
        {
            var n:Number = value;
            if (n < 1)
                n = 1.0 / (-value + 2);
            n *= 10000;
            m_parent.canvasZoom.value = value;
            Application.application.canvasController.zoom(value);  
            m_parent.canvasZoomValue.text = String(Math.round(n) / 100);
        }
        
        public function swapEventListener(from:UndoStack, to:UndoStack):void
        {
            from.removeEventListener(UndoEvent.UNDO, onChangeUndo);
            from.removeEventListener(UndoEvent.REDO, onChangeUndo);
            from.removeEventListener(UndoEvent.PUSH, onChangeUndo);
            to.addEventListener(UndoEvent.UNDO, onChangeUndo);
            to.addEventListener(UndoEvent.REDO, onChangeUndo);
            to.addEventListener(UndoEvent.PUSH, onChangeUndo);
        }
        
        public function get name():String
        {
            return "toolViewController";
        }
        
        public function get parentDisplayObject():DisplayObject
        {
            return m_parent;
        }
        
        public function handleUndo():void
        {
            m_app.canvasModule.undo();
        }
        
        public function handleRedo():void
        {
            m_app.canvasModule.redo();
        }
        
        public function handleChangeCanvasZoom(value:Number):void
        {
            if (value <= 0) {
                value = 1;
            }
            else if (value >= 100) {
                value /= 100;
            }
            else {
                value = -(100 / value) + 2;
            }
            setZoom(value);
        }
        
        public function handleChangeAuxDivideCount(value:Number):void
        {
            Application.application.canvasController.auxDivideCount = uint(value);
        }
        
        public function handleChangeAuxBoxVisible(value:Boolean):void
        {
            Application.application.canvasController.auxBoxVisible = value;
        }
        
        public function handleChangeAuxSkewVisible(value:Boolean):void
        {
            Application.application.canvasController.auxSkewVisible = value;
        }
        
        public function handleChangeAuxType(value:int):void
        {
            var n:Number = m_parent.additionalNumberStepper.value;
            if (value == 0) {
                m_parent.additionalNumberStepper.minimum = 2;
                m_parent.additionalNumberStepper.maximum = 16;
                Application.application.canvasController.enableAuxPixel = false;
            }
            else {
                m_parent.additionalNumberStepper.minimum = 4;
                m_parent.additionalNumberStepper.maximum = 80;
                Application.application.canvasController.enableAuxPixel = true;
            }
        }
        
        public function handleChangeEnableBigPixel(value:Boolean):void
        {
            var module:ICanvasModule = m_app.canvasModule;
            module.setCompatibility(Painter.COMPATIBILITY_BIG_PIXEL, value);
        }
        
        public function handleChangeEnablePixelInfo(value:Boolean):void
        {
            Application.application.canvasController.enablePixelInfo = value;
        }
        
        public function handleChangeEnableUndoLayer(value:Boolean):void
        {
            var module:ICanvasModule = m_app.canvasModule;
            module.setCompatibility(Painter.COMPATIBILITY_UNDO_LAYER, value);
        }
        
        private function onChangeUndo(event:UndoEvent):void
        {
            var undoStack:UndoStack = UndoStack(event.target);
            updateUndoCount(undoStack);
        }
        
        private function updateUndoCount(undoStack:UndoStack):void
        {
            var undoCount:int = undoStack.undoCount;
            m_parent.undoButton.label = _("Undo count");
            if (undoCount > 0) {
                m_parent.undoButton.label += " (" + undoCount + ")";
                m_parent.undoButton.enabled = true;
            }
            else {
                m_parent.undoButton.enabled = false;
            }
            var redoCount:int = undoStack.redoCount;
            m_parent.redoButton.label = _("Redo count");
            if (redoCount > 0) {
                m_parent.redoButton.label += " (" + redoCount + ")";
                m_parent.redoButton.enabled = true;
            }
            else {
                m_parent.redoButton.enabled = false;
            }
        }
        
        private var m_parent:ToolView;
        private var m_app:IApplication;
        private var m_initPosition:Point;
    }
}
