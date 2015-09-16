package custom {
	import flash.display.MovieClip;	
	import player.App;
	
	
	
	public class DancePlayback_player extends DancePlayback{
		
		public function DancePlayback_player(ui:*, danceClip:MovieClip, isBigshowFirsttime:Boolean = false, _replayCallback:Function = null){		
			super(ui, danceClip, App.my_root, true, isBigshowFirsttime, _replayCallback);
		}
	}
}