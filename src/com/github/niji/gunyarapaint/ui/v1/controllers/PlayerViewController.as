package com.github.niji.gunyarapaint.ui.v1.controllers
{
    import com.adobe.serialization.json.JSON;
    import com.github.niji.framework.Player;
    import com.github.niji.framework.events.CommandEvent;
    import com.github.niji.framework.events.PlayerErrorEvent;
    import com.github.niji.framework.events.PlayerEvent;
    import com.github.niji.framework.i18n.TranslatorRegistry;
    import com.github.niji.gunyarapaint.ui.i18n.GetTextTranslator;
    import com.github.niji.gunyarapaint.ui.v1.net.Request;
    import com.rails2u.gettext.GetText;
    
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Graphics;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.display.Shape;
    import flash.events.AsyncErrorEvent;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.IEventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.external.ExternalInterface;
    import flash.net.URLLoader;
    import flash.utils.ByteArray;
    
    import mx.controls.Alert;
    import mx.core.IMXMLObject;
    import mx.core.UIComponent;
    import mx.managers.PopUpManager;
    
    public class PlayerViewController implements IMXMLObject
    {
        public function initialized(document:Object, id:String):void
        {
            m_root = gplogplayer(document);
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
            GetText.locale = m_root.parameters["language"] || "ja_jp";
            GetText.initLangFile(new XML(new m_root.languages()));
            TranslatorRegistry.install(new GetTextTranslator());
        }
        
        public function handleCreationComplete():void
        {
            var url:String = m_root.parameters["oelogUrl"];
            m_finished = true;
            m_continue = false;
            if (url) {
                m_request = new Request();
                showLoadingDialog(m_request, _("Loading the log..."));
                setHandler(m_request, onResponseLog);
                m_request.get(url);
                m_root.currentState = "loading";
            }
            else {
                // should not be here
                Alert.show("The value of oelogUrl is empty");
            }
        }
        
        public function handleChangePlayerSpeed(value:Number):void
        {
            m_player.speed = value;
        }
        
        public function handlePlay():void
        {
            play();
        }
        
        public function handleStop():void
        {
            m_player.stop();
            m_root.currentState = "stopping";
        }
        
        private function onResponseLog(event:Event):void
        {
            var urlLoader:URLLoader = URLLoader(event.target);
            removeHandler(urlLoader, onResponseLog);
            hideLoadingDialog();
            m_log = urlLoader.data;
            m_log.uncompress();
            var url:String = m_root.parameters["baseImgUrl"];
            if (url) {
                var loader:Loader = new Loader();
                m_request.loader = loader.contentLoaderInfo;
                showLoadingDialog(m_request, _("Loading the image layers..."));
                setHandler(m_request, onResponseLayerImage);
                m_request.load(url);
            }
            else {
                // It's now continued
                play();
            }
        }
        
        private function onResponseLayerImage(event:Event):void
        {
            var loader:LoaderInfo = LoaderInfo(event.target);
            removeHandler(loader, onResponseLayerImage);
            hideLoadingDialog();
            m_layerImage = Bitmap(loader.content).bitmapData;
            var url:String = m_root.parameters["baseImgInfoUrl"];
            if (url) {
                m_request.loader = new URLLoader();
                showLoadingDialog(m_request, _("Loading the image metadata..."));
                setHandler(m_request, onResponseMetadata);
                m_request.get(url);
            }
            else {
                // It seems older version
                play();
            }
        }
        
        private function onResponseMetadata(event:Event):void
        {
            var loader:URLLoader = URLLoader(event.target);
            removeHandler(loader, onResponseMetadata);
            hideLoadingDialog();
            m_metadata = JSON.decode(String(loader.data));
            m_continue = true;
            play();
        }
        
        private function onPlayStarted(event:PlayerEvent):void
        {
            trace(m_player.version);
        }
        
        private function onPlayFinished(event:PlayerEvent):void
        {
            setFinished();
        }
        
        private function onPlayError(event:PlayerErrorEvent):void
        {
            setFinished();
            Alert.show(event.cause.message);
        }
        
        private function onError(event:ErrorEvent):void
        {
            hideLoadingDialog();
            removeHandler(m_request, onResponseLog);
            removeHandler(m_request, onResponseLayerImage);
            removeHandler(m_request, onResponseMetadata);
            Alert.show(event.text, event.type);
        }
        
        private function onParse(event:CommandEvent):void
        {
            trace(event.command);
        }
        
        private function setHandler(target:IEventDispatcher, handler:Function):void
        {
            target.addEventListener(Event.COMPLETE, handler);
            target.addEventListener(IOErrorEvent.IO_ERROR, onError);
            target.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onError);
            target.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
        }
        
        private function removeHandler(target:IEventDispatcher, handler:Function):void
        {
            target.removeEventListener(Event.COMPLETE, handler);
            target.removeEventListener(IOErrorEvent.IO_ERROR, onError);
            target.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, onError);
            target.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
        }
        
        private function play():void
        {
            if (m_finished) {
                createPlayer();
                measureWindow();
                callExternal();
                m_finished = false;
            }
            m_root.currentState = "playing";
            m_player.speed = m_root.playSpeedHSlider.value;
            m_player.addEventListener(PlayerEvent.FINISHED, onPlayFinished);
            m_player.addEventListener(PlayerErrorEvent.ERROR, onPlayError);
            if (m_development) {
                m_player.addEventListener(PlayerEvent.STARTED, onPlayStarted);
                m_player.addEventListener(CommandEvent.PARSE, onParse);
            }
            m_player.start();
        }
        
        private function createPlayer():void
        {
            if (m_layerImage && !m_metadata) {
                // It's seems older version
                m_metadata = {
                    "width": m_layerImage.width,
                        "height": m_layerImage.height,
                        "undoBufferSize": 16
                };
                m_continue = true;
            }
            if (m_player != null) {
                // prevent memory leaks caused Event.
                m_player.removeEventListener(CommandEvent.PARSE, onParse);
                m_player.removeEventListener(PlayerEvent.STARTED, onPlayStarted);
                m_player.removeEventListener(PlayerEvent.FINISHED, onPlayFinished);
                m_player.removeEventListener(PlayerErrorEvent.ERROR, onPlayError);
            }
            m_log.position = 0;
            m_player = Player.create(m_log);
            if (m_continue)
                m_player.layers.load(m_layerImage, m_metadata);
            m_root.canvas.removeAllChildren();
            var temp:UIComponent = new UIComponent();
            var mask:Shape = new Shape();
            var g:Graphics = mask.graphics;
            g.beginFill(0x0);
            g.drawRect(0, 0, m_player.width, m_player.height);
            g.endFill();
            temp.mask = mask;
            temp.addChild(mask);
            temp.addChild(m_player.layers.view);
            m_root.canvas.addChild(temp);
        }
        
        private function measureWindow():void
        {
            var w:uint = m_player.width;
            var h:uint = m_player.height;
            m_root.canvas.width = w + 2;
            m_root.canvas.height = h + 2;
            m_root.width = w + 20;
            m_root.width = w < 420 ? 420 : m_root.width;
            m_root.height = h + m_root.canvas.y + 20;
            // for express install
            m_root.height = m_root.height < 137 ? 137 : m_root.height;
        }
        
        private function setFinished():void
        {
            m_root.currentState = "stopping";
            m_finished = true;
        }
        
        private function callExternal():void
        {
            if (ExternalInterface.available) {
                try {
                    ExternalInterface.call("changeGPLogPlayerRect", m_root.width, m_root.height);
                }
                catch (e:Error) {
                    Alert.show(e.message);
                }
            }
        }
        
        private function hideLoadingDialog():void
        {
            m_root.loadingDialog.visible = false;
            PopUpManager.removePopUp(m_root.loadingDialog);
        }
        
        private function showLoadingDialog(request:Request, title:String):void
        {
            m_root.loadingDialog.centerize(m_root);
            m_root.loadingDialog.setProgressSource(request.loader);
            m_root.loadingDialog.visible = true;
            m_root.loadingDialog.title = title;
            PopUpManager.addPopUp(m_root.loadingDialog, m_root);
        }
        
        private var m_root:gplogplayer;
        private var m_log:ByteArray;
        private var m_layerImage:BitmapData;
        private var m_metadata:Object;
        private var m_player:Player;
        private var m_request:Request;
        private var m_continue:Boolean;
        private var m_finished:Boolean;
        private var m_development:Boolean;
    }
}
