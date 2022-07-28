package;

import js.html.PlaybackDirection;
import ui.PreferencesMenu;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class GameOverSubstate extends MusicBeatSubstate
{
	var bf:Boyfriend;
	var camFollow:FlxObject;

	var stageSuffix:String = "";

	var playingDeathSound:Bool = false;
	var randomGameover:Int = 1;

	public function new(x:Float, y:Float)
	{
		var daBf:String = '';
		if (PlayState.pixelStage == true)
		{
			stageSuffix = '-pixel';
			daBf = 'bf-pixel-dead';
		}
		else if (PlayState.SONG.song.toLowerCase() == 'stress')
		{
			daBf = 'bf-holding-gf-dead';
		}
		else
		{
			daBf = 'bf';
		}
		super();

		Conductor.songPosition = 0;

		bf = new Boyfriend(x, y, daBf);
		add(bf);

		camFollow = new FlxObject(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y, 1, 1);
		add(camFollow);

		FlxG.sound.play(Paths.sound('fnf_loss_sfx' + stageSuffix));
		Conductor.changeBPM(100);

		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		bf.playAnim('firstDeath');

		var exclude = [];
		if (PreferencesMenu.getPref('censor-naughty'))
			exclude = [1, 3, 8, 13, 17, 21];
		randomGameover = FlxG.random.int(1, 25, exclude);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();

			endSong();
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.curFrame == 12)
		{
			FlxG.camera.follow(camFollow, LOCKON, 0.01);
		}

		if (PlayState.storyWeek == 7)
		{
			if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished && !playingDeathSound)
			{
				playingDeathSound = true;
				FlxG.sound.music.fadeOut(0.1, 0.2);
				FlxG.sound.play(Paths.sound('jeffGameover/jeffGameover-' + randomGameover), 1, false, null, true, function()
				{
					FlxG.sound.music.fadeIn(4, 1, 1);
				});
			}
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
		{
			FlxG.sound.playMusic(Paths.music('gameOver' + stageSuffix));
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
	}

	override function beatHit()
	{
		super.beatHit();

		FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			bf.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music('gameOverEnd' + stageSuffix));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					LoadingState.loadAndSwitchState(new PlayState());
				});
			});
		}
	}

	function endSong() 
	{
		if (PlayState.isStoryMode)
			FlxG.switchState(new StoryMenuState());
		else 
			FlxG.switchState(new FreeplayState());

		GameStatsState.lastPlayed = PlayState.SONG.song;
		GameStatsState.icon = PlayState.gameVar.iconP2.char;
		GameStatsState.iconColour = PlayState.gameVar.dad.iconColour;

		GameStatsState.totalNotesHit += PlayState.gameVar.songHits;
		GameStatsState.totalSicks += PlayState.gameVar.sicks;
		GameStatsState.totalGoods += PlayState.gameVar.goods;
		GameStatsState.totalBads += PlayState.gameVar.bads;
		GameStatsState.totalShits += PlayState.gameVar.shits;
		GameStatsState.totalMisses += PlayState.gameVar.songMisses;
		GameStatsState.totalBlueballed += PlayState.blueballed;

		GameStatsState.songNotesHit = PlayState.gameVar.songHits;
		GameStatsState.songSicks = PlayState.gameVar.sicks;
		GameStatsState.songGoods = PlayState.gameVar.goods;
		GameStatsState.songBads = PlayState.gameVar.bads;
		GameStatsState.songShits = PlayState.gameVar.shits;
		GameStatsState.songMisses = PlayState.gameVar.songMisses;
		GameStatsState.songBlueballed = PlayState.blueballed;

		GameStatsState.saveGameData();

		PlayState.blueballed = 0;
		PlayState.seenCutscene = false;
	}
}
