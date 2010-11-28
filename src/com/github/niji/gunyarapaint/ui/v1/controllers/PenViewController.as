package com.github.niji.gunyarapaint.ui.v1.controllers
{
    import com.github.niji.framework.Pen;
    import com.github.niji.framework.events.PenEvent;
    import com.github.niji.framework.modules.DropperModule;
    import com.github.niji.framework.modules.FreeHandModule;
    import com.github.niji.framework.modules.PixelModule;
    import com.github.niji.framework.ui.IApplication;
    import com.github.niji.framework.ui.IController;
    import com.github.niji.gunyarapaint.ui.v1.MovableCanvasModule;
    import com.github.niji.gunyarapaint.ui.v1.views.PenView;
    
    import flash.display.BlendMode;
    import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.events.Event;
    import flash.geom.Point;
    
    import mx.containers.Canvas;
    import mx.containers.GridItem;
    import mx.core.IFlexDisplayObject;
    import mx.core.IMXMLObject;
    import mx.events.CloseEvent;
    import mx.managers.PopUpManager;
    
    import org.sepy.controls.SColorPicker;
    import org.sepy.events.SPickerEvent;
    
    public class PenViewController implements IMXMLObject, IController
    {
        public function initialized(document:Object, id:String):void
        {
            m_parent = PenView(document);
        }
        
        public function init(app:IApplication):void
        {
            // The preview at initialized is not drawn, so we should draw it
            var pen:Pen = app.pen;
            pen.addEventListener(PenEvent.ALPHA, onChangeAlpha);
            pen.addEventListener(PenEvent.COLOR, onChangeColor);
            pen.addEventListener(PenEvent.THICKNESS, onChangeThickness);
            drawPreview(pen.thickness, pen.color, pen.alpha);
            m_parent.blendModeComboBox.dataProvider = app.supportedBlendModes;
            m_app = app;
            m_palette = m_parent.gridItemPalette1;
            m_initPosition = new Point(m_parent.x, m_parent.y);
        }
        
        public function load(data:Object):void
        {
            var pen:Pen = m_app.pen;
            var point:Object = data.point;
            this.pen = data.state;
            pen.alpha = data.alpha;
            pen.color = data.color;
            pen.thickness = data.thickness;
            m_parent.move(point.x, point.y);
            palettes = data.palettes;
        }
        
        public function save(data:Object):void
        {
            var pen:Pen = m_app.pen;
            data.point = new Point(m_parent.x, m_parent.y);
            data.alpha = pen.alpha;
            data.color = pen.color;
            data.thickness = pen.thickness;
            data.state = m_app.canvasModule.name;
            data.palettes = palettes;
        }
        
        public function resetWindow():void
        {
            m_parent.move(m_initPosition.x, m_initPosition.y);
        }
        
        public function saveSelectedState():void
        {
            if (m_state == STATE_NONE) {
                if (m_parent.dropperButton.selected) {
                    m_state = STATE_DROPPER;
                }
                else if (m_parent.handtoolButton.selected) {
                    m_state = STATE_HANDTOOL;
                }
                else if (m_parent.eraserButton.selected) {
                    m_state = STATE_ERASER;
                }
                else if (m_parent.dotButton.selected) {
                    m_state = STATE_DOT;
                }
                else {
                    m_state = STATE_OTHER;
                }
            }
        }
        
        public function loadSelectedState():void
        {
            switch (m_state) {
                case STATE_DROPPER:
                    pen = DropperModule.DROPPER;
                    break;
                case STATE_HANDTOOL:
                    pen = MovableCanvasModule.MOVABLE_CANVAS;
                    break;
                case STATE_ERASER:
                    setEraser();
                    break;
                case STATE_DOT:
                    pen = PixelModule.PIXEL;
                    break;
                default:
                    pen = String(m_parent.penModeComboBox.value);
                    m_app.canvasModule.blendMode = String(m_parent.blendModeComboBox.value);
                    break;
            }
            m_state = STATE_NONE;
        }
        
        public function cancel():void
        {
            m_parent.dropperButton.selected = false;
            m_parent.handtoolButton.selected = false;
            m_parent.eraserButton.selected = false;
            m_parent.dotButton.selected = false;
            m_app.setCanvasModule(String(m_parent.penModeComboBox.value));
        }
        
        public function setEraser():void
        {
            pen = FreeHandModule.FREE_HAND;
            m_parent.currentState = "eraser";
            m_app.canvasModule.blendMode = BlendMode.ERASE;
        }
        
        public function createColorPicker():void
        {
            var picker:SColorPicker = new SColorPicker();
            picker.selectedColor = m_palette.getStyle('backgroundColor');
            picker.title = _("Select color to the palette");
            // display the 'x' close button
            picker.showCloseButton = true;  
            // picker.add_swatch = true;
            // picker.picker_enabled = true;
            picker.addEventListener(CloseEvent.CLOSE, onClosePicker);
            picker.addEventListener(SPickerEvent.CHANGING, onPicker);
            picker.addEventListener(SPickerEvent.SWATCH_ADD, onPicker);
            picker.addEventListener(Event.CHANGE, onPicker);
            PopUpManager.addPopUp(picker, m_parent, true);
            PopUpManager.centerPopUp(picker);
        }
        
        public function handleCurrentStateChange(oldState:String, newState:String):void
        {
            // The "eraser" state retains BlendMode.ERASE so change it forcely
            if (oldState == "eraser") {
                m_app.canvasModule.blendMode = String(m_parent.blendModeComboBox.value);
                currentThickness = m_brushThickness;
            }
            else if (newState == "eraser") {
                currentThickness = m_eraserThickness
            }
        }
        
        public function handleClickPalette(index:uint):void
        {
            var palette:GridItem = this["gridItemPalette" + index];
            m_palette.setStyle("borderThickness", 1);
            m_palette.setStyle("borderColor", 0xb7babc);
            palette.setStyle("borderThickness", 3);
            palette.setStyle("borderColor", 0x000000);
            m_palette = palette;
            currentColor = palette.getStyle("backgroundColor");
        }
        
        public function handleSelectHandTool(value:Boolean):void
        {
            if (value)
                pen = MovableCanvasModule.MOVABLE_CANVAS;
            else
                setDefaultPen();
        }
        
        public function handleSelectDropper(value:Boolean):void
        {
            if (value)
                pen = DropperModule.DROPPER;
            else
                setDefaultPen();
        }
        
        public function handleSelectEraser(value:Boolean):void
        {
            if (value)
                setEraser();
            else
                setDefaultPen();
        }
        
        public function handleSelectDot(value:Boolean):void
        {
            if (value)
                pen = PixelModule.PIXEL;
            else
                setDefaultPen();
        }
        
        public function handleSelectPen(value:String):void
        {
            cancel();
            pen = value;
        }
        
        public function handleSelectBlendMode(value:String):void
        {
            cancel();
            m_app.canvasModule.blendMode = value;
        }
        
        public function handleChangeColorSlider(value:Number, mode:String):void
        {
            var c:uint = 0;
            switch (mode) {
                case "red":
                    c += value * 65536;
                    c += m_parent.colGSlider.value * 256;
                    c += m_parent.colBSlider.value;
                    break;
                case "green":
                    c += m_parent.colRSlider.value * 65536;
                    c += value * 256;
                    c += m_parent.colBSlider.value;
                    break;
                case "blue":
                    c += m_parent.colRSlider.value * 65536;
                    c += m_parent.colGSlider.value * 256;
                    c += value;
                    break;
            }
            currentColor = c;
        }
        
        public function get isEraser():Boolean
        {
            return m_parent.currentState == "eraser" && m_state != STATE_NONE;
        }
        
        public function get dataForPost():Object
        {
            return [palettes];
        }
        
        public function get palettes():Object
        {
            var palettes:Array = [];
            for (var i:uint = 1; i <= MAX_PALETTE; i++) {
                var gridItem:GridItem = GridItem(m_parent["gridItemPalette" + i]);
                palettes.push(gridItem.getStyle("backgroundColor"));
            }
            return { "palettes": palettes };
        }
        
        public function get name():String
        {
            return "penViewController";
        }
        
        public function get parentDisplayObject():DisplayObject
        {
            return m_parent;
        }
        
        public function set palettes(value:Object):void
        {
            for (var i:uint = 1; i <= MAX_PALETTE; i++) {
                var palette:uint = value["palettes"][i - 1];
                var gridItem:GridItem = GridItem(m_parent["gridItemPalette" + i]);
                gridItem.setStyle("backgroundColor", palette);
            }
        }
        
        public function set pen(mode:String):void
        {
            // The "eraser" state retains BlendMode.ERASE so change it forcely
            m_parent.currentState = mode.split(".").pop();
            m_app.setCanvasModule(mode);
        }
        
        public function set currentColor(value:uint):void
        {
            m_app.canvasModule.color = value;
        }
        
        public function set currentAlpha(value:Number):void
        {
            m_app.canvasModule.alpha = value;
        }
        
        public function set currentThickness(value:uint):void
        {
            m_app.canvasModule.thickness = value;
        }
        
        private function onChangeAlpha(event:PenEvent):void
        {
            var pen:Pen = m_app.pen;
            var value:Number = pen.alpha;
            m_parent.alphaSlider.value = value;
            drawPreview(pen.thickness, pen.color, value);
        }
        
        private function onChangeColor(event:PenEvent):void
        {
            var pen:Pen = m_app.pen;
            var value:uint = pen.color;
            m_palette.setStyle("backgroundColor", value);
            drawPreview(pen.thickness, value, pen.alpha);
            m_parent.colRSlider.value = (value & 0xff0000) >> 16;
            m_parent.colGSlider.value = (value & 0x00ff00) >> 8;
            m_parent.colBSlider.value = value & 0x0000ff;
        }
        
        private function onChangeThickness(event:PenEvent):void
        {
            var pen:Pen = m_app.pen;
            var value:uint = pen.thickness;
            m_parent.thicknessSlider.value = value;
            drawPreview(value, pen.color, pen.alpha);
            if (m_parent.currentState == "eraser")
                m_eraserThickness = value;
            else
                m_brushThickness = value;
        }
        
        private function onClosePicker(event:CloseEvent):void
        {
            var picker:SColorPicker = SColorPicker(event.target);
            picker.removeEventListener(CloseEvent.CLOSE, onClosePicker);
            picker.removeEventListener(SPickerEvent.CHANGING, onPicker);
            picker.removeEventListener(SPickerEvent.SWATCH_ADD, onPicker);
            picker.removeEventListener(Event.CHANGE, onPicker);
            PopUpManager.removePopUp(IFlexDisplayObject(event.target));
        }
        
        private function onPicker(event:Event):void
        {
            if (event.type != SPickerEvent.CHANGING &&
                event.type != SPickerEvent.SWATCH_ADD &&
                event.type == Event.CHANGE) {
                currentColor = SColorPicker(event.target).selectedColor;
                PopUpManager.removePopUp(IFlexDisplayObject(event.target));
            }
        }
        
        private function drawPreview(thickness:uint, color:uint, alpha:Number):void
        {
            var preview:Canvas = m_parent.previewCanvas;
            var g:Graphics = preview.graphics;
            g.clear();
            g.beginFill(color, alpha);
            g.drawCircle(preview.width / 2, preview.height / 2, thickness / 2);
            g.endFill();
        }
        
        private function setDefaultPen():void
        {
            pen = String(m_parent.penModeComboBox.value);
        }
        
        public static const MAX_PALETTE:uint = 21;
        
        private const STATE_NONE:uint = 0;
        private const STATE_DROPPER:uint = 1;
        private const STATE_HANDTOOL:uint = 2;
        private const STATE_ERASER:uint = 3;
        private const STATE_DOT:uint = 4;
        private const STATE_OTHER:uint = 5;
        
        private var m_parent:PenView;
        private var m_app:IApplication;
        private var m_palette:GridItem;
        private var m_initPosition:Point;
        private var m_state:uint = STATE_NONE;
        private var m_brushThickness:uint = Pen.DEFAULT_THICKNESS;
        private var m_eraserThickness:uint = Pen.DEFAULT_THICKNESS;
    }
}
