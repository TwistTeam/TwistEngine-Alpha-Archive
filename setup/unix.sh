echo Installing dependencies.
haxelib git hxcpp https://github.com/HaxeFoundation/hxcpp --skip-dependencies
haxelib install lime 8.1.3 --skip-dependencies
haxelib run lime setup
haxelib install openfl 9.3.4 --skip-dependencies
haxelib install flixel 5.6.2 --skip-dependencies
haxelib install flixel-addons 3.2.3 --skip-dependencies
haxelib install flixel-ui 2.6.1 --skip-dependencies
haxelib install thx.semver --skip-dependencies
# haxelib install yagp
haxelib install hxvlc --skip-dependencies
haxelib install haxeui-openfl 1.7.0 --skip-dependencies
haxelib git flxanimate https://github.com/Redar13/flxanimate dev --skip-dependencies
# haxelib git away3d https://github.com/CodenameCrew/away3d
haxelib git hscript-improved https://github.com/Redar13/hscript-improved polymod-scripted-classes --skip-dependencies
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit --skip-dependencies
haxelib install hxdiscord_rpc --skip-dependencies
echo Finished!