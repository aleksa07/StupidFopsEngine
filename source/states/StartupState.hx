package states;

import flixel.input.keyboard.FlxKey;

class StartupState extends MusicBeatState
{
	var logo:FlxSprite;
	var skipTxt:FlxText;

	var canChristmas = false;
	var canAutism = false;

	// All video names found in the splash video folder
	var splashVideos:Array<String> = [];

	private var vidSprite:VideoSprite = null;

	private function startVideo(name:String, ?library:String = null, ?callback:Void->Void = null, canSkip:Bool = true, loop:Bool = false, playOnLoad:Bool = true)
	{
		#if VIDEOS_ALLOWED
		var foundFile:Bool = false;
		var fileName:String = Paths.legacyvideo(name, library);

		#if sys
		if (FileSystem.exists(fileName))
		#else
		if (OpenFlAssets.exists(fileName))
		#end
		foundFile = true;

		if (foundFile)
		{
			vidSprite = new VideoSprite(fileName, false, canSkip, loop);
			vidSprite.scrollFactor.set();

			function onVideoEnd()
			{
				FlxG.switchState(TitleState.new);
			}
			vidSprite.finishCallback = (callback != null) ? callback.bind() : onVideoEnd;
			vidSprite.onSkip = (callback != null) ? callback.bind() : onVideoEnd;
			insert(0, vidSprite);

			if (playOnLoad)
				vidSprite.videoSprite.play();
			return vidSprite;
		}
		else
		{
			FlxG.log.error("Video not found: " + fileName);
			new FlxTimer().start(0.1, function(tmr:FlxTimer) {
				FlxG.switchState(TitleState.new);
			});
		}
		#else
		FlxG.log.warn('Platform not supported!');
		new FlxTimer().start(0.1, function(tmr:FlxTimer) {
			FlxG.switchState(TitleState.new);
		});
		#end
		return null;
	}

	// Scans the splash video folder and collects ALL video file names (without extension)
	function scanSplashVideos():Void
	{
		splashVideos = [];

		#if sys
		// Use a dummy name to resolve what folder Paths points to for 'splash' videos
		var samplePath:String = Paths.legacyvideo('_dummy_', 'splash');
		var folderPath:String = haxe.io.Path.directory(samplePath);

		FlxG.log.notice('Scanning video folder: ' + folderPath);

		if (FileSystem.exists(folderPath) && FileSystem.isDirectory(folderPath))
		{
			for (file in FileSystem.readDirectory(folderPath))
			{
				var ext:String = haxe.io.Path.extension(file).toLowerCase();
				if (ext == 'mp4' || ext == 'webm' || ext == 'ogv' || ext == 'avi' || ext == 'mov')
				{
					var baseName:String = haxe.io.Path.withoutExtension(file);
					splashVideos.push(baseName);
				}
			}
		}
		else
		{
			FlxG.log.error('Splash video folder not found: ' + folderPath);
		}
		#end

		FlxG.log.notice('Found ${splashVideos.length} splash video(s): ' + splashVideos.join(', '));
	}

	override public function create():Void
	{
		if (DateUtils.isChristmas())
			canChristmas = true;
		else if (DateUtils.isAprilFools())
			canAutism = true;

		// Scan folder first so splashVideos is populated before doIntro runs
		scanSplashVideos();

		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;

		logo = new FlxSprite().loadGraphic(Paths.image('sillyLogo', 'splash'));
		logo.scrollFactor.set();
		logo.screenCenter();
		logo.alpha = 0;
		logo.active = true;
		add(logo);

		skipTxt = new FlxText(0, FlxG.height, 0, 'Press ENTER To Skip', 16);
		skipTxt.setFormat("vcr", 18, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		skipTxt.borderSize = 1.5;
		skipTxt.antialiasing = true;
		skipTxt.scrollFactor.set();
		skipTxt.alpha = 0;
		skipTxt.y -= skipTxt.textField.textHeight;
		if (vidSprite != null)
			insert(1, skipTxt);
		else
			add(skipTxt);

		FlxTween.tween(skipTxt, {alpha: 1}, 1);

		new FlxTimer().start(0.1, function(tmr:FlxTimer) {
			doIntro();
		});

		super.create();
	}

	function doIntro()
	{
		#if debug
		// In debug: always play the first video found
		if (splashVideos.length > 0)
			startVideo(splashVideos[0], 'splash');
		else
			FlxG.switchState(TitleState.new);
		#else
		if (splashVideos.length == 0)
		{
			FlxG.log.warn('No splash videos found, skipping to title.');
			FlxG.switchState(TitleState.new);
			return;
		}

		// Pick a random video from everything in the folder
		var picked:String = splashVideos[FlxG.random.int(0, splashVideos.length - 1)];
		FlxG.log.notice('Playing splash video: ' + picked);
		startVideo(picked, 'splash');
		#end
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.ENTER) FlxG.switchState(TitleState.new);
		super.update(elapsed);
	}
}
