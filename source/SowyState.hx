package;

// FNF SHIT
import Song;
import Section;
//

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.util.FlxSave;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxStringUtil;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;

// FILE SELECTION SHIT
import openfl.display.Loader;
import openfl.display.LoaderInfo;
import openfl.net.FileReference;
import openfl.net.FileFilter;

import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.utils.ByteArray;
//
import haxe.Json;

class SowyState extends FlxState
{
	var dadData:String;
	var momData:String;

	var jsonFileFilter = [new FileFilter("JSON Files", "*.json")];
	
	var console = new Console(); // to display messages and shit

	var dadStatus:FlxText;
	var momStatus:FlxText;

	override public function create():Void
	{
		FlxG.camera.pixelPerfectRender = true;
		FlxG.camera.antialiasing = false;

		var bg = new FlxSprite();
		bg.frames = Paths.getSparrowAtlas("space");
		bg.animation.addByPrefix("space", "Symbol 1", 60, true);
		bg.animation.play("space", true);
		add(bg);

		add(console);
		console.addTextMessage("hello world!!!");

		////
		var dadButton = new FlxButton(10, 10, "Load Camera Chart", function(){
			var dadFile = new FileReference();
			dadFile.addEventListener(Event.SELECT, _onSelectDad);
			dadFile.addEventListener(Event.CANCEL, function(listener:Event){
				console.addTextMessage("you cancelled!!! ><");
			});
			dadFile.browse(jsonFileFilter);
		});
		dadButton.label.offset.y = 4;
		dadButton.setGraphicSize(80, 30);
		add(dadButton);

		////
		var momButton = new FlxButton(10, 40, "Load Notes Chart", function(){
			var motherFile = new FileReference();
			motherFile.addEventListener(Event.SELECT, _onSelectMom);
			motherFile.addEventListener(Event.CANCEL, function(listener:Event){
				console.addTextMessage("you cancelled!!! ><");
			});
			motherFile.browse(jsonFileFilter);
		});
		momButton.label.offset.y = 4;
		momButton.setGraphicSize(80, 30);
		add(momButton);

		////
		var childButton = new FlxButton(10, 70, "Save Modified Chart", makeBabies);
		childButton.label.offset.y = 4;
		childButton.setGraphicSize(80, 30);
		add(childButton);

		////
		dadStatus = new FlxText(0, 10, 0, "Nothing.");
		dadStatus.setPosition(10 + dadButton.x + dadButton.width, 10 + dadButton.y);
		add(dadStatus);

		momStatus = new FlxText(0, 40, 0, "Nothing.");
		momStatus.setPosition(10 + momButton.x + momButton.width, 10 + momButton.y);
		add(momStatus);

		////
		super.create();
	}

	//// DAD FILE SELECTION SHIT
	function _onSelectDad(E:Event):Void
	{
		var fr:FileReference = cast(E.target, FileReference);
		fr.addEventListener(Event.COMPLETE, _onLoadDad, false, 0, true);
		fr.load();

		console.addTextMessage('Loading dad: "' + fr.name + '"');
	}
	function _onLoadDad(E:Event):Void
	{
		var fr:FileReference = cast E.target;
		fr.removeEventListener(Event.COMPLETE, _onLoadDad);

		// it just works, so im going to stick with this
		dadData = FlxStringUtil.formatArray([fr.data]);  

		dadStatus.text = fr.name;

		console.addTextMessage("Dad file successfully loaded");
	}

	//// THE SAME SHIT BUT REPEATED
	function _onSelectMom(E:Event):Void
	{
		var fr:FileReference = cast(E.target, FileReference);
		fr.addEventListener(Event.COMPLETE, _onLoadMom, false, 0, true);
		fr.load();

		console.addTextMessage('Loading mom: "' + fr.name + '"');
	}
	function _onLoadMom(E:Event):Void
	{
		var fr:FileReference = cast E.target;
		fr.removeEventListener(Event.COMPLETE, _onLoadDad);

		// it just works, so im going to stick with this
		momData = FlxStringUtil.formatArray([fr.data]);  

		momStatus.text = fr.name;

		console.addTextMessage("Mom file successfully loaded");
	}

