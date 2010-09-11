package com.github.niji.gunyarapaint.ui.events
{
    import flash.events.Event;
    
    /**
     * モジュールの変更が行われるときに呼び出されるイベントクラス
     */
    public final class CanvasModuleEvent extends Event
    {
        internal static const PREFIX:String = "org.libspark.gunyarapaint.ui.events.";
        
        public static const AFTER_CHANGE:String = PREFIX + "afterChange";
        
        public static const BEFORE_CHANGE:String = PREFIX + "beforeChange";
        
        public function CanvasModuleEvent(type:String)
        {
            super(type, false, false);
        }
        
        public override function clone():Event
        {
            return new CanvasModuleEvent(type);
        }
    }
}
