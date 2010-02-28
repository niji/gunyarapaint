import flash.display.Graphics;
import flash.events.Event;

import mx.containers.GridItem;
import mx.events.FlexEvent;
import mx.events.ListEvent;
import mx.events.SliderEvent;

import org.libspark.gunyarapaint.framework.modules.DrawModuleFactory;

private var m_gridItemPalette:GridItem;
private var m_delegate:IDelegate;

public function set delegate(value:IDelegate):void
{
    m_delegate = value;
    blendModeComboBox.dataProvider = value.supportedBlendModes;
    gridItemPaletteClickHandler(1);
    // 初期値と設定値が一緒なのでイベントが飛んでこない、明示的に呼んであげる
    drawPreview(0x000000, 1, 3);
}

// Ctrlとかのショートカットキーで変わったペンToolを戻す
public function reset():void
{
    if (dropperButton.selected) {
        pen = DrawModuleFactory.DROPPER;
    }
    else if (handtoolButton.selected) {
        currentState = "handtool";
    }
    else if (eraserButton.selected) {
        pen = DrawModuleFactory.ERASER;
        m_delegate.module.blendMode = BlendMode.ERASE;
    }
    else if (dotButton.selected) {
        pen = DrawModuleFactory.PIXEL;
    }
    else {
        pen = String(blendModeComboBox.value);
        m_delegate.module.blendMode = String(blendModeComboBox.value);
    }
}

public function cancel():void
{
    dropperButton.selected = false;
    handtoolButton.selected = false;
    eraserButton.selected = false;
    dotButton.selected = false;
    m_delegate.module = DrawModuleFactory.create(String(blendModeComboBox.value), m_delegate.recorder);
}

public function drawPreview(color:uint, alpha:Number, thickness:uint):void
{
    var g:Graphics = previewCanvas.graphics;
    g.clear();
    g.beginFill(color, alpha);
    g.drawCircle((previewCanvas.width) / 2, (previewCanvas.height) / 2, thickness / 2);
    g.endFill();
}

public function get palettes():Object
{
    var palettes:Array = [];
    for (var i:uint = 1; i < 21; i++) {
        var gridItem:GridItem = GridItem(this["gridItemPalette" + i]);
        palettes.push(gridItem.getStyle("backgroundColor"));
    }
    return { "palettes": palettes };
}

public function set palettes(value:Object):void
{
    for (var i:uint = 1; i < 21; i++) {
        var palette:uint = value["palettes"][i - 1];
        var gridItem:GridItem = GridItem(this["gridItemPalette" + i]);
        gridItem.setStyle("backgroundColor", palette);
    }
}

public function set pen(mode:String):void
{
    currentState = mode;
    m_delegate.module = DrawModuleFactory.create(currentState, m_delegate.recorder);
}

public function set thickness(t:uint):void
{
    m_delegate.module.thickness = thicknessSlider.value = t;
}

private function gridItemPaletteClickHandler(index:uint):void
{
    var palette:GridItem = this["gridItemPalette" + index];
    if (m_gridItemPalette) {
        m_gridItemPalette.setStyle("borderThickness", 1);
        m_gridItemPalette.setStyle("borderColor", 0xb7babc);
    }
    palette.setStyle("borderThickness", 3);
    palette.setStyle("borderColor", 0x000000);
    m_gridItemPalette = palette;
    m_delegate.module.color = m_gridItemPalette.getStyle("backgroundColor");
    setColorRGBSlider(m_gridItemPalette.getStyle("backgroundColor")); // 20090905-haku2 ins
}

private function colorPickerButtonHandler(evt:FlexEvent):void
{
    /*
    // FIXME: お絵かきのログにパレット変更も反映したい
    var picker:SColorPicker = new SColorPicker();
    picker.selectedColor = m_gridItemPalette.getStyle('backgroundColor');
    picker.title = "パレットに入れる色を選んでください。";
    
    // display the 'x' close button
    picker.showCloseButton = true;  
    // picker.add_swatch = true;
    // picker.picker_enabled = true;
    
    picker.addEventListener(CloseEvent.CLOSE, function(event:CloseEvent):void { PopUpManager.removePopUp(IFlexDisplayObject(event.target)); } );
    picker.addEventListener(SPickerEvent.CHANGING, pickerHandler);
    picker.addEventListener(SPickerEvent.SWATCH_ADD, pickerHandler);
    picker.addEventListener(Event.CHANGE, pickerHandler);
    
    PopUpManager.addPopUp(picker, Application.application as DisplayObject, true);
    PopUpManager.centerPopUp(picker);
    */
}

private function pickerHandler(evt:Event):void
{
    /*
    if (evt.type == SPickerEvent.CHANGING) { // avoid bug of component
    }
    else if (evt.type == SPickerEvent.SWATCH_ADD) {
    }
    else if (evt.type == Event.CHANGE) {
        var color:uint = SColorPicker(evt.target).selectedColor;
        m_delegate.module.color = color;
        m_gridItemPalette.setStyle("backgroundColor", color);
        setColRGBSlider(color); // 20090905-haku2 ins
        PopUpManager.removePopUp(IFlexDisplayObject(evt.target));
    }
    */
}

private function handtoolButtonHandler(evt:Event):void
{
    pen = "handtool";
    //setModeHandtool(evt.target.selected);
}

