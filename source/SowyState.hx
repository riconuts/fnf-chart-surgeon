package;

// FNF SHIT
import Song;
import Section;

//
import haxe.Json;

//
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.text.FlxText;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;

// FILE SELECTION SHIT
import openfl.display.Loader;
import openfl.display.LoaderInfo;
import openfl.net.FileReference;
import openfl.net.FileFilter;

import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.utils.ByteArray;

class SowyState extends FlxState
{
	var dadData:String;
	var momData:String;

	var dadStatus:FlxText;
	var momStatus:FlxText;

	var jsonFileFilter = [new FileFilter("JSON Files", "*.json")];

	var console = new Console(); // to display messages and shit

	static var welcomeTexts = ["hello!!!!", "hiiii", ":)", "yooo"];
	inline static function getWelcomeMessage():String
		return welcomeTexts[Std.random(welcomeTexts.length)];
	inline function salute()
		console.addTextMessage(getWelcomeMessage());

	override public function create():Void
	{
		FlxG.camera.pixelPerfectRender = true;

		var bg = new FlxSprite();
		bg.frames = Paths.getSparrowAtlas("space");
		bg.animation.addByPrefix("space", "Symbol 1", 60, true);
		bg.animation.play("space", true);
		add(bg);

		add(console);
		salute();

		////
		var dadButton = new FlxButton(10, 10, "Load Notes Chart", function(){
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
		var momButton = new FlxButton(10, 40, "Load Camera Chart", function(){
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
		dadStatus = new FlxText(0, 10, 0, "Nothing loaded.");
		dadStatus.setPosition(10 + dadButton.x + dadButton.width, 10 + dadButton.y);
		add(dadStatus);

		momStatus = new FlxText(0, 40, 0, "Nothing loaded.");
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

		dadData = Std.string(fr.data);  

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
		fr.removeEventListener(Event.COMPLETE, _onLoadMom);

		momData = Std.string(fr.data);  

		momStatus.text = fr.name;
		console.addTextMessage("Mom file successfully loaded");
	}

	function getSectionBeats(song:SwagSong, secNum:Int):Float
	{
		var val:Null<Float> = null;
		
		if(song.notes[secNum] != null) 
			val = song.notes[secNum].sectionBeats;
		
		return (val!=null) ? val : 4;
	}

	function sectionStartTime(song:SwagSong, secNum:Int):Float
	{
		var daBPM:Float = song.bpm;
		var daPos:Float = 0;
		
		for (i in 0...secNum)
		{
			if(song.notes[i] != null)
			{
				if (song.notes[i].changeBPM)
				{
					daBPM = song.notes[i].bpm;
				}
				daPos += getSectionBeats(song, i) * (1000 * 60 / daBPM);
			}
		}
		return daPos;
	}

	/** Sorts note info on ascending order **/
	static function sortNoteInfo(a:Array<Dynamic>, b:Array<Dynamic>)
	{
		if (a[0] == b[0])
			return 0;

		return (a[0] < b[0]) ? -1 : 1;
	}

	/**Ok so I called them Mom and Dad, cause the Dad stuff goes into the Mom and makes the baby. Yeah.**/
	function makeBabies()
	{
		if (dadData == null || momData == null)
		{
			console.addTextMessage("You're missing files dude!");
			return;
		}
		
		////
		var notesChart:SwagSong = Song.loadFromRawJson(dadData);
		var cameraChart:SwagSong = Song.loadFromRawJson(momData);

		// clean up sections
		for (section in cameraChart.notes)
			section.sectionNotes = [];

		// get notes
		var allNotes:Array<Array<Dynamic>> = [];
		while (notesChart.notes.length > 0){
			var section = notesChart.notes.pop();

			while (section.sectionNotes.length > 0){
				var noteInfo = section.sectionNotes.pop();
				if (!section.mustHitSection)
					(noteInfo[1] > 3 ? noteInfo[1]-=4 : noteInfo[1]+=4);
				
				allNotes.push(noteInfo);	
			}
		}
		allNotes.sort(sortNoteInfo);

		// do the thang
		for (sectionNum in 0...cameraChart.notes.length)
		{
			if (allNotes.length == 0)
				break;
			
			var section:SwagSection = cameraChart.notes[sectionNum];
			var startTime:Float = sectionStartTime(cameraChart, sectionNum);
			var endTime:Float = sectionStartTime(cameraChart, sectionNum+1);

			while (allNotes.length > 0){
				var noteInfo = allNotes[0];
				var noteTime = noteInfo[0];

				if (noteTime >= startTime && noteTime < endTime){
					if (!section.mustHitSection) 
						(noteInfo[1] > 3 ? noteInfo[1]-=4 : noteInfo[1]+=4);

					section.sectionNotes.push(noteInfo);
					allNotes.shift();
				}else{
					break;
				}
			}
		}

		if (allNotes.length > 0)
			console.addTextMessage('Warning! ${allNotes.length} notes weren\'t added to any section :o');

		//// save the resulting chart
		var json = {
			"song": cameraChart,
			"sowy": true
		};

		var data:String = Json.stringify(json, "\t");

		if (data == null || data.length == 0){
			console.addTextMessage('An error ocurred. Resulting data is invalid?');
			trace(data);
		}else{
			var _file = new FileReference();
			_file.addEventListener(Event.COMPLETE, function(listener:Event){
				console.addTextMessage("Save complete! :D");
			});
			_file.addEventListener(Event.CANCEL, function(listener:Event){
				console.addTextMessage("Save canceled :|");
			});
			_file.addEventListener(IOErrorEvent.IO_ERROR, function(listener:Event){
				console.addTextMessage("There was an error saving the file");
			});
			_file.save(data, Paths.formatToSongPath(cameraChart.song) + ".json");
		}
	}

	#if !FLX_NO_KEYBOARD
	var clock:Float = 0;
	override public function update(elapsed:Float):Void
	{
		clock += elapsed;

		if (FlxG.keys.justPressed.ANY || FlxG.keys.pressed.ANY && clock > 0.5){
			salute();
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