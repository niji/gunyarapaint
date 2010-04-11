package {
    import com.rails2u.gettext.GetText;

    public function _(str:String, ... args):* {
        return GetText._(str, args);
    }
}
