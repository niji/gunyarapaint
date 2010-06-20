package org.libspark.gunyarapaint.ui.v1
{
    import flash.utils.ByteArray;
    
    import org.libspark.gunyarapaint.framework.ui.IApplication;

    /**
     * コントローラの処理と情報の復元及び保存に必要なインターフェースです
     */
    public interface IController
    {
        /**
         * コントローラのウィンドウの初期化を実行します
         * 
         * @param IApplication
         */
        function init(app:IApplication):void;
        
        /**
         * コントローラ情報の復元をします
         * 
         * @param data 読み込み元のオブジェクト
         */
        function load(data:Object):void;
        
        /**
         * コントローラ情報の保存をします
         * 
         * @param data 保存先の空のオブジェクト
         */
        function save(data:Object):void;
        
        /**
         * コントローラのウィンドウを初期状態に戻します
         */
        function resetWindow():void;
        
        /**
         * コントローラ名を取得します
         */
        function get name():String;
    }
}
