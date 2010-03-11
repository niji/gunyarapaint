private const DEBUG:Boolean = true;

import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.ui.Keyboard;
import flash.utils.ByteArray;

import mx.controls.Alert;
import mx.core.UITextField;
import mx.events.FlexEvent;
import mx.events.ListEvent;
import mx.events.NumericStepperEvent;
import mx.events.SliderEvent;
import mx.managers.PopUpManager;

import org.libspark.gunyarapaint.controls.MovingCanvasModule;
import org.libspark.gunyarapaint.controls.GPPasswordWindowControl;
import org.libspark.gunyarapaint.framework.LayerBitmapCollection;
import org.libspark.gunyarapaint.framework.Pen;
import org.libspark.gunyarapaint.framework.Recorder;
import org.libspark.gunyarapaint.framework.events.CommandEvent;
import org.libspark.gunyarapaint.framework.events.UndoEvent;
import org.libspark.gunyarapaint.framework.modules.CanvasModuleContext;
import org.libspark.gunyarapaint.framework.modules.DropperModule;
import org.libspark.gunyarapaint.framework.modules.FreeHandModule;
import org.libspark.gunyarapaint.framework.modules.ICanvasModule;
import org.libspark.nicopedia.Com;

private var m_recorder:Recorder;
private var m_context:CanvasModuleContext;
private var m_module:ICanvasModule;
private var m_commit:uint;

private var basex:uint = 0;
private var basey:uint = 0;
private var baseWidth:uint = 0;
private var baseHeight:uint = 0;

private var oekakiId:uint;
private var redirectUrl:String;

//private var _logger:GPLogger;

private const ALERT_TITLE:String = 'お絵カキコ';
private const MAX_CANVAS_WIDTH:uint = 500;
private const MAX_CANVAS_HEIGHT:uint = 500;
private const MIN_CANVAS_WIDTH:uint = 16;
private const MIN_CANVAS_HEIGHT:uint = 16;

// ポップアップの初期位置
private var initCanvasWindowPos:Point;
private var initPenDetailWindowPos:Point;
private var initGPLayerWindowPos:Point;
private var initCanvasWindowSize:Point;

public function setModule(value:String):void
{
    m_module = m_context.getModule(value);
}

public function get module():ICanvasModule
{
    return m_module;
}

public function get supportedBlendModes():Array
{
    return blendModes.toArray();
}

public function get layers():LayerBitmapCollection
{
    return m_recorder.layers;
}

public function get pen():Pen
{
    return m_recorder.pen;
}

public function get canvasWidth():uint
{
    return m_recorder.width;
}

public function get canvasHeight():uint
{
    return m_recorder.height;
}

public function get canvasView():Sprite
{
    return m_recorder.view;
}

// ふっかつのじゅもんからの復活

public function deserialize(s:String):void
{
    // TODO: 実装
    // var log:GPLogger = GPLogger.deserialize(s);
}

private function onPreinitialize(event:FlexEvent):void
{
    var width:int = 0;
    var height:int = 0;
    var undoBufferSize:int = 0;
    if (DEBUG) {
        /*
        parameters['oekakiId'] = 23724;
        parameters['baseImgUrl'] = 'http://dic.nicovideo.jp/oekaki_layers/23724';
        parameters['baseImgInfoUrl'] = 'http://dic.nicovideo.jp/oekaki_info/23724';
        */
        parameters['postUrl'] = 'http://dic.dev.nicovideo.jp/';
        parameters['cookie'] = 'cookie';
        parameters['magic'] = 'magic';
        parameters['redirectUrl'] = 'http://dic.dev.nicovideo.jp/';
        parameters['undoBufferSize'] = 16;
        parameters['canvasWidth'] = 417;
        parameters['canvasHeight'] = 317;
    }
    
    width = int(parameters['canvasWidth']);
    height = int(parameters['canvasHeight']);
    undoBufferSize = int(parameters['undoBufferSize']);
    
    m_recorder = Recorder.create(width, height, undoBufferSize);
    m_context = new CanvasModuleContext(m_recorder);
    m_module = m_context.getModule(FreeHandModule.FREE_HAND);
    m_commit = 0;
    
    m_recorder.addEventListener(CommandEvent.COMMITTED, onCommit);
    m_recorder.addEventListener(UndoEvent.UNDO, onChangeUndo);
    m_recorder.addEventListener(UndoEvent.REDO, onChangeUndo);
    m_recorder.addEventListener(UndoEvent.PUSH, onChangeUndo);
    m_context.add(new MovingCanvasModule(m_recorder, gpCanvasWindow));
}

