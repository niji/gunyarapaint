import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.events.Event;

import mx.containers.GridItem;
import mx.core.Application;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.events.ListEvent;
import mx.events.SliderEvent;
import mx.managers.PopUpManager;

import org.libspark.gunyarapaint.controls.IDelegate;

private var gridItemPalette:GridItem;
private var m_delegate:IDelegate;

public function set delegate(value:IDelegate):void
{
    m_delegate = value;
    blendModeComboBox.dataProvider = value.supportedBlendModes;
    gridItemPaletteClickHandler(1);
    // 初期値と設定値が一緒なのでイベントが飛んでこない、明示的に呼んであげる
    drawPreview(GPPen.PEN_MODE_HAND, 0x000000, 1, 3);
}

private function gridItemPaletteClickHandler(index:uint):void
{
    var pal:GridItem = this['gridItemPalette' + index];
    if (gridItemPalette) {
        gridItemPalette.setStyle('borderThickness', 1);
        gridItemPalette.setStyle('borderColor', 0xb7babc);
    }
    pal.setStyle('borderThickness', 3);
    pal.setStyle('borderColor', 0x000000);
    gridItemPalette = pal;
    m_delegate.module.color = gridItemPalette.getStyle('backgroundColor');
    setColRGBSlider(gridItemPalette.getStyle('backgroundColor')); // 20090905-haku2 ins
}

private function colorPickerButtonHandler(evt:FlexEvent):void
{
    // FIXME: お絵かきのログにパレット変更も反映したい
    var picker:SColorPicker = new SColorPicker();
    picker.selectedColor = gridItemPalette.getStyle('backgroundColor');
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
}

private function pickerHandler(evt:Event):void
{
    if (evt.type == SPickerEvent.CHANGING) { // avoid bug of component
    }
    else if (evt.type == SPickerEvent.SWATCH_ADD) {
    }
    else if (evt.type == Event.CHANGE) {
        var color:uint = SColorPicker(evt.target).selectedColor;
        _logger.eventLineStyleColor(color);
        gridItemPalette.setStyle('backgroundColor', color);
        setColRGBSlider(color); // 20090905-haku2 ins
        PopUpManager.removePopUp(IFlexDisplayObject(evt.target));
    }
}

// Ctrlとかのショートカットキーで変わったペンToolを戻す
public function resetPenTool():void
{
    if (dropperButton.selected) {
        setModeDropper(true);
    } else if (handtoolButton.selected) {
        setModeHandtool(true);
    } else if (eraserButton.selected) {
        setModeEraser(true);    
    } else if (dotButton.selected) {
        setModePixel(true);
    } else {
        _logger.eventSetPenMode(uint(penModeComboBox.value));
    }
}

// TODO: こいつらをスッキリまとめるべきでーす。
private function setModeDropper(selected:Boolean):void {
    handtoolButton.selected = false;
    eraserButton.selected = false;
    dotButton.selected = false;
    setTool(GPPen.PEN_MODE_DROPPER, null, selected);  
}

private function dropperButtonHandler(evt:Event):void {
    setModeDropper(evt.target.selected);
}

private function setModeHandtool(selected:Boolean):void
{
    dropperButton.selected = false;
    eraserButton.selected = false;
    dotButton.selected = false;
    setTool(GPPen.PEN_MODE_HANDTOOL, null, selected);
}

private function handtoolButtonHandler(evt:Event):void
{
    setModeHandtool(evt.target.selected);
}

private function setModeEraser(selected:Boolean):void
{
    handtoolButton.selected = false;
    dropperButton.selected = false;
    dotButton.selected = false;
    setTool(GPPen.PEN_MODE_ERASER, BlendMode.ERASE, selected);
}

private function eraserButtonHandler(evt:Event):void
{
    setModeEraser(evt.target.selected);
}

private function setModePixel(selected:Boolean):void
{
    handtoolButton.selected = false;
    eraserButton.selected = false;
    dropperButton.selected = false;
    // TODO: pen太さ
    setTool(GPPen.PEN_MODE_PIXEL, null, selected);  
}

private function dotButtonHandler(evt:Event):void
{
    setModePixel(evt.target.selected);
}

public function cancelTool():void
{
    dropperButton.selected = false;
    handtoolButton.selected = false;
    eraserButton.selected = false;
    _logger.eventSetPenMode(uint(penModeComboBox.value));
}

public function setTool(penMode:uint, penBlendMode:String, b:Boolean):void
{
    if (b) {
        if (penMode)
            _logger.eventSetPenMode(penMode);
        if (penBlendMode)
            m_delegate.module.blendMode = penBlendMode;
    }
    else {
        _logger.eventSetPenMode(uint(penModeComboBox.value));
        m_delegate.module.blendMode = String(blendModeComboBox.value);
    }
}

private function penModeComboBoxHandler(evt:ListEvent):void
{
    cancelTool();
    _logger.eventSetPenMode(uint(evt.currentTarget.value));
}

private function blendModeComboBoxHandler(evt:ListEvent):void
{
    cancelTool();
    m_delegate.module.blendMode = String(evt.currentTarget.value);
}

private function thicknessSliderHandler(evt:SliderEvent):void
{
    m_delegate.module.thickness = evt.value;
}

private function changeThickness(t:uint):void
{
    thicknessSlider.value = t;
    m_delegate.module.thickness = t;
}

