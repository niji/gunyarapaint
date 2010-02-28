import mx.collections.ArrayCollection;
import mx.events.DragEvent;
import mx.events.ListEvent;
import mx.events.SliderEvent;

import org.libspark.gunyarapaint.framework.LayerBitmap;
import org.libspark.gunyarapaint.framework.LayerBitmapCollection;
import org.libspark.gunyarapaint.framework.Painter;
import org.libspark.gunyarapaint.utils.ComponentResizer;
import org.libspark.gunyarapaint.controls.IDelegate;

private var m_delegate:IDelegate;

public function change():void
{
    // TODO
    // layerDataGrid.dataProvider = _logger.layerArray.layersForDataProvider;
    var painter:Painter = m_delegate.recorder.painter;
    var layers:LayerBitmapCollection = painter.layers;
    var layer:LayerBitmap = layers.at(layers.currentIndex);
    var currentLayerBlendMode:String = layer.blendMode;
    layerDataGrid.selectedIndex = layer.index;
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

public function set delegate(value:IDelegate):void
{
    m_delegate = value;
    blendModeComboBox.dataProvider = value.supportedBlendModes;
    enabled = true;
    changeLayer();
    var painter:Painter = value.recorder.painter;
    var layers:LayerBitmapCollection = painter.layers;
    var currentLayerIndex:uint = layers.currentIndex;
    var currentLayerBlendMode:String = layers.at(currentLayerIndex).blendMode;
    var blendModes:Object = blendModeComboBox.dataProvider;
    var blendModeLength:uint = blendModes.length;
    layerDataGrid.selectedIndex = currentLayerIndex;
    alphaSlider.value = layers.at(currentLayerIndex).alpha;
    for (var i:uint = 0; i < blendModeLength; i++) {
        if (blendModes[i].data == currentLayerBlendMode)
            blendModeComboBox.selectedIndex = i;
    }
}

private function init():void
{
    layerDataGrid.addEventListener('describeChange', itemCheckChangeHandler);
    ComponentResizer.addResize(this, new Point(144, 230));
    enabled = false;
}

private function itemClickHandler(evt:ListEvent):void
{
    m_delegate.module.alpha = evt.currentTarget.selectedItem.index;
}

private function itemDoubleClickHandler(evt:ListEvent):void
{
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
    var layers:LayerBitmapCollection = m_delegate.recorder.painter.layers;
    for (var i:uint = 0; i < length; i++) {
        var from:uint = a[i].index;
        var to:uint = layers.at(i).index;
        if (a[i].index != to) {
            m_delegate.module.swapLayers(from, to);
            break;
        }
    }
}