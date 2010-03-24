package org.libspark.gunyarapaint.ui.events
{
    import flash.events.Event;
    
    public final class CanvasModuleEvent extends Event
    {
        internal static const PREFIX:String = "org.libspark.gunyarapaint.ui.events.";
        
        public static const AFTER_CHANGE:String = PREFIX + "afterChange";
        
        public static const BEFORE_CHANGE:String = PREFIX + "beforeChange";
        
        public function CanvasModuleEvent(type:String)
        {
            super(type, false, false);
        }
    }
}