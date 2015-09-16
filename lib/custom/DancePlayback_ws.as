package custom {
	import flash.display.MovieClip;	
	import code.skeleton.App;
	
	
	
	public class DancePlayback_ws extends DancePlayback{
		
		public function DancePlayback_ws(ui:*, danceClip:MovieClip, isBigshowFirsttime:Boolean = false, _replayCallback:Function = null){	
			super(ui, danceClip, App.mediator, false, isBigshowFirsttime, _replayCallback);
		}
	}
}