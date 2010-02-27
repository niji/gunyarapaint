import mx.collections.ArrayCollection;
import mx.events.DragEvent;
import mx.events.FlexEvent;
import mx.events.ListEvent;
import mx.events.SliderEvent;

import org.libspark.gunyarapaint.framework.LayerBitmapCollection;
import org.libspark.gunyarapaint.framework.Painter;
import org.libspark.gunyarapaint.utils.ComponentResizer;

private var m_delegate:IDelegate;

private function init():void
{
    layerDataGrid.addEventListener('describeChange', itemCheckChangeHandler);
    ComponentResizer.addResize(this, new Point(144, 230));
    enabled = false;
}

public function set delegate(value:IDelegate):void
{
    m_delegate = value;
    blendModeComboBox.dataProvider = value.supportedBlendModes;
    enabled = true;
    changeLayer();
    var painter:Painter = value.recorder.painter;
    var layers:LayerBitmapCollection = painter.layers;
    var currentLayerIndex:uint = layers.currentIndex;
    var currentLayerBlendMode:String = painter.currentLayerBlendMode;
    var blendModes:Object = blendModeComboBox.dataProvider;
    var blendModeLength:uint = blendModes.length;
    layerDataGrid.selectedIndex = currentIndex;
    alphaSlider.value = layers.at(currentLayerIndex).alpha;
    for (var i:uint = 0; i < blendModeLength; i++) {
        if (blendModes[i].data == currentLayerBlendMode)
            blendModeComboBox.selectedIndex = i;
    }
}

private function itemClickHandler(evt:ListEvent):void
{
    m_delegate.module.alpha = evt.currentTarget.selectedItem.index;
}

private function itemDoubleClickHandler(evt:ListEvent):void
{
}

public function changeLayer():void
{
    // TODO
    // layerDataGrid.dataProvider = _logger.layerArray.layersForDataProvider;
    var painter:Painter = value.recorder.painter;
    var layers:LayerBitmapCollection = painter.layers;
    var currentLayerBlendMode:String = painter.currentLayerBlendMode;
    var layers:LayerBitmapCollection = value.recorder.painter.layers;
    var layer:LayerBitmap = layers.at(layers.currentIndex);
    layerDataGrid.selectedIndex = layer.index;
    
    var painter:Painter = value.recorder.painter;
    alphaSlider.value = layer.alpha;
    
    var ac:ArrayCollection = blendModeComboBox.dataProvider as ArrayCollection;
    var length:uint = ac.length;
    for (var i:uint = 0; i < length; i++) {
        if (ac.getItemAt(i).data == currentLayerBlendMode) {
            blendModeComboBox.selectedIndex = i;
            return;
        }
    }
}

private function newLayerHandler(evt:Event):void
{
    m_delegate.module.createLayer();
}

private function copyLayerHandler(evt:Event):void
{
    m_delegate.module.copyLayer();
}

private function deleteLayerHandler(evt:Event):void
{
    m_delegate.module.removeLayer();
}

private function mergeLayerHandler(evt:Event):void
{
    m_delegate.module.mergeLayers();
}

private function itemCheckChangeHandler(evt:Event):void
{
    // do nothing...
}

private function alphaSliderHandler(evt:SliderEvent):void
{
    m_delegate.module.layerAlpha = evt.value;
}

private function blendModeComboBoxHandler(evt:ListEvent):void
{
    m_delegate.module.layerBlendMode = String(evt.currentTarget.value);
}

private function dragCompleteHandler(evt:DragEvent):void
{
    var a:Array = (layerDataGrid.dataProvider as ArrayCollection).toArray().reverse();
    var length:uint = a.length;
    var layers:LayerBitmapCollection = value.recorder.painter.layers;
    for (var i:uint = 0; i < length; i++) {
        var from:uint = a[i].index;
        var to:uint = layers.at(i).index;
        if (a[i].index != to) {
            m_delegate.module.swapLayers(from, to);
            break;
        }
    }
}