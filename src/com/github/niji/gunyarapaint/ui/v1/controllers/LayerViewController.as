package com.github.niji.gunyarapaint.ui.v1.controllers
{
    import com.github.niji.framework.BitmapLayer;
    import com.github.niji.framework.ILayer;
    import com.github.niji.framework.LayerList;
    import com.github.niji.framework.UndoStack;
    import com.github.niji.framework.events.UndoEvent;
    import com.github.niji.framework.modules.ICanvasModule;
    import com.github.niji.framework.ui.IApplication;
    import com.github.niji.framework.ui.IController;
    import com.github.niji.gunyarapaint.ui.events.CheckBoxEditorEvent;
    import com.github.niji.gunyarapaint.ui.utils.ComponentResizer;
    import com.github.niji.gunyarapaint.ui.v1.views.LayerView;
    
    import flash.display.DisplayObject;
    import flash.geom.Point;
    
    import mx.collections.ArrayCollection;
    import mx.core.IMXMLObject;
    
    public class LayerViewController implements IMXMLObject, IController
    {
        public function initialized(document:Object, id:String):void
        {
            m_parent = LayerView(document);
        }
        
        public function init(app:IApplication):void
        {
            var layers:LayerList = app.layers;
            var currentLayerIndex:uint = layers.currentIndex;
            var currentLayerBlendMode:String = layers.at(currentLayerIndex).blendMode;
            var blendModes:Object = m_parent.blendModeComboBox.dataProvider;
            var blendModeLength:uint = blendModes.length;
            var undo:UndoStack = app.undoStack;
            undo.addEventListener(UndoEvent.UNDO, onChangeUndo);
            undo.addEventListener(UndoEvent.REDO, onChangeUndo);
            m_parent.blendModeComboBox.dataProvider = app.supportedBlendModes;
            m_parent.layerDataGrid.selectedIndex = getSelectedIndex(layers);
            m_parent.alphaSlider.value = layers.at(currentLayerIndex).alpha;
            for (var i:uint = 0; i < blendModeLength; i++) {
                if (blendModes[i].data == currentLayerBlendMode)
                    m_parent.blendModeComboBox.selectedIndex = i;
            }
            m_parent.layerDataGrid.addEventListener(CheckBoxEditorEvent.DATA_CHANGED, onDataChange);
            ComponentResizer.addResize(m_parent, new Point(144, 230));
            m_app = RootViewController(app);
            m_initPosition = new Point(m_parent.x, m_parent.y);
            update();
        }
        
        public function load(data:Object):void
        {
            var point:Object = data.point;
            m_parent.move(point.x, point.y);
            update();
        }
        
        public function save(data:Object):void
        {
            data.point = new Point(m_parent.x, m_parent.y);
        }
        
        public function resetWindow():void
        {
            m_parent.move(m_initPosition.x, m_initPosition.y);
        }
        
        public function update():void
        {
            var layers:LayerList = m_app.layers;
            var layer:BitmapLayer = BitmapLayer(layers.at(layers.currentIndex));
            var currentLayerBlendMode:String = layer.blendMode;
            layers.resetIndex();
            m_parent.layerDataGrid.dataProvider = layers.toDataProvider();
            m_parent.layerDataGrid.selectedIndex = getSelectedIndex(layers);
            m_parent.alphaSlider.value = layer.alpha;
            updateBlendModeComboBox(currentLayerBlendMode);
        }
        
        public function swapEventListener(from:UndoStack, to:UndoStack):void
        {
            from.removeEventListener(UndoEvent.UNDO, onChangeUndo);
            from.removeEventListener(UndoEvent.REDO, onChangeUndo);
            to.addEventListener(UndoEvent.UNDO, onChangeUndo);
            to.addEventListener(UndoEvent.REDO, onChangeUndo);
        }
        
        public function handleSelectLayer(value:Object):void
        {
            var layer:BitmapLayer = BitmapLayer(value);
            if (m_app.layers.currentIndex != layer.index) {
                m_app.canvasModule.layerIndex = layer.index;
                m_parent.alphaSlider.value = layer.alpha;
                updateBlendModeComboBox(layer.blendMode);
            }
        }
        
        public function handleDragStart():void
        {
            m_selectedIndex = getSelectedIndex(m_app.layers);
        }
        
        public function handleDragComplete():void
        {
            var a:Array = ArrayCollection(m_parent.layerDataGrid.dataProvider).toArray().reverse();
            var length:uint = a.length;
            var layers:LayerList = m_app.layers;
            for (var i:uint = 0; i < length; i++) {
                var from:uint = a[i].index;
                var to:uint = layers.at(i).index;
                if (from != to) {
                    m_app.canvasModule.swapLayers(from, to);
                    return;
                }
            }
            // If there is no change a layer, we should restore the selected index.
            // (for example, drags a layer out of the window)
            m_parent.layerDataGrid.selectedIndex = m_selectedIndex;
        }
        
        public function handleCreateLayer():void
        {
            try {
                // should catch AddLayerError here
                m_app.canvasModule.createLayer();
                update();
            } catch (e:Error) {
                m_app.showAlert(e.message, m_parent.title);
            }
        }
        
        public function handleCopyLayer():void
        {
            try {
                // should catch AddLayerError here
                m_app.canvasModule.copyLayer();
                update();
            } catch (e:Error) {
                m_app.showAlert(e.message, m_parent.title);
            }
        }
        
        public function handleRemoveLayer():void
        {
            try {
                // should catch RemoveLayerError here
                m_app.canvasModule.removeLayer();
                update();
            } catch (e:Error) {
                m_app.showAlert(e.message, m_parent.title);
            }
        }
        
        public function handleMergeLayers():void
        {
            try {
                // should catch MergeLayersError here
                m_app.canvasModule.mergeLayers();
                update();
            } catch (e:Error) {
                m_app.showAlert(e.message, m_parent.title);
            }
        }
        
        public function handleChangeAlphaSlider(value:Number):void
        {
            m_app.canvasModule.layerAlpha = value;
        }
        
        public function handleMirrorAllLayersHorizontally():void
        {
            m_app.canvasModule.horizontalMirror(LayerList.ALL_LAYERS)
        }
        
        public function handleMirrorAllLayersVertically():void
        {
            m_app.canvasModule.verticalMirror(LayerList.ALL_LAYERS);
        }
        
        public function get name():String
        {
            return "layerViewController";
        }
        
        public function get parentDisplayObject():DisplayObject
        {
            return m_parent;
        }
        
        public function handleSelectBlendMode(value:String):void
        {
            m_app.canvasModule.layerBlendMode = value;
        }
        
        private function onChangeUndo(event:UndoEvent):void
        {
            update();
        }
        
        private function onDataChange(event:CheckBoxEditorEvent):void
        {
            if (event.column === "visible") {
                var module:ICanvasModule = m_app.canvasModule;
                var layer:ILayer = ILayer(event.data);
                module.setLayerVisible(layer.index, layer.visible);
            }
        }
        
        private function updateBlendModeComboBox(blendMode:String):void
        {
            var ac:ArrayCollection = m_parent.blendModeComboBox.dataProvider as ArrayCollection;
            var length:uint = ac.length;
            for (var i:uint = 0; i < length; i++) {
                if (ac.getItemAt(i).data == blendMode) {
                    m_parent.blendModeComboBox.selectedIndex = i;
                    break;
                }
            }
        }
        
        private function getSelectedIndex(layers:LayerList):uint
        {
            return layers.count - layers.currentIndex - 1;
        }
        
        private var m_parent:LayerView;
        private var m_app:RootViewController;
        private var m_initPosition:Point;
        private var m_selectedIndex:uint;
    }
}
