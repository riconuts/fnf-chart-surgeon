package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.math.FlxRandom;
import openfl.Lib;
import openfl.Assets;
import openfl.events.Event;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;

using StringTools;

#if CRASH_HANDLER
import haxe.CallStack;
import lime.app.Application;
import openfl.events.UncaughtErrorEvent;

#if sys
import sys.io.File;
#end

#if (windows && cpp)
@:cppFileCode('#include <windows.h>')
#end
#end

class Main extends Sprite
{
	var gameWidth:Int = 480; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 320; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = SowyState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = false; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}
		
		addChild(new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen));
		flixel.FlxG.scaleMode = new flixel.system.scaleModes.PixelPerfectScaleMode();

		#if CRASH_HANDLER
		// Original code was made by sqirra-rng, big props to them!!!
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
			UncaughtErrorEvent.UNCAUGHT_ERROR, 
			(event:UncaughtErrorEvent)->{
				onCrash(event.error);
			}
		);


		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onCrash);
		#end
		#end
	}

	
	#if CRASH_HANDLER
	function onCrash(errorName:String):Void
	{
		////
		var ogTrace = haxe.Log.trace;
		haxe.Log.trace = (msg, ?pos)->{
			ogTrace(msg, null);
		}

		////
		trace("\nCall stack starts below");

		var callstack:String = "";

		for (stackItem in CallStack.exceptionStack(true))
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					callstack += '$file:$line\n';
				default:
			}
		}

		callstack += '\n$errorName';

		trace('\n$callstack\n');

		#if sys
		File.saveContent("crash.txt", callstack);
		#end

		#if (windows && cpp)
		windows_showErrorMsgBox(callstack, errorName);
		#else
		Application.current.window.alert(callstack, errorName);
		#end

		#if sys
		Sys.exit(1);
		#end
	}

	#if (windows && cpp)
	@:functionCode('MessageBox(NULL, message, title, MB_ICONERROR | MB_OK);')
	function windows_showErrorMsgBox(message:String, title:String){}
	#end

	#end
}