private function dropperButtonHandler(evt:Event):void
{
    pen = DrawModuleFactory.DROPPER;
}

private function eraserButtonHandler(evt:Event):void
{
    pen = DrawModuleFactory.ERASER;
    m_delegate.module.blendMode = BlendMode.ERASE;
}

private function dotButtonHandler(evt:Event):void
{
    pen = DrawModuleFactory.PIXEL;
}

private function penModeComboBoxHandler(evt:ListEvent):void
{
    cancel();
    m_delegate.module = DrawModuleFactory.create(String(evt.currentTarget.value), m_delegate.recorder);
}

private function blendModeComboBoxHandler(evt:ListEvent):void
{
    cancel();
    m_delegate.module.blendMode = String(evt.currentTarget.value);
}

private function thicknessSliderHandler(evt:SliderEvent):void
{
    m_delegate.module.thickness = evt.value;
}

// 選択した色をRGBスライダに反映
private function setColorRGBSlider(color:uint):void
{
    colBSlider.value = color % 256;
    color >>>= 8;
    colGSlider.value = color % 256;
    color >>>= 8;
    colRSlider.value = color % 256;
}

private function colorSliderHandler(evt:SliderEvent, mode:String):void
{
    var color:uint = 0;
    switch (mode) {
        case "red":
            color += evt.value * 65536;
            color += colGSlider.value * 256;
            color += colBSlider.value;
            break;
        case "green":
            color += colRSlider.value * 65536;
            color += evt.value * 256;
            color += colBSlider.value;
            break;
        case "blue":
            color += colRSlider.value * 65536;
            color += colGSlider.value * 256;
            color += evt.value;
            break;
    }
    m_delegate.module.color = color;
    m_gridItemPalette.setStyle('backgroundColor', color);
}

private function alphaSliderHandler(evt:SliderEvent):void
{
    m_delegate.module.alpha = evt.value;
}

// TODO:整理する
public function changePen(mode:String, color:uint, alpha:Number, thickness:uint):void
{
    m_gridItemPalette.setStyle('backgroundColor', color);
    setColorRGBSlider(color);
    drawPreview(color, alpha, thickness);
    
    currentState = mode;
    /*
    switch(mode) {
        case GPPen.PEN_MODE_HAND:
        case GPPen.PEN_MODE_LINE:
        case GPPen.PEN_MODE_CIRCLE:
            thicknessButton1.enabled = true;
            thicknessButton2.enabled = true;
            thicknessButton3.enabled = true;
            thicknessButton4.enabled = true;
            thicknessButton5.enabled = true;
            thicknessSlider.enabled = true;
            alphaSlider.enabled = true;
            blendModeComboBox.enabled = true;
            penModeComboBox.enabled = true;
            paletteGrid.enabled = true;
            break;
        case GPPen.PEN_MODE_DROPPER:
            thicknessButton1.enabled = false;
            thicknessButton2.enabled = false;
            thicknessButton3.enabled = false;
            thicknessButton4.enabled = false;
            thicknessButton5.enabled = false;
            thicknessSlider.enabled = false;
            alphaSlider.enabled = false;
            blendModeComboBox.enabled = false;
            penModeComboBox.enabled = false;
            paletteGrid.enabled = true;
            break;
        case GPPen.PEN_MODE_FLOOD_FILL:
            thicknessButton1.enabled = false;
            thicknessButton2.enabled = false;
            thicknessButton3.enabled = false;
            thicknessButton4.enabled = false;
            thicknessButton5.enabled = false;
            thicknessSlider.enabled = false;
            alphaSlider.enabled = true;
            blendModeComboBox.enabled = true;
            penModeComboBox.enabled = true;
            paletteGrid.enabled = true;
            break;
        case GPPen.PEN_MODE_HANDTOOL:
            thicknessButton1.enabled = false;
            thicknessButton2.enabled = false;
            thicknessButton3.enabled = false;
            thicknessButton4.enabled = false;
            thicknessButton5.enabled = false;
            thicknessSlider.enabled = false;
            alphaSlider.enabled = false;
            blendModeComboBox.enabled = false;
            penModeComboBox.enabled = false;
            paletteGrid.enabled = false;
            break;
        case GPPen.PEN_MODE_ERASER:
            thicknessButton1.enabled = true;
            thicknessButton2.enabled = true;
            thicknessButton3.enabled = true;
            thicknessButton4.enabled = true;
            thicknessButton5.enabled = true;
            thicknessSlider.enabled = true;
            alphaSlider.enabled = true; // 消しゴムはalpha値に対応している。
            blendModeComboBox.enabled = false;
            penModeComboBox.enabled = false;
            paletteGrid.enabled = false;
            break;
        case GPPen.PEN_MODE_PIXEL:
            thicknessButton1.enabled = false;
            thicknessButton2.enabled = false;
            thicknessButton3.enabled = false;
            thicknessButton4.enabled = false;
            thicknessButton5.enabled = false;
            thicknessSlider.enabled = false;
            alphaSlider.enabled = true; // ドット自体のアルファ値となる。
            blendModeComboBox.enabled = false;
            penModeComboBox.enabled = false;
            paletteGrid.enabled = true;
            break;
    }
    */
}