private function onCommit(event:CommandEvent):void
{
    //trace(event.command);
    m_commit++;
}

private function onCreationComplete(event:FlexEvent):void
{
    var width:uint = 0;
    var height:uint = 0;
    var undoBufferSize:uint = 0;
    
    if (DEBUG) {
        // debug buttons
        //logPlayButton.addEventListener(FlexEvent.BUTTON_DOWN, playLogHandler);
        versionLabel.text += 'debug';
        logPlayButton.visible = true;
        checkPngButton.visible = true;
    }
    
    enabled = false;
    gpCanvasWindow.enabled = false;
    penDetailWindow.enabled = false;
    gpLayerWindow.enabled = false;
    
    // ポップアップさせて、そいつらの初期位置を覚える
    PopUpManager.addPopUp(gpCanvasWindow, this);
    PopUpManager.addPopUp(penDetailWindow, this);
    PopUpManager.addPopUp(gpLayerWindow, this);
    initCanvasWindowPos = new Point(gpCanvasWindow.x, gpCanvasWindow.y);
    initPenDetailWindowPos = new Point(penDetailWindow.x, penDetailWindow.y);
    initGPLayerWindowPos = new Point(gpLayerWindow.x, gpLayerWindow.y);
    initCanvasWindowSize = new Point(gpCanvasWindow.width, gpCanvasWindow.height);
    
    if (parameters['postUrl'] && parameters['cookie'] && parameters['magic'] && parameters['redirectUrl']) {
        postOekakiButton.enabled = true;
        redirectUrl = parameters['redirectUrl'];
    }
    if (parameters['undoBufferSize']) {
        undoBufferSize = int(parameters['undoBufferSize']);
        if (undoBufferSize < 0) {
            Alert.show('最大アンドゥ回数が少なすぎます。', ALERT_TITLE);      
        }
        if (undoBufferSize > 32) {
            Alert.show('最大アンドゥ回数が多すぎます。', ALERT_TITLE);      
        }
    }
    else {
        return;
    }
    if (parameters['oekakiId'] && parameters['baseImgUrl']) {
        oekakiId = uint(parameters['oekakiId']);
        new Com().loadURL(parameters['baseImgUrl'], getBaseImgHandler);
    }
    else {
        if (parameters['canvasWidth'] && parameters['canvasHeight']) {
            width = int(parameters['canvasWidth']);
            height = int(parameters['canvasHeight']);
            if (width < MIN_CANVAS_WIDTH || height < MIN_CANVAS_HEIGHT) {
                Alert.show('キャンバスサイズが小さすぎます。', ALERT_TITLE);
                return;
            }
            if (width > MAX_CANVAS_WIDTH || height > MAX_CANVAS_HEIGHT) {
                Alert.show('キャンバスサイズが大きすぎます。', ALERT_TITLE);
                return;
            }
        } else {
            return;
        }
        relocateComponents();
    }
}

private function onApplicationComplete(event:FlexEvent):void
{
    stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);  
    stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);  
    stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
    stage.addEventListener(MouseEvent.MOUSE_OUT, onMouseUp); // これを入れるとマズい。
}

private function onRemove(event:Event):void
{
    m_recorder.removeEventListener(CommandEvent.COMMITTED, onCommit);
    m_recorder.removeEventListener(UndoEvent.UNDO, onChangeUndo);
    m_recorder.removeEventListener(UndoEvent.REDO, onChangeUndo);
    m_recorder.removeEventListener(UndoEvent.PUSH, onChangeUndo);
    stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);  
    stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);  
    stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
    stage.removeEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
}

