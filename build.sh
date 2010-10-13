#!/bin/sh
# ** CONFIG **
FLEX3_SDK_PATH=~/flex_sdk_3.5

# ** BUILD **
cat << CONFIG > build-config.xml
<?xml version="1.0" encoding="utf-8"?>
<flex-config>
  <target-player>10.0.0</target-player>
  <compiler>
    <source-path append="true">
      <path-element>./src</path-element>
    </source-path>
    <library-path append="true">
      <path-element>./libs/colorpicker.swc</path-element>
      <path-element>./libs/framework.swc</path-element>
    </library-path>
  </compiler>
  <file-specs>
    <path-element>./src/gunyarapaint.mxml</path-element>
  </file-specs>
  <default-background-color>#FFFFFF</default-background-color>
  <default-frame-rate>30</default-frame-rate>
  <default-size>
    <width>1024</width>
    <height>768</height>
  </default-size>
</flex-config>
CONFIG

$FLEX3_SDK_PATH/bin/mxmlc -load-config+=build-config.xml -incremental=true -optimize=true -static-link-runtime-shared-libraries=true -locale ja_JP -o ./bin/gunyarapaint.swf

cat << CONFIG > build-config.xml
<?xml version="1.0" encoding="utf-8"?>
<flex-config>
  <target-player>10.0.0</target-player>
  <compiler>
    <source-path append="true">
      <path-element>./src</path-element>
    </source-path>
    <library-path append="true">
      <path-element>./libs/colorpicker.swc</path-element>
      <path-element>./libs/framework.swc</path-element>
    </library-path>
  </compiler>
  <file-specs>
    <path-element>./src/gplogplayer.mxml</path-element>
  </file-specs>
  <default-background-color>#FFFFFF</default-background-color>
  <default-frame-rate>30</default-frame-rate>
  <default-size>
    <width>1024</width>
    <height>768</height>
  </default-size>
</flex-config>
CONFIG

$FLEX3_SDK_PATH/bin/mxmlc -load-config+=build-config.xml -incremental=true -optimize=true -static-link-runtime-shared-libraries=true -locale ja_JP -o ./bin/gplogplayer.swf

rm build-config.xml
