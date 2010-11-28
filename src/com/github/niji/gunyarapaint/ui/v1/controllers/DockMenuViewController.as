package com.github.niji.gunyarapaint.ui.v1.controllers
{
    import com.github.niji.gunyarapaint.ui.v1.CanvasController;
    import com.github.niji.gunyarapaint.ui.v1.FileDialog;
    import com.github.niji.gunyarapaint.ui.v1.views.CopyrightView;
    import com.github.niji.gunyarapaint.ui.v1.views.DataLoadView;
    import com.github.niji.gunyarapaint.ui.v1.views.DataSaveView;
    
    import flash.display.DisplayObject;
    import flash.errors.IllegalOperationError;
    import flash.net.URLRequest;
    import flash.net.navigateToURL;
    
    import mx.controls.Alert;
    import mx.core.Application;
    import mx.core.IFlexDisplayObject;
    import mx.core.IMXMLObject;
    import mx.events.CloseEvent;
    import mx.managers.PopUpManager;
    
    public class DockMenuViewController implements IMXMLObject
    {
        public function initialized(document:Object, id:String):void
        {
            m_parent = DisplayObject(document);
        }
        
        public function handleOnClick(item:XML):void
        {
            var selected:String = item.@data;
            var controller:RootViewController = RootViewController(Application.application.controller);
            switch (selected) {
                case "application.about":
                    m_copyright = m_copyright || new CopyrightView();
                    PopUpManager.addPopUp(m_copyright, m_parent, true);
                    break;
                case "data.load":
                    m_loadView = m_loadView || new DataLoadView();
                    PopUpManager.addPopUp(m_loadView, m_parent, true);
                    break;
                case "data.save":
                    m_saveView = m_saveView || new DataSaveView();
                    m_saveView.controller.confirm(confirmCallback);
                    break;
                case "window.resetAll":
                    controller.resetWindowsPosition();
                    break;
                case "help.article":
                    navigateToURL(new URLRequest("http://dic.nicovideo.jp/id/377406"));
                    break;
                case "help.bbs":
                    navigateToURL(new URLRequest("http://nicodic.razil.jp/bugyobo/"));
                    break;
                case "development.saveLog":
                    var marshal:Marshal = controller.newMarshal({});
                    var dialog:FileDialog = new FileDialog(item.@label);
                    dialog.openToSave(marshal.newRecorderBytes());
                    break;
                default:
                    throw new IllegalOperationError("Invalid menu item selected");
            }
        }
        
        private function confirmCallback(event:CloseEvent):void
        {
            if (event.detail == Alert.YES) {
                if (m_saveView.controller.trySave())
                    PopUpManager.addPopUp(m_saveView, m_parent, true)
            }
        }
        
        private var m_parent:DisplayObject;
        private var m_copyright:CopyrightView;
        private var m_loadView:DataLoadView;
        private var m_saveView:DataSaveView;
    }
}
