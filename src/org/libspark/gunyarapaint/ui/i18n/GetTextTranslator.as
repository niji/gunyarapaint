package org.libspark.gunyarapaint.ui.i18n
{
    import com.rails2u.gettext.GetText;
    
    import org.libspark.gunyarapaint.framework.i18n.ITranslator;
    
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
            var translated:String = GetText._(str, rest);
            return translated;
        }
    }
}