	function makeBabies()
	{
		if (!(dadData != null && momData != null))
		{
			console.addTextMessage("You're missing files bro.");
			return;
		}
		
		////
		var cameraChart:SwagSong = Song.loadFromRawJson(dadData);
		var _song:SwagSong = Song.loadFromRawJson(momData);

		for (i in 0...cameraChart.notes.length){
			var cameraSection = cameraChart.notes[i];
			var chartedSection = _song.notes[i];

			if (cameraSection == null || chartedSection == null){
				trace("broke!!");
				break;
			}
				
			if (cameraSection.mustHitSection != chartedSection.mustHitSection){
				chartedSection.mustHitSection = !chartedSection.mustHitSection;
				
				for (i in 0...chartedSection.sectionNotes.length){
					var note = chartedSection.sectionNotes[i];
					note[1] = (note[1] + 4) % 8;
					chartedSection.sectionNotes[i] = note;
				}
			}

			_song.notes[i] = chartedSection;
		}

		/*
		var playerNotes:Array<Array<Dynamic>> = [];
		var opponentNotes:Array<Array<Dynamic>> = [];

		for (section in dadChart.notes){
			for (note in section.sectionNotes){
				var container = (note > 3 && section.mustHitSection) ? playerNotes : opponentNotes; 

				container.push(note);
				section.sectionNotes.remove(note) ? continue : trace("this didn't work idiot");
			}
			dadChart.notes.remove(section); // remove shit because im a schizo
		}
		dadChart = null;

		//// begin transplant
		var curSec = 0; // current Section

		function getSectionBeats(?section:Null<Int> = null)
		{
			if (section == null) section = curSec;
			var val:Null<Float> = null;
			
			if(_song.notes[section] != null) val = _song.notes[section].sectionBeats;
			return val != null ? val : 4;
		}

		function sectionStartTime(add:Int = 0):Float{
			var daBPM:Float = _song.bpm;
			var daPos:Float = 0;
			for (i in 0...curSec + add)
			{
				if(_song.notes[i] != null)
				{
					if (_song.notes[i].changeBPM)
					{
						daBPM = _song.notes[i].bpm;
					}
					daPos += getSectionBeats(i) * (1000 * 60 / daBPM);
				}
			}
			return daPos;
		}

		for (sectionNumber in 0..._song.notes.length){
			var section = _song.notes[sectionNumber];
			// empty the chart first
			for (note in section.sectionNotes)
			{
				section.sectionNotes = [];
			}
			
			curSec = sectionNumber;

			var startThing:Float = sectionStartTime();
			var endThing:Float = sectionStartTime(1);
			
			for (note in playerNotes)
			{
				var strumTime = note[0];

				if (strumTime >= startThing && strumTime < endThing){
					if (section.mustHitSection)
						note[1] += 4;

					section.sectionNotes.push(note);
					playerNotes.remove(note);
				}
			}

			for (note in opponentNotes)
			{
				var strumTime = note[0];

				if (strumTime >= startThing && strumTime < endThing){
					if (!section.mustHitSection)
						note[1] += 4;

					section.sectionNotes.push(note);
					opponentNotes.remove(note);
				}
			}
		}
		*/

		//// save the resulting chart
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			var _file = new FileReference();
			_file.addEventListener(Event.COMPLETE, function(listener:Event){
				console.addTextMessage("Save complete! :D");
			});
			_file.addEventListener(Event.CANCEL, function(listener:Event){
				console.addTextMessage("Save canceled");
			});
			_file.addEventListener(IOErrorEvent.IO_ERROR, function(listener:Event){
				console.addTextMessage("There was an error saving the file");
			});
			_file.save(data, Paths.formatToSongPath(_song.song) + ".json");
		}
		else
			console.addTextMessage("An error ocurred.");
	}

	#if !FLX_NO_KEYBOARD
	var clock:Float = 0;
	override public function update(elapsed:Float):Void
	{
		clock += elapsed;

		if (FlxG.keys.justPressed.ANY || FlxG.keys.pressed.ANY && clock > 0.5){
			console.addTextMessage("yooo");
			clock -= 0.5;
		}

		super.update(elapsed);
	}
	#end
}

class Console extends FlxTypedGroup<ConsoleText>
{
	function updatePositions(){
		for (i in 0...members.length){
			var prevInst = members[i-1];
			var instance = members[i];
			instance.targetY = (prevInst != null ? prevInst.targetY : FlxG.height) - instance.frameHeight; 
		}
	}
	override function remove(instance:ConsoleText, splice:Bool = true):ConsoleText
	{
		var r = super.remove(instance, splice);
		updatePositions();
		return r;
	}
	override function add(instance:ConsoleText):ConsoleText
	{
		instance.parent = this;

		var r = super.add(instance);
		updatePositions();
		return r;	
	}

	public function addTextMessage(text:Dynamic = ""){
		trace(text);
		add(new ConsoleText(0, 0, 0, Std.string(text)));
	}
}
class ConsoleText extends FlxText
{
	public var timeElapsed:Float = 0;
	public var parent:Console;
	public var targetY:Float = 0;

	override function update(elapsed:Float){
		timeElapsed += elapsed;

		y = Std.int(FlxMath.lerp(y, targetY, elapsed * 10.2));
		alpha = FlxMath.lerp(1, 0.15, (timeElapsed / 6));

		super.update(elapsed);

		if (timeElapsed > 6){
			if (parent != null) parent.remove(this);
			destroy();
		}
	}
}