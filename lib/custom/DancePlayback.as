package custom
{
	import code.skeleton.App;
	
	import com.greensock.TweenLite;
	import com.greensock.plugins.TweenPlugin;
	import com.greensock.plugins.VisiblePlugin;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import org.casalib.events.RemovableEventDispatcher;
	
	public class DancePlayback extends RemovableEventDispatcher
	{
		protected var _ui				:*;
		protected var _currentDanceClip	:MovieClip;
		protected var _progressBar		:ProgressBar;
		protected var _muted			:Boolean;
		protected var _isBigshowFirsttime:Boolean;
		protected var _fullscreen		:Boolean;
		protected var _lastMousePos:Point = new Point(0, 0);
		protected var _autoHideTimeout:uint = 0;
		protected var _playing			:Boolean;
		public var replayCallback:Function;
		public var _appBase:*;
		public var _isStandalonePlayer:Boolean;
		
		public function DancePlayback(ui:*, danceClip:MovieClip, appBase:*, isStandalonePlayer:Boolean = false, isBigshowFirsttime:Boolean = false, _replayCallback:Function = null)
		{
			super();
			TweenPlugin.activate([VisiblePlugin]);
			_ui = ui;
			_appBase = appBase;
			_isStandalonePlayer = isStandalonePlayer;
			_isBigshowFirsttime = isBigshowFirsttime;
			_currentDanceClip = danceClip;
			_ui.visible = false;
			_ui.alpha = 0;
			replayCallback = _replayCallback;
			_init();
		}
		protected function _init():void{
			_progressBar = new ProgressBar(_ui.progress);
			_addListeners();
			_updateUI();
		}
		protected var _forceShow:Boolean;
		public function forceShowControls():void{
			_forceShow = true;
			show();
		}
		protected function _addListeners():void{
			_currentDanceClip.addEventListener(Event.ENTER_FRAME, _onFrame);
		
			_ui.btn_unmute.addEventListener(MouseEvent.CLICK, 		_onUnMuteClicked);
			_ui.btn_mute.addEventListener(MouseEvent.CLICK, 		_onMuteClicked);
			if (_ui.btn_fullScreen) {
				_ui.btn_normalScreen_bsFirsttime.addEventListener(MouseEvent.CLICK, _onToggleFullscreen_bsFirsttime);
				_ui.btn_normalScreen.addEventListener(MouseEvent.CLICK, _onToggleFullscreen);
				_ui.btn_fullScreen.addEventListener(MouseEvent.CLICK, 	_onToggleFullscreen);
			}
			_ui.small_play_button.addEventListener(MouseEvent.CLICK, _onPlayClicked);
			_ui.small_pause_button.addEventListener(MouseEvent.CLICK, _onPauseClicked);
			_ui.btn_replay.addEventListener(MouseEvent.CLICK, 		_onReplayClicked);
			
			_progressBar.addEventListener(Event.CHANGE, _onProgressBarChanged);
			
		}
		
		protected function _onFrame(e:Event):void
		{
			_progressBar.update(_currentDanceClip.currentFrame/_currentDanceClip.totalFrames);
			
			if(_forceShow) return;
			if(_currentDanceClip.parent == null) return;
			var newPos:Point = new Point(_currentDanceClip.mouseX, _currentDanceClip.mouseY);
			var dist:Number = Point.distance(newPos, _lastMousePos);
			
			if (_ui.getRect(_currentDanceClip).containsPoint(newPos)) {
				// Touchin' buttons, force to show	
				dist = 777;
			}else if (!_currentDanceClip.parent.getRect(_currentDanceClip).containsPoint(newPos)) {
				// If not within content viewer	
				dist = 0;
			}
			
			_lastMousePos.x = newPos.x;
			_lastMousePos.y = newPos.y;
			
			if (dist > 1){
				clearTimeout(_autoHideTimeout);
				_autoHideTimeout = setTimeout(hide, 1700);
				
				if (!_ui.visible) show();
			} 

		}
		public function hide(quick:Boolean = false):void{
			if(quick){ 
				_ui.visible = false; 
				_ui.alpha = 0;
				return;
			}
			TweenLite.to(_ui, .5, {alpha:0, visible:false});
		}
		public function show():void{
			_ui.visible = true;
			TweenLite.to(_ui, .35, {alpha:1, visible:true});
		}
		protected function _onReplayClicked(e:MouseEvent):void
		{
			replay();
			
		}
		
		protected function _onPlayClicked(e:MouseEvent):void
		{
			if(_currentDanceClip.currentFrame < _currentDanceClip.totalFrames)	play();
			else replay();
		}
		protected function _onPauseClicked(e:MouseEvent):void
		{
			pause();
		}
		protected function _onMuteClicked(e:MouseEvent):void
		{
			mute();
			
		}
		protected function _onUnMuteClicked(e:MouseEvent):void
		{
			unmute();
		}
		
		protected function _onToggleFullscreen_bsFirsttime(e:MouseEvent):void {
			_appBase._onToggleFullscreen_bsFirsttime(toggleFullscreen_bsFirsttime_fin);

			
			function toggleFullscreen_bsFirsttime_fin(_state:String):void {
				_fullscreen = false; //<=== must be "normalScreen"
				_isBigshowFirsttime = false;
				_updateUI();
			}
		}
		protected function _onToggleFullscreen(e:MouseEvent):void {
			_appBase._onToggleFullscreen(toggleFullscreen_fin);
			
			
			function toggleFullscreen_fin(_state:String):void {
				if (_state == "normalScreen") {
					_fullscreen = false;
				}else if (_state == "fullScreen") {
					_fullscreen = true;
				}
				_updateUI();
			}
		}
		
		protected function _onProgressBarChanged(e:Event):void
		{
			play(_progressBar.progress);
		}		
		public function play(playHeadPercent:Number = -1):void{
			_playing = true;
			_updateUI();
			_forceShow = false;
			if(playHeadPercent > -1){
				_currentDanceClip.gotoAndPlay(Math.round(playHeadPercent*_currentDanceClip.totalFrames));
				_currentDanceClip.allheads.gotoAndPlay(Math.round(playHeadPercent*_currentDanceClip.totalFrames));
			}else{
				_currentDanceClip.play();
				_currentDanceClip.allheads.play();
			}
			if(_isStandalonePlayer==false) _appBase.get_ws_art().bigShow.btn_play.visible = false;
		}
		public function replay(e:Event = null):void
		{
			_playing = true;
			_forceShow = false;
			if(_ui.parent.getChildByName("btn_play")){
				_ui.parent.getChildByName("btn_play").visible= false;
			}
			_updateUI();
			
			if (replayCallback != null) { 
				_currentDanceClip.gotoAndStop(1);
				_currentDanceClip.allheads.gotoAndStop(1);
				destroy();
				hide(true);
				replayCallback();
			}else {
				_currentDanceClip.gotoAndPlay(2);
				_currentDanceClip.allheads.gotoAndPlay(2);
			}
			if(_isStandalonePlayer==false) _appBase.get_ws_art().bigShow.btn_play.visible = false;
		}
		public function pause(e:Event = null):void
		{
			_playing = false;
			_currentDanceClip.stop();
			_currentDanceClip.allheads.stop();
			_updateUI();
			SoundMixer.stopAll();
		}
		public function mute(e:Event = null):void
		{
			var transform:SoundTransform = new SoundTransform(0);
			SoundMixer.soundTransform = transform;	
			_muted = true;
			_updateUI();
		}
		public function unmute(e:Event = null):void
		{
			var transform:SoundTransform = new SoundTransform(1);
			SoundMixer.soundTransform = transform;
			_muted = false;
			_updateUI();
		}
		protected function _updateUI():void
		{
			_ui.btn_unmute.visible = _muted;
			_ui.btn_mute.visible = !muted;
			if (_ui.btn_fullScreen) {
				if (_isBigshowFirsttime) {	
					_ui.btn_normalScreen_bsFirsttime.visible = true;
					_ui.btn_fullScreen.visible = false;
					_ui.btn_normalScreen.visible = false;
				}else {
					_ui.btn_normalScreen_bsFirsttime.visible = false;
					_ui.btn_fullScreen.visible = !_fullscreen;
					_ui.btn_normalScreen.visible = _fullscreen;
				}
			}
			_ui.small_play_button.visible = !_playing;
			_ui.small_pause_button.visible = _playing;
		}
		
		public function get muted():Boolean
		{
			return _muted;
		}
		override public function destroy():void
		{
			_progressBar.removeEventListener(Event.CHANGE, _onProgressBarChanged);
			
			_ui.btn_unmute.removeEventListener(MouseEvent.CLICK, 		_onUnMuteClicked);
			_ui.btn_mute.removeEventListener(MouseEvent.CLICK, 		_onMuteClicked);
			if (_ui.btn_fullScreen) {
				_ui.btn_normalScreen_bsFirsttime.removeEventListener(MouseEvent.CLICK, _onToggleFullscreen_bsFirsttime);	
				_ui.btn_normalScreen.removeEventListener(MouseEvent.CLICK, _onToggleFullscreen);
				_ui.btn_fullScreen.removeEventListener(MouseEvent.CLICK, 	_onToggleFullscreen);
			}
			_ui.small_play_button.removeEventListener(MouseEvent.CLICK, _onPlayClicked);
			_ui.small_pause_button.removeEventListener(MouseEvent.CLICK, _onPauseClicked);
			_ui.btn_replay.removeEventListener(MouseEvent.CLICK, 		_onReplayClicked);
			if(_progressBar) _progressBar.destroy();
			if(_currentDanceClip){
				if(_currentDanceClip.hasEventListener(Event.ENTER_FRAME))	_currentDanceClip.removeEventListener(Event.ENTER_FRAME, _onFrame);
				_currentDanceClip = null;
			}
			super.destroy();		
		}
	}
}