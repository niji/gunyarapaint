package com.github.niji.gunyarapaint.ui.i18n
{
    import com.github.niji.framework.i18n.ITranslator;
    import com.rails2u.gettext.GetText;
    
    /**
     * as3gettext を使った翻訳クラス
     */
    public final class GetTextTranslator implements ITranslator
    {
        /**
         * @copy org.libspark.gunyarapaint.framework.i18n.ITranslator#translate()
         */
        public function translate(str:String, ...rest):String
        {
            var args:Array = rest ? rest[0] : [];
            var translated:String = GetText._(str, args);
            return translated;
        }
    }
}