// canvasでの外のmouseUpをcanvasに通知  
private function onMouseUp(evt:MouseEvent):void
{
    module.interrupt(evt.localX, evt.localY);
}

private function onChangeUndo(event:UndoEvent):void
{
    var undoCount:int = event.undoCount;
    undoButton.label = 'アンドゥ ';
    if (undoCount > 0) {
        undoButton.label += '(' + undoCount + ')';
        undoButton.enabled = true;
    }
    else {
        undoButton.enabled = false;
    }
    var redoCount:int = event.redoCount;
    redoButton.label = 'リドゥ ';
    if (redoCount > 0) {
        redoButton.label += '(' + redoCount + ')';
        redoButton.enabled = true;
    }
    else {
        redoButton.enabled = false;
    }
}

private function get isShortCut():Boolean
{
    return stage.focus is mx.core.UITextField;
}

private function onKeyDown(evt:KeyboardEvent):void
{
    if (isShortCut)
        return;
    switch (evt.keyCode) {
        case Keyboard.CONTROL:
            penDetailWindow.pen = DropperModule.DROPPER;
            break;
        case Keyboard.SHIFT:
            break;
        case Keyboard.SPACE:
            penDetailWindow.pen = ""; // handtool
            break;
        case 48: // 0
        case 96: // ten-key 0
            if (evt.shiftKey) {
                setRotate(0);
            } else {
                setZoom(1);
            }
            break;
        case 65: // a
            // Aキーの状態 = 押下中
            m_module.keyA = true;
            break;
        case 73: // i
            windowsResetButtonHandler(null);
            break;
        case 77: // m
            m_module.horizontalMirror(0xff);
            break;
        case 81: // q
            // Qキーの状態 = 押下中
            m_module.keyQ = true;
            break;
        case 82: // r
            // Rキーの状態 = 押下中
            m_module.shouldStartAfterDrawing = true;
            break;
        // 20090905-haku2 ins start
        case 84: // t
            // Tキーの状態 = 押下中
            m_module.shouldStartBeforeDrawing = true;
            break;
        // 20090905-haku2 ins end
        case 89: // y
            m_module.redo();
            break;
        case 90: // z
            m_module.undo();
            break;
        case 107: // ten key +
            // +
            setZoom(canvasZoom.value + 1);
            break;
        case 109: // ten key -
            // -
            setZoom(canvasZoom.value - 1);
            break;
        case 187:
            if (evt.shiftKey)
                // +
                setZoom(canvasZoom.value + 1);
            break;
        case 189:
            // -
            setZoom(canvasZoom.value - 1);
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
            if (!evt.shiftKey)// 念のため SHIFTキー対応 (テンキーのほうは放置)
                penDetailWindow.currentThickness = evt.keyCode - 48;
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
            penDetailWindow.currentThickness = evt.keyCode - 96;
            break;
        case 45: // INS
            if (!evt.shiftKey)
                setRotate(0);
            break;
        default:
            // Alert('' + evt.keyCode);
            break;
    }
}

private function onKeyUp(evt:KeyboardEvent):void
{
    if (isShortCut)
        return;
    switch (evt.keyCode) {
        case Keyboard.CONTROL:
            penDetailWindow.reset();
            break;
        case Keyboard.SPACE:
            penDetailWindow.reset();
            break;
        case 65: // a
            // Aキーの状態 = 解放
            m_module.keyA = false;
            break;
        case 81: // q
            // Qキーの状態 = 解放
            m_module.keyQ = false;
            break;
        case 82: // r
            // Rキーの状態 = 解放
            m_module.shouldStartAfterDrawing = false;
            break;
        // 20090905-haku2 ins start
        case 84: // t
            // Tキーの状態 = 解放
            m_module.shouldStartBeforeDrawing = false;
            break;
        // 20090905-haku2 ins end
        return;
    }
}

