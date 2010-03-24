package org.libspark.nicopedia
{
  import com.adobe.serialization.json.JSON;
  import com.adobe.serialization.json.JSONParseError;
  
  import flash.display.DisplayObject;
  
  import mx.core.UIComponent;
  import mx.events.FlexEvent;
  
  public class Com extends UIComponent
  {
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.events.SecurityErrorEvent;
    import flash.utils.ByteArray;
    import flash.events.HTTPStatusEvent;
    import flash.events.IEventDispatcher;
    import flash.display.Loader;
    import flash.net.*;
    
    import mx.controls.Alert;
    
    import mx.managers.PopUpManager;
    
    private const ALERT_TITLE:String = 'ニコニコ大百科伝言班';
    
    private var callback:Function;
  
    private var urlLoader:URLLoader;
    private var loader:Loader;
    
    private var errorStr:String;
    
    private var _comDialog:ComDialog;

    public function Com() {
    }

    // jasrac_idsはスペース区切りで
    public function postPico(url:String, magic:String, cookie:String,
                             name:String, title:String, msg:String, addWatchlist:Boolean,
                             mml:String, ref_mml_id:uint, jasrac_ids:String, callback:Function):void {
      var r:URLRequest = new URLRequest();
      var v:URLVariables = new URLVariables();
      r.url = url;
      r.method = URLRequestMethod.POST;
      r.data = v;
      v.magic = magic;
      v.FROM = name;
      v.title = title;
      v.MESSAGE = msg;
      v.watchlist = addWatchlist ? 't' : '';
      v.MML = mml;
      v.ref_mml_id = ref_mml_id;
      v.jasrac_ids = jasrac_ids;
      v.cookie = cookie;
      
      this.callback = callback;      
      post(r);
    }
    
    public static function redirect(url:String):void {
      var r:URLRequest = new URLRequest();
      r.url = url;
      r.method = URLRequestMethod.GET;
      navigateToURL(r, '_top');
    }
    
    public function postOekaki(parent:DisplayObject, url:String, magic:String, cookie:String, 
                               name:String, title:String, msg:String, addWatchlist:Boolean,
                               ref_oekaki_id:uint, data:Object, callback:Function):void {
      try {
        _comDialog = new ComDialog();
        PopUpManager.addPopUp(_comDialog, parent, true);
        _comDialog.cancelButton.addEventListener(FlexEvent.BUTTON_DOWN, cancelHandler);
  
        var r:URLRequest = new URLRequest();
        var v:URLVariables = new URLVariables();
        var b:ByteArray = new ByteArray();
        var info:ByteArray = new ByteArray();
        info.writeUTFBytes(JSON.encode(data['info']));
        v.cookie = cookie;
        v.magic = magic;
        v.FROM = name;
        v.title = title;
        v.MESSAGE = msg;
        v.watchlist = addWatchlist ? 't' : '';
        v.ref_oekaki_id = ref_oekaki_id;
        v.log_count = data['info']['log_count']; // TODO: サーバ側で取り出してあげる
        var form:String = v.toString();
        b.writeUTFBytes(':' + form.length + '=' + form);
        b.writeUTFBytes('&IMAGE:' + data['image'].length + '=');
        b.writeBytes(data['image']);
        b.writeUTFBytes('&IMAGE_LOG:' + data['compressed_log'].length + '=');
        b.writeBytes(data['compressed_log']);
        b.writeUTFBytes('&IMAGE_LAYERS:' + data['layers_image'].length + '=');
        b.writeBytes(data['layers_image']);
        b.writeUTFBytes('&IMAGE_INFO:' + info.length + '=');
        b.writeBytes(info);
        r.url = url;
        r.method = URLRequestMethod.POST;
        r.contentType = 'application/x-nicopedia-oekaki';
        r.data = b;
        
        this.callback = callback;
        post(r);
      } catch (e:Error) {
        errorStr = '投稿準備時にエラーが起こりました。ほかのアプリケーションを終了して空きメモリ容量を増やした上で、再度投稿してください。';
        callback(this);
      }
    }
    
    public static function navigate(url:String, target:String):void {
      var r:URLRequest = new URLRequest();
      r.url = url;
      r.method = URLRequestMethod.POST;
      navigateToURL(r, target);
    }
    
    public function sendGetUrlRequest(url:String, callback:Function):void {
      var r:URLRequest = new URLRequest();
      r.url = url;
      r.method = URLRequestMethod.GET;
      this.callback = callback;
      post(r);
    }
    
    private function post(request:URLRequest):void {
      errorStr = null;
      urlLoader = new URLLoader();
      urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
      configureListeners(urlLoader);
      urlLoader.load(request);
    }

    // 画像の読み込み専用！
    public function loadURL(url:String, callback:Function):void {
      var r:URLRequest = new URLRequest;
      r.url = url;
      r.method = URLRequestMethod.GET;
      loader = new Loader();
      configureListeners(loader.contentLoaderInfo);
      this.callback = callback;
      loader.load(r);
    }
    
    private function configureListeners(dispatcher:IEventDispatcher):void {
      // dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, postHttpStatusHandler);
      dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, postSecurityErrorHandler);
      dispatcher.addEventListener(IOErrorEvent.IO_ERROR, postIOErrorHandler);
      dispatcher.addEventListener(Event.OPEN, postOpenHandler);
      dispatcher.addEventListener(ProgressEvent.PROGRESS, postProgressHandler);
      dispatcher.addEventListener(Event.COMPLETE, postCompleteHandler);            
    }
    
    private function postSecurityErrorHandler(evt:SecurityErrorEvent):void {
      errorStr = 'セキュリティエラーが発生しました。通信が許可されていません。通常このエラーは起きません。\n詳細:' + evt.text;
      postCompleteHandler(evt);
    }
    private function postIOErrorHandler(evt:IOErrorEvent):void {
      // TODO: not event based, see URLLoader help
      errorStr = 'ネットワークエラーが発生しました。混雑や一時的なメンテナンスの可能性がございます。お手数ですが、再度投稿お願いいたします。\n詳細:' + evt.text;
      postCompleteHandler(evt);
    }
    private function postOpenHandler(evt:Event):void {
    }
    private function postProgressHandler(evt:ProgressEvent):void {
      if (_comDialog) {
        _comDialog.comProgressBar.setProgress(evt.bytesLoaded, evt.bytesTotal);
      }
    }
    
    private function cancelHandler(evt:Event):void {
      try {
        urlLoader.close();
      } catch (e:Error) {}
      errorStr = '投稿をキャンセルしました。すでに投稿がなされている場合もあります。';
      postCompleteHandler(evt);
    }
    private function postCompleteHandler(evt:Event):void {
      if (_comDialog) {
        PopUpManager.removePopUp(_comDialog);
        _comDialog = null;
      }
      callback(this);
    }
    public function get data():ByteArray {
      return urlLoader.data;
    }
    public function get content():DisplayObject {
      // for png to bitmap
      return loader.content;
    }
    public function get jsonObject():Object {
      if (urlLoader.data.toString != '') {
        try {
          return JSON.decode(urlLoader.data);          
        } catch (e:JSONParseError) {
        }
      }
      return null;
    }
    public function get errStr():String {
      return errorStr;
    }
  }
}