// 20090905-haku2 ins start
// 選択した色をRGBスライダに反映
private function setColRGBSlider(color:uint):void
{
    colBSlider.value = color % 256;
    color >>>= 8;
    colGSlider.value = color % 256;
    color >>>= 8;
    colRSlider.value = color % 256;
}

// RGB直指定スライダ
private function colRSliderHandler(evt:SliderEvent):void
{
    var color:uint = 0;
    color += evt.value * 65536;
    color += colGSlider.value * 256;
    color += colBSlider.value;
    m_delegate.module.color = color;
    gridItemPalette.setStyle('backgroundColor', color);
}

private function colGSliderHandler(evt:SliderEvent):void
{
    var color:uint = 0;
    color += colRSlider.value * 65536;
    color += evt.value * 256;
    color += colBSlider.value;
    m_delegate.module.color = color;
    gridItemPalette.setStyle('backgroundColor', color);
}

private function colBSliderHandler(evt:SliderEvent):void
{
    var color:uint = 0;
    color += colRSlider.value * 65536;
    color += colGSlider.value * 256;
    color += evt.value;
    m_delegate.module.color = color;
    gridItemPalette.setStyle('backgroundColor', color);
}
// 20090905-haku2 ins end

private function alphaSliderHandler(evt:SliderEvent):void
{
    m_delegate.module.alpha = evt.value;
}

// 20081115-haku2 ins start
public function setPenSize(v:uint):void
{
    changeThickness(v);
}
// 20081115-haku2 ins end

// TODO:整理する
public function changePen(mode:uint, color:uint, alpha:Number, thickness:uint):void
{
    gridItemPalette.setStyle('backgroundColor', color);
    setColRGBSlider(color); // 20090905-haku2 ins
    drawPreview(mode, color, alpha, thickness);
    
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
}

public function drawPreview(mode:uint, color:uint, alpha:Number, thickness:uint):void
{
    var g:Graphics = previewCanvas.graphics;
    g.clear();
    g.beginFill(color, alpha);
    g.drawCircle((previewCanvas.width) / 2,
        (previewCanvas.height) / 2,
        thickness / 2);
    g.endFill();
}

public function get dataForPost():Object
{
    return {
        'palettes': [
            gridItemPalette1.getStyle('backgroundColor'),
            gridItemPalette2.getStyle('backgroundColor'),
            gridItemPalette3.getStyle('backgroundColor'),
            gridItemPalette4.getStyle('backgroundColor'),
            gridItemPalette5.getStyle('backgroundColor'),
            gridItemPalette6.getStyle('backgroundColor'),
            gridItemPalette7.getStyle('backgroundColor'),
            gridItemPalette8.getStyle('backgroundColor'),
            gridItemPalette9.getStyle('backgroundColor'),
            gridItemPalette10.getStyle('backgroundColor'),
            gridItemPalette11.getStyle('backgroundColor'),
            gridItemPalette12.getStyle('backgroundColor'),
            gridItemPalette13.getStyle('backgroundColor'),
            gridItemPalette14.getStyle('backgroundColor'),
            gridItemPalette15.getStyle('backgroundColor'),
            gridItemPalette16.getStyle('backgroundColor'),
            gridItemPalette17.getStyle('backgroundColor'),
            gridItemPalette18.getStyle('backgroundColor'),
            gridItemPalette19.getStyle('backgroundColor'),
            gridItemPalette20.getStyle('backgroundColor'),
            gridItemPalette21.getStyle('backgroundColor')
        ]
    };
}

public function set baseImgInfo(o:Object):void
{
    gridItemPalette1.setStyle('backgroundColor', o['palettes'][0]);
    gridItemPalette2.setStyle('backgroundColor', o['palettes'][1]);
    gridItemPalette3.setStyle('backgroundColor', o['palettes'][2]);
    gridItemPalette4.setStyle('backgroundColor', o['palettes'][3]);
    gridItemPalette5.setStyle('backgroundColor', o['palettes'][4]);
    gridItemPalette6.setStyle('backgroundColor', o['palettes'][5]);
    gridItemPalette7.setStyle('backgroundColor', o['palettes'][6]);
    gridItemPalette8.setStyle('backgroundColor', o['palettes'][7]);
    gridItemPalette9.setStyle('backgroundColor', o['palettes'][8]);
    gridItemPalette10.setStyle('backgroundColor', o['palettes'][9]);
    gridItemPalette11.setStyle('backgroundColor', o['palettes'][10]);
    gridItemPalette12.setStyle('backgroundColor', o['palettes'][11]);
    gridItemPalette13.setStyle('backgroundColor', o['palettes'][12]);
    gridItemPalette14.setStyle('backgroundColor', o['palettes'][13]);
    gridItemPalette15.setStyle('backgroundColor', o['palettes'][14]);
    gridItemPalette16.setStyle('backgroundColor', o['palettes'][15]);
    gridItemPalette17.setStyle('backgroundColor', o['palettes'][16]);
    gridItemPalette18.setStyle('backgroundColor', o['palettes'][17]);
    gridItemPalette19.setStyle('backgroundColor', o['palettes'][18]);
    gridItemPalette20.setStyle('backgroundColor', o['palettes'][19]);
    gridItemPalette21.setStyle('backgroundColor', o['palettes'][20]);
}