private function windowsResetButtonHandler(evt:FlexEvent):void
{
    gpCanvasWindow.rotate(0);
    
    gpCanvasWindow.transform.matrix = new Matrix(1, 0, 0, 1, initCanvasWindowPos.x, initCanvasWindowPos.y);
    penDetailWindow.move(initPenDetailWindowPos.x, initPenDetailWindowPos.y);
    gpLayerWindow.move(initGPLayerWindowPos.x, initGPLayerWindowPos.y);
    gpCanvasWindow.width = initCanvasWindowSize.x;
    gpCanvasWindow.height = initCanvasWindowSize.y;
    
    setRotate(0);
    setZoom(1);
}

private function passwordButtonHandler(evt:FlexEvent):void
{
    var w:GPPasswordWindowControl = new GPPasswordWindowControl();
    PopUpManager.addPopUp(w, this, true);
    // w.password = gpCanvas.logger.password;
}

private function set allEnabled(value:Boolean):void
{
    enabled = value;
    gpCanvasWindow.enabled = value;
    penDetailWindow.enabled = value;
    gpLayerWindow.enabled = value;
}

private function relocateComponents():void
{
    toolCanvas.x = (width - toolCanvas.width) / 2;
    allEnabled = true;
}

// TODO: もう本当に汚い…　これのスコープを短くする。
private var baseImg:BitmapData;

private function getBaseImgHandler(com:Com):void
{
    baseImg = Bitmap(com.content).bitmapData;
    if (parameters['baseImgInfoUrl']) {
        new Com().sendGetUrlRequest(parameters['baseImgInfoUrl'], getBaseImgInfoHandler);
    } else {
        // 画像のサイズがそのままwidth/height
        // このロジックは通らなくなっているはずだが、移行措置のため残してある。
        // 消してもよい。
        baseImgToCanvas(baseImg.width, baseImg.height, parameters['undoBufferSize'], null);
    }
}

private function getBaseImgInfoHandler(com:Com):void
{
    var info:Object = com.jsonObject;
    if (!info) {
        info = {'width': baseImg.width, 'height': baseImg.height};
    }
    baseImgToCanvas(info['width'], info['height'], parameters['undoBufferSize'], info);
}

private function baseImgToCanvas(width:uint, height:uint, undoBufferSize:uint, baseInfo:Object):void
{
    /*
    _logger = GPLogger.createForDraw(width, height, undoBufferSize,
        baseImg, baseInfo);
    gpCanvasWindow.logger = _logger;
    */
    relocateComponents();
    enabled = true;  
}

private function canvasZoomHandler(evt:SliderEvent):void
{
    // 20090905-haku2 ins start
    // 拡大率をテキストボックスに反映
    if (evt.value >= 1) {
        canvasZoomValue.text = String(Math.round(evt.value * 10000)/100);
    }
    else {
        canvasZoomValue.text = String(Math.round((1.0 / (-evt.value + 2)) * 10000)/100);
    }
    // 20090905-haku2 ins end
    gpCanvasWindow.zoom(evt.value);
}
// 20090909-haku2 upd start

// 数値入力で拡大率指定
private function canvasZoomValueHandler(evt:Event):void
{
    var rm:Number = Number(canvasZoomValue.text);
    if (rm <= 0) {
        rm = 1;
    }
    else if (rm >= 100) {
        rm /= 100;
    }
    else {
        rm = -(100 / rm) + 2;
    }
    canvasZoom.value = rm;
    gpCanvasWindow.zoom(canvasZoom.value);
}
// 20090909-haku2 upd end

private function canvasRotateHandler(evt:SliderEvent):void
{
    canvasRotateValue.text = String(-evt.value); // 20090905-haku2 ins キャンバス回転角度をテキストボックスに反映
    gpCanvasWindow.rotate(evt.value);
}

// 20090909-haku2 upd start
// 数値入力でキャンバス回転角度指定
private function canvasRotateValueHandler(evt:Event):void
{
    canvasRotate.value = Number(canvasRotateValue.text);
    gpCanvasWindow.rotate(canvasRotate.value);
}
// 20090909-haku2 upd end

