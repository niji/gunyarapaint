package com.github.niji.gunyarapaint.ui.v1.controllers
{
    import com.adobe.images.PNGEncoder;
    import com.adobe.serialization.json.JSON;
    import com.adobe.serialization.json.JSONParseError;
    import com.github.niji.framework.LayerList;
    import com.github.niji.framework.Marshal;
    import com.github.niji.framework.Pen;
    import com.github.niji.framework.Recorder;
    import com.github.niji.framework.UndoStack;
    import com.github.niji.framework.events.CommandEvent;
    import com.github.niji.framework.i18n.TranslatorRegistry;
    import com.github.niji.framework.modules.CanvasModuleContext;
    import com.github.niji.framework.modules.CircleModule;
    import com.github.niji.framework.modules.DropperModule;
    import com.github.niji.framework.modules.FloodFillModule;
    import com.github.niji.framework.modules.FreeHandModule;
    import com.github.niji.framework.modules.ICanvasModule;
    import com.github.niji.framework.modules.LineModule;
    import com.github.niji.framework.modules.PixelModule;
    import com.github.niji.framework.ui.IApplication;
    import com.github.niji.framework.ui.IController;
    import com.github.niji.gunyarapaint.ui.errors.DecryptError;
    import com.github.niji.gunyarapaint.ui.events.CanvasModuleEvent;
    import com.github.niji.gunyarapaint.ui.i18n.GetTextTranslator;
    import com.github.niji.gunyarapaint.ui.v1.MovableCanvasModule;
    import com.github.niji.gunyarapaint.ui.v1.PNGExporter;
    import com.github.niji.gunyarapaint.ui.v1.net.Parameters;
    import com.github.niji.gunyarapaint.ui.v1.views.CopyrightView;
    import com.hurlant.crypto.Crypto;
    import com.hurlant.crypto.symmetric.ICipher;
    import com.hurlant.crypto.symmetric.IPad;
    import com.hurlant.crypto.symmetric.IVMode;
    import com.hurlant.crypto.symmetric.PKCS5;
    import com.rails2u.gettext.GetText;
    
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.BlendMode;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.errors.IllegalOperationError;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.KeyboardEvent;
    import flash.events.SecurityErrorEvent;
    import flash.external.ExternalInterface;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.ui.Keyboard;
    import flash.utils.ByteArray;
    
    import mx.controls.Alert;
    import mx.core.IFlexDisplayObject;
    import mx.core.IMXMLObject;
    import mx.core.UITextField;
    import mx.events.CloseEvent;
    import mx.managers.PopUpManager;
    import mx.utils.SHA256;
    
    public class RootViewController implements IMXMLObject, IApplication
    {
        public function initialized(document:Object, id:String):void
        {
            m_root = gunyarapaint(document);
        }
        
        /**
         * @copy flash.events.IEventDispatcher#addEventListener()
         */
        public function addEventListener(type:String,
                                         listener:Function,
                                         useCapture:Boolean = false,
                                         priority:int = 0,
                                         useWeakReference:Boolean = false):void
        {
            m_root.addEventListener(type, listener, useCapture, priority, useWeakReference);
        }
        
        /**
         * @copy flash.events.IEventDispatcher#removeEventListener()
         */
        public function removeEventListener(type:String,
                                            listener:Function,
                                            useCapture:Boolean = false):void
        {
            m_root.removeEventListener(type, listener, useCapture);
        }
        
        /**
         * @copy flash.events.IEventDispatcher#dispatchEvent()
         */
        public function dispatchEvent(event:Event):Boolean
        {
            return m_root.dispatchEvent(event);
        }
        
        /**
         * @copy flash.events.IEventDispatcher#hasEventListener()
         */
        public function hasEventListener(type:String):Boolean
        {
            return m_root.hasEventListener(type);
        }
        
        /**
         * @copy flash.events.IEventDispatcher#willTrigger()
         */
        public function willTrigger(type:String):Boolean
        {
            return m_root.willTrigger(type);
        }
        
        public function resetWindowsPosition():void
        {
            for (var i:String in m_windows) {
                m_windows[i].resetWindow();
            }
        }
        
        public function setCanvasModule(value:String):void
        {
            if (hasEventListener(CanvasModuleEvent.BEFORE_CHANGE))
                dispatchEvent(new CanvasModuleEvent(CanvasModuleEvent.BEFORE_CHANGE));
            m_module.unload();
            m_module = m_context.getModule(value);
            if (m_module == null) {
                throw new IllegalOperationError(value
                    + " is not the ICanvasModule implemented module");
            }
            m_module.load();
            if (hasEventListener(CanvasModuleEvent.AFTER_CHANGE))
                dispatchEvent(new CanvasModuleEvent(CanvasModuleEvent.AFTER_CHANGE));
        }
        
        public function newMarshal(metadata:Object):Marshal
        {
            return new Marshal(m_recorder, m_windows, metadata);
        }
        
        public function load(bytes:ByteArray, password:String):void
        {
            var metadata:Object = {};
            var cipher:ICipher = getCipherFromPassword(password);
            if (cipher is IVMode) {
                IVMode(cipher).IV = bytes.readObject();
            }
            var data:ByteArray = ByteArray(bytes.readObject());
            try {
                cipher.decrypt(data);
            } catch (e:Error) {
                throw new DecryptError(e.message);
            }
            newMarshal(metadata).load(data, m_bytes);
            m_module.reset();
        }
        
        public function save(bytes:ByteArray, password:String):void
        {
            var metadata:Object = {};
            var data:ByteArray = new ByteArray();
            var cipher:ICipher = getCipherFromPassword(password);
            newMarshal(metadata).save(data, m_bytes);
            cipher.encrypt(data);
            if (cipher is IVMode) {
                bytes.writeObject(IVMode(cipher).IV);
            }
            bytes.writeObject(data);
        }
        
        public function fillParameters(param:Parameters):void
        {
            var parameters:Object = m_root.parameters;
            if (!m_development && commitCount == 0)
                throw new ArgumentError(_("The canvas is not drawn. You should draw the canvas."));
            if (!parameters.postUrl    ||
                !parameters.cookie     ||
                !parameters.magic      ||
                !parameters.redirectUrl)
                throw new ArgumentError(_("Request cannot accept for the invalid state. This error should not be occured"));
            var layers:LayerList = m_recorder.layers;
            var bitmapData:BitmapData = getBitmap();
            var layerBitmap:BitmapData = layers.newLayerBitmapData;
            var metadata:Object = {};
            layers.save(layerBitmap, metadata);
            metadata.log_count = commitCount;
            metadata.pen_details = m_root.penView.controller.dataForPost;
            metadata.undo_buffer_size = m_recorder.undoStack.size;
            param.cookie = parameters.cookie;
            param.magic = parameters.magic;
            param.refererId = parameters.oekakiId;
            param.imageBytes = PNGEncoder.encode(bitmapData);
            param.layerImageBytes = PNGEncoder.encode(layerBitmap);
            param.logBytes = m_recorder.newBytes();
            param.logCount = commitCount;
            param.metadata = metadata;
            bitmapData.dispose();
        }
        
        public function showAlert(message:String, title:String):void
        {
            m_lockHandlingKeyboard = true;
            Alert.show(message, title, Alert.OK, null, onClose);
        }
        
        public function getParameter(key:String):String
        {
            return m_root.parameters[key];
        }
        
        public function handleApplicationComplete():void
        {
            var parameters:Object = m_root.parameters;
            if (m_development)
                m_root.versionLabel.text += " with development mode";
            var oekakiId:uint = uint(parameters["oekakiId"]);
            if (oekakiId > 0 && parameters["baseImgUrl"]) {
                var loader:Loader = new Loader();
                addLoaderEvents(loader.contentLoaderInfo);
                loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadImage);
                loader.load(new URLRequest(parameters.baseImgUrl));
                m_root.loadingDialog.title = _("Loading the image layers...");
            }
            else {
                // It's not continued
                var width:int = int(parameters["canvasWidth"]);
                var height:int = int(parameters["canvasHeight"]);
                m_root.enabled = postInitialize(width, height);
            }
        }
        
        public function handlePreinitialize():void
        {
            var configXml:XML = new XML(new m_root.config());
            if (configXml.@stage != "production") {
                for each (var item:XML in configXml.children()) {
                    m_root.parameters[item.name()] = item.toString();
                }
                m_development = true;
            }
            // The default state is disabled
            m_root.enabled = false;
            GetText.locale = m_root.parameters["language"] || "ja_jp";
            GetText.initLangFile(new XML(new m_root.languages()));
            TranslatorRegistry.install(new GetTextTranslator());
            m_title = _("Oekakiko");
            m_blendModes = [
                { "label": _("Normal"),     "data": BlendMode.NORMAL     },
                { "label": _("Darken"),     "data": BlendMode.DARKEN     },
                { "label": _("Multiply"),   "data": BlendMode.MULTIPLY   },
                { "label": _("Lighten"),    "data": BlendMode.LIGHTEN    },
                { "label": _("Screen"),     "data": BlendMode.SCREEN     },
                { "label": _("Add"),        "data": BlendMode.ADD        },
                { "label": _("Overlay"),    "data": BlendMode.OVERLAY    },
                { "label": _("Hardlight"),  "data": BlendMode.HARDLIGHT  },
                { "label": _("Difference"), "data": BlendMode.DIFFERENCE },
                { "label": _("Subtract"),   "data": BlendMode.SUBTRACT   },
                { "label": _("Invert"),     "data": BlendMode.INVERT     },
            ];
        }
        
        public function handleClickImage():void
        {
            PopUpManager.addPopUp(new CopyrightView(), m_root, true);
        }
        
        public function get canvasModule():ICanvasModule
        {
            return m_module;
        }
        
        public function get canvasModuleName():String
        {
            switch (m_module.name) {
                case CircleModule.CIRCLE:
                    return _("Circle module");
                case DropperModule.DROPPER:
                    return _("Dropper module");
                case FloodFillModule.FLOOD_FILL:
                    return _("Flood fill module");
                case FreeHandModule.FREE_HAND:
                    return _("Freehand (or Eraser) module");
                case LineModule.LINE:
                    return _("Line module");
                case PixelModule.PIXEL:
                    return _("Pixel module");
                default:
                    return _("Unknown module");
            }
        }
        
        public function get supportedBlendModes():Array
        {
            return m_blendModes.slice();
        }
        
        public function get layers():LayerList
        {
            return m_recorder.layers;
        }
        
        public function get pen():Pen
        {
            return m_recorder.pen;
        }
        
        public function get undoStack():UndoStack
        {
            return m_recorder.undoStack;
        }
        
        public function get parentView():IFlexDisplayObject
        {
            return m_root;
        }
        
        public function get canvasWidth():uint
        {
            return m_recorder.width;
        }
        
        public function get canvasHeight():uint
        {
            return m_recorder.height;
        }
        
        public function get commitCount():uint
        {
            return m_commit;
        }
        
        public function get enabledDevelopmentSupport():Boolean
        {
            return m_development;
        }
        
        public function get hashForSharedObject():String
        {
            var params:Object = m_root.parameters;
            var keyBytes:ByteArray = new ByteArray();
            keyBytes.writeUTF(String(params.page_id));
            keyBytes.writeUTF(String(params.user_id));
            return SHA256.computeDigest(keyBytes);
        }
        
        public function set shouldAlertOnUnload(value:Boolean):void
        {
            if (ExternalInterface.available) {
                try {
                    ExternalInterface.call("changeAlertOnUnload", value);
                }
                catch (e:Error) {
                    Alert.show(e.message, m_title);
                }
            }
        }
        
        private function restoreCanvas(metadata:Object):void
        {
            var width:int = metadata.width;
            var height:int = metadata.height;
            var ready:Boolean = postInitialize(width, height);
            // If ready is false, an error has occured.
            if (ready) {
                m_lockHandlingKeyboard = true;
                var from:UndoStack = m_recorder.undoStack;
                m_recorder.load(m_baseImage, metadata);
                var to:UndoStack = m_recorder.undoStack;
                if (metadata.pen_details != null)
                    m_root.penView.controller.palettes = metadata.pen_details[0];
                m_root.toolView.controller.swapEventListener(from, to);
                m_root.layerView.controller.swapEventListener(from, to);
                m_root.layerView.controller.update();
                m_root.enabled = ready;
                m_lockHandlingKeyboard = false;
            }
        }
        
        private function postInitialize(width:int, height:int):Boolean
        {
            var undoBufferSize:int = int(m_root.parameters["undoBufferSize"]);
            if (undoBufferSize < 1) {
                showAlert(_("Too small count of the max of undo." +
                    "(required is %s and minimum is %s)",
                    undoBufferSize, 1), m_title);
                return false;
            }
            else if (undoBufferSize > 32) {
                showAlert(_("Too many count of the max of undo." +
                    "(required is %s and maximum is %s)", undoBufferSize, 32), m_title);
                return false;
            }
            else if (width < MIN_CANVAS_WIDTH || height < MIN_CANVAS_HEIGHT) {
                showAlert(_("Too small size of the canvas." +
                    "(required is %s x %s and minimum is %s x %s)",
                    width, height, MIN_CANVAS_WIDTH, MIN_CANVAS_HEIGHT), m_title);
                return false;
            }
            else if (width > MAX_CANVAS_WIDTH || height > MAX_CANVAS_HEIGHT) {
                showAlert(_("Too big size of the canvas." +
                    "(required is %s x %s and minimum is %s x %s)",
                    width, height, MAX_CANVAS_WIDTH, MAX_CANVAS_HEIGHT), m_title);
                return false;
            }
            m_bytes = new ByteArray();
            m_recorder = Recorder.create(m_bytes, width, height, undoBufferSize);
            m_context = new CanvasModuleContext(m_recorder);
            m_module = m_context.getModule(FreeHandModule.FREE_HAND);
            m_commit = 0;
            m_recorder.addEventListener(CommandEvent.COMMITTED, onCommit);
            m_context.registerModule(new MovableCanvasModule(m_recorder, m_root.canvasController));
            m_exporter = new PNGExporter();
            m_exporter.addEventListener(Event.COMPLETE, onExportComplete);
            m_windows = new Vector.<IController>(5, true);
            m_windows[0] = m_root.canvasController;
            m_windows[1] = m_root.penView.controller;
            m_windows[2] = m_root.layerView.controller;
            m_windows[3] = m_root.toolView.controller;
            m_windows[4] = m_root.formView.controller;
            m_lockHandlingKeyboard = false;
            for (var i:String in m_windows) {
                var controller:IController = m_windows[i];
                controller.init(this);
                PopUpManager.addPopUp(IFlexDisplayObject(controller.parentDisplayObject), m_root);
            }
            m_root.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            m_root.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
            return true;
        }
        
        private function addLoaderEvents(loader:EventDispatcher):void
        {
            m_root.loadingDialog.visible = true;
            m_root.loadingDialog.centerize(m_root);
            m_root.loadingDialog.setProgressSource(loader);
            PopUpManager.addPopUp(m_root.loadingDialog, m_root);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
            loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
        }
        
        private function removeLoaderEvents(loader:EventDispatcher):void
        {
            m_root.loadingDialog.visible = false;
            PopUpManager.removePopUp(m_root.loadingDialog);
            loader.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
            loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
        }
        
        private function getCipherFromPassword(password:String):ICipher
        {
            var keyBytes:ByteArray = new ByteArray();
            var pad:IPad = new PKCS5();
            var cipher:ICipher = null;
            keyBytes.writeUTF(hashForSharedObject);
            keyBytes.writeUTF(password);
            cipher = Crypto.getCipher("aes256-cbc", keyBytes, pad);
            return cipher;
        }
        
        private function getBitmap():BitmapData
        {
            var layers:LayerList = m_recorder.layers;
            var bitmapData:BitmapData = new BitmapData(layers.width, layers.height, true, 0);
            bitmapData.draw(layers.view);
            return bitmapData;
        }
        
        private function onCommit(event:CommandEvent):void
        {
            //trace(event.command);
            m_commit++;
        }
        
        private function onKeyDown(event:KeyboardEvent):void
        {
            if (m_lockHandlingKeyboard || isForcusedOnTextField)
                return;
            var keyCode:uint = event.keyCode;
            var toolViewController:ToolViewController = m_root.toolView.controller;
            var penViewController:PenViewController = m_root.penView.controller;
            switch (keyCode) {
                case Keyboard.CONTROL:
                    penViewController.saveSelectedState();
                    penViewController.pen = DropperModule.DROPPER;
                    break;
                case Keyboard.SPACE:
                    penViewController.saveSelectedState();
                    penViewController.pen = MovableCanvasModule.MOVABLE_CANVAS;
                    break;
                case 48: // 0
                case 96: // ten-key 0
                    if (event.shiftKey)
                        toolViewController.setRotate(0);
                    else
                        toolViewController.setZoom(1);
                    break;
                case 65: // a (pressing)
                    m_module.shouldDrawCircleClockwise = true;
                    break;
                case 73: // i
                    resetWindowsPosition();
                    break;
                case 77: // m
                    m_module.horizontalMirror(LayerList.ALL_LAYERS);
                    break;
                case 81: // q (pressing)
                    m_module.shouldDrawCircleCounterClockwise = true;
                    break;
                case 82: // r (pressing)
                    m_module.shouldDrawFromEndPoint = true;
                    break;
                case 84: // t (pressing)
                    m_module.shouldDrawFromStartPoint = true;
                    break;
                case 88: // x
                    var bitmapData:BitmapData = getBitmap();
                    m_exporter.save(bitmapData);
                    bitmapData.dispose();
                    break;
                case 89: // y
                    try {
                        m_module.redo();
                    }
                    catch (e:Error) {
                        showAlert(e.message, m_title);
                    }
                    break;
                case 90: // z
                    try {
                        m_module.undo();
                    }
                    catch (e:Error) {
                        showAlert(e.message, m_title);
                    }
                    break;
                case 107: // ten key +
                    // +
                    m_root.toolView.controller.setZoom(m_root.toolView.canvasZoom.value + 1);
                    break;
                case 109: // ten key -
                    // -
                    m_root.toolView.controller.setZoom(m_root.toolView.canvasZoom.value - 1);
                    break;
                case 187:
                    // +
                    if (event.shiftKey)
                        m_root.toolView.controller.setZoom(m_root.toolView.canvasZoom.value + 1);
                    break;
                case 189:
                    // -
                    m_root.toolView.controller.setZoom(m_root.toolView.canvasZoom.value - 1);
                    break;
                case 49: // 1
                case 50: // 2
                case 51: // 3
                case 52: // 4
                case 53: // 5
                case 54: // 6
                case 55: // 7
                case 56: // 8
                case 57: // 9
                    // SHIFT + (NUM) is reserved
                    if (!event.shiftKey)
                        penViewController.currentThickness = keyCode - 48;
                    break;
                case 97: // ten-key 1
                case 98: // ten-key 2
                case 99: // ten-key 3
                case 100: // ten-key 4
                case 101: // ten-key 5
                case 102: // ten-key 6
                case 103: // ten-key 7
                case 104: // ten-key 8
                case 105: // ten-key 9
                    penViewController.currentThickness = keyCode - 96;
                    break;
                case 45: // INS
                    // INS + SHIFT is reserved
                    if (!event.shiftKey)
                        toolViewController.setRotate(0);
                    break;
            }
        }
        
        private function onKeyUp(evt:KeyboardEvent):void
        {
            if (m_lockHandlingKeyboard || isForcusedOnTextField)
                return;
            switch (evt.keyCode) {
                case Keyboard.CONTROL:
                case Keyboard.SPACE:
                    m_root.penView.controller.loadSelectedState();
                    break;
                case 65: // a (released)
                    m_module.shouldDrawCircleClockwise = false;
                    break;
                case 81: // q (released)
                    m_module.shouldDrawCircleCounterClockwise = false;
                    break;
                case 82: // r (released)
                    m_module.shouldDrawFromEndPoint = false;
                    break;
                case 84: // t (released)
                    m_module.shouldDrawFromStartPoint = false;
                    break;
            }
        }
        
        private function onClose(event:CloseEvent):void
        {
            m_lockHandlingKeyboard = false;
        }
        
        private function onExportComplete(event:Event):void
        {
            showAlert(_("Exporting the bitmap of the canvas to PNG has been completed."), m_title);
        }
        
        private function onLoadImage(event:Event):void
        {
            var loaderInfo:LoaderInfo = LoaderInfo(event.target);
            loaderInfo.removeEventListener(Event.COMPLETE, onLoadImage);
            removeLoaderEvents(loaderInfo);
            m_baseImage = Bitmap(loaderInfo.content).bitmapData;
            if (m_root.parameters["baseImgInfoUrl"]) {
                // from continued
                var loader:URLLoader = new URLLoader();
                addLoaderEvents(loader);
                loader.addEventListener(Event.COMPLETE, onLoadImageInfo);
                loader.load(new URLRequest(m_root.parameters.baseImgInfoUrl));
                m_root.loadingDialog.title = _("Loading the image metadata...");
            }
            else {
                // FIXME: Should be removed?
                var metadata:Object = {
                    "width": m_baseImage.width,
                        "height": m_baseImage.height
                };
                restoreCanvas(metadata);
            }
        }
        
        private function onLoadImageInfo(event:Event):void
        {
            var loader:URLLoader = URLLoader(event.target);
            var metadata:Object = null;
            loader.removeEventListener(Event.COMPLETE, onLoadImageInfo);
            removeLoaderEvents(loader);
            try {
                metadata = JSON.decode(String(loader.data));
                restoreCanvas(metadata);
            }
            catch (e:JSONParseError) {
                // should not be occured
                showAlert(e.message, e.name);
            }
        }
        
        private function onIOError(event:IOErrorEvent):void
        {
            removeLoaderEvents(EventDispatcher(event.target));
            showAlert(_("IO error has occured. Try again: %s", event.text), event.type);
        }
        
        private function onSecurityError(event:SecurityErrorEvent):void
        {
            removeLoaderEvents(EventDispatcher(event.target));
            showAlert(_("Security error has occured. This error should not be occured: %s", event.text), event.type);
        }
        
        private function get isForcusedOnTextField():Boolean
        {
            return m_root.stage.focus is mx.core.UITextField;
        }
        
        private const MAX_CANVAS_WIDTH:uint = 500;
        private const MAX_CANVAS_HEIGHT:uint = 500;
        private const MIN_CANVAS_WIDTH:uint = 8;
        private const MIN_CANVAS_HEIGHT:uint = 8;
        
        private var m_root:gunyarapaint;
        private var m_baseImage:BitmapData;
        private var m_bytes:ByteArray;
        private var m_recorder:Recorder;
        private var m_context:CanvasModuleContext;
        private var m_module:ICanvasModule;
        private var m_exporter:PNGExporter;
        private var m_commit:uint;
        private var m_windows:Vector.<IController>;
        private var m_title:String;
        private var m_blendModes:Array;
        private var m_development:Boolean;
        private var m_lockHandlingKeyboard:Boolean;
    }
}
