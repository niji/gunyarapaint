package com.github.niji.gunyarapaint.ui.v1.controllers
{
    import com.github.niji.gunyarapaint.ui.v1.views.DataLoadView;
    import com.github.niji.gunyarapaint.ui.v1.views.DataSaveView;
    
    import flash.display.DisplayObject;
    import flash.errors.IllegalOperationError;
    import flash.net.URLRequest;
    import flash.net.navigateToURL;
    
    import mx.core.Application;
    import mx.core.IMXMLObject;
    import mx.managers.PopUpManager;
    import com.github.niji.gunyarapaint.ui.v1.CanvasController;
    import com.github.niji.gunyarapaint.ui.v1.views.CopyrightView;
    import com.github.niji.gunyarapaint.ui.v1.FileDialog;

    public class DockMenuViewController implements IMXMLObject
    {
        public function initialized(document:Object, id:String):void
        {
        }
        
        public function handleOnClick(item:XML):void
        {
            var selected:String = item.@data;
            var app:Object = Application.application;
            var cc:CanvasController = app.canvasController;
            switch (selected) {
                case "application.about":
                    var cview:CopyrightView = new CopyrightView();
                    PopUpManager.addPopUp(cview, DisplayObject(app), true);
                    break;
                case "data.load":
                    var lview:DataLoadView = new DataLoadView();
                    PopUpManager.addPopUp(lview, DisplayObject(app), true);
                    break;
                case "data.save":
                    var sview:DataSaveView = new DataSaveView();
                    if (sview.controller.trySave())
                        PopUpManager.addPopUp(sview, DisplayObject(app), true);
                    break;
                case "window.resetAll":
                    Application.application.resetWindowsPosition();
                    break;
                case "help.article":
                    navigateToURL(new URLRequest("http://dic.nicovideo.jp/id/377406"));
                    break;
                case "help.bbs":
                    navigateToURL(new URLRequest("http://nicodic.razil.jp/bugyobo/"));
                    break;
                case "development.saveLog":
                    var marshal:Marshal = app.controller.newMarshal({});
                    var dialog:FileDialog = new FileDialog(item.@label);
                    dialog.openToSave(marshal.newRecorderBytes());
                    break;
                default:
                    throw new IllegalOperationError("Invalid menu item selected");
            }
        }
    }
}