private function additionalNumberStepperHandler(evt:NumericStepperEvent):void
{
    gpCanvasWindow.auxDivideCount = uint(evt.value);
}

private function additionalBoxCheckBoxHandler(evt:Event):void
{
    gpCanvasWindow.auxBoxVisible = evt.target.selected;
}

private function additionalSkewCheckBoxHandler(evt:Event):void
{
    gpCanvasWindow.auxSkewVisible = evt.target.selected;
}

// 20090906-haku2 ins start
// 補助線種類の変更
private function additionalTypeComboBoxHandler(evt:ListEvent):void
{
    var n:Number = additionalNumberStepper.value;
    if (evt.currentTarget.value == 0) {
        additionalNumberStepper.minimum = 2;
        additionalNumberStepper.maximum = 16;
        gpCanvasWindow.enableAuxPixel = false;
    }
    else {
        additionalNumberStepper.minimum = 4;
        additionalNumberStepper.maximum = 80;
        gpCanvasWindow.enableAuxPixel = true;
    }
}

// 20090906-haku2 ins end

private function commCompleteHandler(com:Com):void
{
    try {
        if (com.errStr) {
            // error
            Alert.show(com.errStr, ALERT_TITLE);
        } else if (com.data.toString() != '') {
            Alert.show(com.data.toString(), ALERT_TITLE);
        } else {
            // redirect
            Com.redirect(redirectUrl);
            return;
        }
    } catch (e:Error) {
        Alert.show('何かしらのエラーが起きました…再投稿お願いいたします。', ALERT_TITLE);
    }
    allEnabled = true;
    alertOnUnload(true);
}

private function postOekakiButtonHandler(evt:Event):void
{
    if (titleTextInput.text == '') {
        Alert.show('絵のタイトルが空です。', ALERT_TITLE);
    }
    else if (messageTextArea.text == '') {
        Alert.show('書き込みが空です。', ALERT_TITLE);
    }
    else if (m_commit == 0) {
        Alert.show('絵が描かれていません。お絵かきしてください。', ALERT_TITLE);
    }
    else {
        try {
            allEnabled = false;
            alertOnUnload(false);
            var com:Com = new Com();
            com.postOekaki(this,
                parameters['postUrl'],
                parameters['magic'],
                parameters['cookie'],
                fromTextInput.text,
                titleTextInput.text,
                messageTextArea.text,
                watchlistCheckBox.selected,
                oekakiId,
                new ByteArray(), //_logger.dataForPost,
                commCompleteHandler
            );
        } catch (e:Error) {
            allEnabled = true;
            alertOnUnload(true);
            Alert.show(e.message, ALERT_TITLE);
        }
    }
}

private function rotateResetButtonHandler(evt:Event):void
{
    setRotate(0);
    canvasRotateValue.text = "0"; // 20090905-haku2 ins 数値入力をリセット
}

private function zoomResetButtonHandler(evt:Event):void
{
    setZoom(1);
    canvasZoomValue.text = "100"; // 20090905-haku2 ins 数値入力をリセット
}

private function setRotate(v:Number):void
{
    canvasRotate.value = v;
    canvasRotateValue.text = String(-canvasRotate.value); // 20090909-haku2 ins キャンバス回転角度をテキストボックスに反映
    gpCanvasWindow.rotate(canvasRotate.value);
}

private function setZoom(v:Number):void
{
    canvasZoom.value = v;
    gpCanvasWindow.zoom(canvasZoom.value);  
    // 20090909-haku2 ins start
    // 拡大率をテキストボックスに反映
    if (canvasZoom.value >= 1) {
        canvasZoomValue.text = String(Math.round(canvasZoom.value * 10000)/100);
    } else {
        canvasZoomValue.text = String(Math.round((1.0 / (-canvasZoom.value + 2)) * 10000)/100);
    }
    // 20090909-haku2 ins end
}

private function alertOnUnload(b:Boolean):void
{
    if (ExternalInterface.available) {
        try {
            ExternalInterface.call("changeAlertOnUnload", b);
        } catch (e:SecurityError) {
        } catch (e:Error) {
        }
    }
}
