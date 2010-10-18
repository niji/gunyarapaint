rem ** CONFIG **
set FLEX3_SDK_PATH=c:\mydoc\flex_sdk_3.5.0

rem ** BUILD **
%FLEX3_SDK_PATH%\bin\mxmlc -load-config+=obj\compatConfig.xml -incremental=true -optimize=true -static-link-runtime-shared-libraries=true -locale ja_JP -o .\bin\gunyarapaint.swf
%FLEX3_SDK_PATH%\bin\mxmlc -load-config+=obj\compat_log_playerConfig.xml -incremental=true -optimize=true -static-link-runtime-shared-libraries=true -locale ja_JP -o .\bin\gplogplayer.swf
