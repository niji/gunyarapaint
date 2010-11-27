package com.github.niji.gunyarapaint.ui.v1.controllers
{
    import com.github.niji.framework.ui.IApplication;
    import com.github.niji.framework.ui.IController;
    import com.github.niji.gunyarapaint.ui.v1.net.Parameters;
    import com.github.niji.gunyarapaint.ui.v1.views.RequestWindowView;
    
    import flash.display.DisplayObject;
    import flash.geom.Point;
    
    import mx.core.IMXMLObject;
    import mx.managers.PopUpManager;
    import com.github.niji.gunyarapaint.ui.v1.views.FormView;
    
    public class FormViewController implements IMXMLObject, IController
    {
        public function initialized(document:Object, id:String):void
        {
            m_parent = FormView(document);
        }
        
        public function init(app:IApplication):void
        {
            m_app = RootViewController(app);
            m_initPosition = new Point(m_parent.x, m_parent.y);
        }
        
        public function load(data:Object):void
        {
            var point:Object = data.point;
            m_parent.move(point.x, point.y);
            m_parent.fromTextInput.text = data.from;
            m_parent.titleTextInput.text = data.title;
            m_parent.messageTextArea.text = data.message;
        }
        
        public function save(data:Object):void
        {
            data.point = new Point(m_parent.x, m_parent.y);
            data.from = m_parent.fromTextInput.text;
            data.title = m_parent.titleTextInput.text;
            data.message = m_parent.messageTextArea.text;
        }
        
        public function resetWindow():void
        {
            m_parent.move(m_initPosition.x, m_initPosition.y);
        }
        
        public function handlePost():void
        {
            try {
                var window:RequestWindowView = new RequestWindowView();
                var parameters:Parameters = new Parameters();
                parameters.name = m_parent.fromTextInput.text;
                parameters.message = m_parent.messageTextArea.text;
                parameters.title = m_parent.titleTextInput.text;
                parameters.shouldAddWatchList = m_parent.watchlistCheckBox.selected;
                m_app.fillParameters(parameters);
                PopUpManager.addPopUp(window, m_parent);
                window.controller.post(parameters, m_app);
            }
            catch (e:Error) {
                m_app.showAlert(e.message, m_parent.title);
            }
        }
        
        public function get name():String
        {
            return "formViewController";
        }
        
        public function get parentDisplayObject():DisplayObject
        {
            return m_parent;
        }
        
        private var m_parent:FormView;
        private var m_app:RootViewController;
        private var m_initPosition:Point;
    }
}
