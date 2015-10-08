package custom
{
	import code.HeadStruct;
	import code.skeleton.App;
	
	import com.greensock.TweenLite;
	import com.oddcast.event.AlertEvent;
	import com.oddcast.utils.URL_Opener;
	import com.oddcast.utils.gateway.Gateway;
	import com.oddcast.utils.gateway.Gateway_Request;
	import com.oddcast.workshop.Callback_Struct;
	import com.oddcast.workshop.SceneStruct;
	import com.oddcast.workshop.ServerInfo;
	import com.oddcast.workshop.WSBackgroundStruct;
	import com.oddcast.workshop.WSEventTracker;
	import com.oddcast.workshop.WorkshopMessage;
	
	import flash.display.*;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	
	import org.casalib.util.ArrayUtil;
	import org.casalib.util.RatioUtil;
	
	public class DanceScene extends Sprite
	{
		//[Embed(source="../../src/art/idle_vid01.swf")]
		//private var Idle:Class;
		
		private var _idleLoader				:*;
		private var _idle					:MovieClip;
		
		private var _currentDanceClip		:MovieClip;
		
		private var _heads					:Array;
		private var _mouths					:Array;
		private var _mask					:Sprite;
		
		private var _danceIndex				:Number = 0;
		private var DANCE_INDEX_WITH_MOUTH	:Number = 7;
		
		protected var _looping				:Boolean = false;
		
		protected var _currentLoop			:Number;
		protected var _lastFrame			:Number;
		
		protected var _loops				:Array = [ "idle1", "idle2", "idle3" ];
		
		protected var _useOddIdleLoop		:Boolean;
		
		/*** USED FOR BIG SHOW ***/
		private var _inBigShow				:Boolean;
		private var _isBigshowFirsttime		:Boolean=true;
		
		private var mid_message				:WorkshopMessage;
		private var _gotoEditStateCallback	:Function;
		private var _headsToBeLoaded		:Array;
		private var _headsToBeLoadedNum		:Number;
		
		private var _enhancedToBeLoaded		:Array = [];
		
		
		private static const LOADING_HEADS	:String = "LOADING HEADS";
		private static const LOADING_DANCE	:String = "LOADING DANCE";
		
		private static const START_X:Number = 0;
		private static const START_Y:Number = 0;
		
		private var _bigShowUI:BigShow_UI;
		private var _mainUI:MainPlayerHolder;
		
		public function DanceScene()
		{
			super();
			
			x  = START_X;
			y = START_Y;
			
			
			// listen for when the app is considered to have loaded and initialized all assets
			var loaded_event:String = App.mediator.EVENT_WORKSHOP_LOADED;
			App.listener_manager.add(App.mediator, loaded_event, app_initialized, this);
			App.listener_manager.add(App.mediator, App.mediator.EVENT_WORKSHOP_LOADED_EDITING_STATE, in_editing_state, this);
			
			_mainUI = App.ws_art.mainPlayer;
			_mainUI.visible 		= false;
			
			_bigShowUI = App.ws_art.bigShow;
			_bigShowUI.visible = false;
			
			App.ws_art.printProcessing.visible 	= false;
			App.ws_art.printReady.visible 		= false;
			App.ws_art.pinProcessing.visible 	= false;
			App.ws_art.pinReady.visible 		= false;
			// provide the mediator a reference to send data to this controller
			var registered:Boolean = App.mediator.register_controller(this);
			
			/** called when the application has finished the inauguration process */
			function app_initialized(_e:Event):void
			{
				App.listener_manager.remove_caught_event_listener( _e, arguments );
				// init this after the application has been inaugurated
				if(!_hasBeenInit) _init();
			}
			function in_editing_state(e:Event):void{
				danceIndex = START_DANCE_INDEX;
				if(App.asset_bucket.danceScenes[0]) _currentDanceClip = App.asset_bucket.danceScenes[0];
				var danceScenes:Array = App.asset_bucket.danceScenes;
				// don't know when this would be called...
				
				
				_videoControls = _mainUI.video_controls;
				_mainUI.player_hold.addChild(_hold.parent);
			
				_bigShowUI.visible = false;
			}

		}
		protected var _playback:DancePlayback;
		protected var _hasBeenInit:Boolean;
		protected var _hold:Sprite;
		
		private function _init():void
		{
			
			
			addEventListener(Event.ENTER_FRAME, _onEnterFrame);
			
			//make them all null so we can loop through later
			_heads = []//null,null,null,null,null];
			_mouths = []//null,null,null,null,null];
			
			_mainUI.end_greeting.visible = false;
			_bigShowUI.end_greeting.visible = false;
			
			_hold = new Sprite();
			this.addChild(_hold);
			
			_bigShowUI.end_greeting.visible = false;
			
			App.ws_art.stop_btn.visible = false;
			_mainUI.visible = false;
			_bigShowUI.btn_play.visible= false;
			
			_hasBeenInit = true;
			
			App.listener_manager.add_multiple_by_object(  [_bigShowUI.btn_play,
															_mainUI.end_screen.btn_replay], MouseEvent.CLICK, _onReplayClicked, this );
			
			_mainUI.btn_create_another.addEventListener(MouseEvent.CLICK, _onCreateAnotherClicked);
			_mainUI.btn_elfYourselfLogo.addEventListener(MouseEvent.CLICK, _onElfYourselfLogoClicked);
			_mainUI.btn_elfYourselfLogo.buttonMode = true;
			
			_danceButtons = [	_mainUI.danceBtns.btn_dance1,
								_mainUI.danceBtns.btn_dance2,
								_mainUI.danceBtns.btn_dance3,
								_mainUI.danceBtns.btn_dance4,
								_mainUI.danceBtns.btn_dance5,
								_mainUI.danceBtns.btn_dance6,
								_mainUI.danceBtns.btn_dance7,
								_mainUI.danceBtns.btn_dance8,
								_mainUI.danceBtns.btn_dance9,
								_mainUI.danceBtns.btn_dance10,
								_mainUI.danceBtns.btn_dance11,
								_mainUI.danceBtns.btn_dance12,
								_mainUI.danceBtns.btn_dance13,
								_mainUI.danceBtns.btn_dance14];
								//_mainUI.danceBtns.btn_dance15];
								//_mainUI.danceBtns.btn_dance13];
			
			
			_mainUI.danceBtns.btn_dance15.addEventListener(MouseEvent.CLICK, _onHousePartyBtnClicked);
			_mainUI.danceBtns.btn_dance14.addEventListener(MouseEvent.CLICK, _onHanBtnClicked);
			App.listener_manager.add_multiple_by_object(  _danceButtons, MouseEvent.CLICK, _onDanceBtnClicked, this );
			App.ws_art.makeAnother.btn_select_a_dance.addEventListener(MouseEvent.CLICK, _onSelectADanceClicked);
			App.ws_art.makeAnother.btn_elfYourselfLogo.addEventListener(MouseEvent.CLICK, _onElfYourselfLogoClicked);
			
			var art:MainPlayerHolder = _mainUI;
			App.listener_manager.add_multiple_by_object(  [art.btn_create_another, 
															art.btn_merch, 
															art.btn_details, 
															art.btn_storedownload,
															art.shareBtns.email_btn,
															art.shareBtns.get_url_btn,
															art.shareBtns.facebook_btn,
															art.shareBtns.twitter_btn,
															art.shareBtns.pintrest_btn,
															art.shareBtns.embed_btn, art.btn_deals], MouseEvent.CLICK, _onMiscBtnClicked, this );
			art.btn_deals.addEventListener(MouseEvent.CLICK, _onDealsClick);
			art.shareBtns.pintrest_btn.addEventListener(MouseEvent.CLICK, _onPinterestClick);
			art.btn_merch.addEventListener(MouseEvent.CLICK, _onShopClick);
			art.btn_details.addEventListener(MouseEvent.CLICK, _onDetailsClick);
			art.btn_edit.addEventListener(MouseEvent.CLICK, _onEditClicked);
			
			art.enhanced_prompt.btn_nothanks.addEventListener(MouseEvent.CLICK, _onNoThanksClicked);
			art.enhanced_end.btn_clear_photos.addEventListener(MouseEvent.CLICK, _onClearPhotosClicked);
			art.enhanced_end.btn_new_photos.addEventListener(MouseEvent.CLICK, _onNewPhotosClicked);
			art.enhanced_end.btn_lets_dance.addEventListener(MouseEvent.CLICK, _onLetsDanceClicked);
			art.enhanced_end.visible = false;
			art.enhanced_prompt.visible = false;
			//_mainUI.btn_reset.addEventListener(MouseEvent.CLICK, _onPlayFromBeginningClicked);
			App.ws_art.stage.addEventListener(KeyboardEvent.KEY_DOWN, _onKeyPress);
			App.ws_art.stage.addEventListener(KeyboardEvent.KEY_UP	, _onKeyUp);
		}
		protected var _sPressed:Boolean;
		
		
		protected function _onKeyPress(e:KeyboardEvent):void{
			if(e.charCode == 115){
				_sPressed = true;
			}
			
		}
		protected function _onKeyUp(e:KeyboardEvent):void
		{
			_sPressed = false;
		}
		protected function _comingSoon(e:MouseEvent):void
		{
			App.mediator.doTrace("xxxxx 111===> _comingSoon");
			if(_playback) _playback.pause();
			App.ws_art.comingSoon.visible = true;
		}
		protected function _onDownloadClick(e:MouseEvent = null):void
		{
			//http://host.oddcast.com/api_misc/1177/checkout.php?mId={mid}&email={email}&optin={optin 0/1}
			//"http://host.oddcast.com/api_misc/1177/checkout.php?mId="+mID+"&email="+email+"&optin="{optin 0/1}";
			
		}
		//onCalendarClick old
		protected function _onDealsClick(e:MouseEvent):void
		{
			WSEventTracker.event("ce23");
			//new DanceScreenShot(this._heads, this._mouths, "doPrint");
			App.mediator.open_hyperlink(App.mediator.LOGO_LINK, "_blank");
		}
		protected function _onPinterestClick(e:MouseEvent):void
		{
			new DanceScreenShot(this._heads, this._mouths, "doPinterest");
			WSEventTracker.event("ce21");
		}
		protected function _onShopClick(e:MouseEvent):void{
			WSEventTracker.event("ce16");	
			var DETAILS_LINK:String = "http://www.officemax.com/home/custom.jsp?id=m590006";
			URL_Opener.open_url( DETAILS_LINK, "_blank");
		}
		protected function _onDetailsClick(e:MouseEvent):void{
			var DETAILS_LINK:String = "http://www.google.com/";
			URL_Opener.open_url( DETAILS_LINK, "_blank");
		}
		protected function _onEditClicked(e:MouseEvent):void
		{						
			WSEventTracker.event("ce24");
			if(_playback) _playback.pause();
			
			_currentDanceClip.stop();
			_currentDanceClip.allheads.stop();
			SoundMixer.stopAll();
			
			App.ws_art.stop_btn.visible 	= false;
			_mainUI.visible 	= false;
			
			_danceIndex = START_DANCE_INDEX;
			App.asset_bucket.danceScenes = [];
				
			App.mediator.gotoMakeAnother();
				
		}
		protected function _onMiscBtnClicked(e:MouseEvent):void
		{
			if(_playback) _playback.pause();
		}
		protected function _onPlayFromBeginningClicked(e:MouseEvent):void
		{
			if(_currentDanceClip)
			{
				_currentDanceClip.gotoAndPlay(2);
				_currentDanceClip.allheads.gotoAndPlay(2);
			}
		}
		
		protected static const START_DANCE_INDEX:Number = 0;//11;
		protected function _onCreateAnotherClicked(e:MouseEvent):void
		{
			_currentDanceClip.stop();
			_currentDanceClip.allheads.stop();
			SoundMixer.stopAll();
			
			function startOver(_ok:Boolean):void
			{
				if(!_ok) return;
				_danceIndex = START_DANCE_INDEX;
				App.ws_art.stop_btn.visible 	= false;
				_mainUI.visible 	= false;
				App.mediator.clearHeads();
				heads = [];
				App.asset_bucket.danceScenes = [];
				App.asset_bucket.enhancedPhotos = [];
				App.asset_bucket.endGreeting = null;
				App.mediator.autophoto_open_mode_selector();
			}
			App.mediator.alert_user(new AlertEvent(AlertEvent.ALERT, "startOver", "Are you sure you want to discard your video and start over?", null, startOver));			
			WSEventTracker.event("ce25");
		}
		protected function _onSelectADanceClicked(e:MouseEvent):void
		{
			//_mainUI.visible = false;
			App.ws_art.makeAnother.visible = false;
			App.ws_art.dancers.visible = false;
			
			var headCount:int = 0;
			for(var i:Number = 0; i<App.mediator.savedHeads.length; i++){
				if(App.mediator.savedHeads[i] != null) headCount++;
			}
			WSEventTracker.event("ce17", null, headCount);
			dance();
		}
		
		protected function _updateDanceButtons():void
		{
			var art:MainPlayerHolder = _mainUI;
			App.ws_art.han_bg.visible = danceIndex == Dances.HAN_DANCE_INDEX;
			//var overs:Array = [art.danceBtns.btn_dance1_over, art.danceBtns.btn_dance2_over, art.danceBtns.btn_dance3_over, art.danceBtns.btn_dance4_over, art.danceBtns.btn_dance5_over, art.danceBtns.btn_dance6_over, art.danceBtns.btn_dance7_over, art.danceBtns.btn_dance8_over, art.danceBtns.btn_dance9_over, art.danceBtns.btn_dance10_over, ];
			//var btns:Array = [art.danceBtns.btn_dance1, art.danceBtns.btn_dance2, art.danceBtns.btn_dance3, art.danceBtns.btn_dance4, art.danceBtns.btn_dance5, art.danceBtns.btn_dance6, art.danceBtns.btn_dance7, art.danceBtns.btn_dance8, art.danceBtns.btn_dance9];
			var danceBtns:Sprite = art.danceBtns;
			for(var i:Number = 0; i<Dances.list.length; i++)
			{
				
				//danceBtns.getChildByName("btn_dance"+i).visible = !(danceBtns.getChildByName("btn_dance"+i+"_over").visible = i == danceIndex+1);
				var btn:SimpleButton = _danceButtons[i] as SimpleButton;
				
				if(i == danceIndex)
				{
					//overs[i].visible = true;
					if(btn) _onState(btn);
					
				}else
				{
					if(btn) _offState(btn);
					//overs[i].visible = false;
					//_danceButtons[i].visible = true;
				}
			}
		}
		protected function _onState(button:SimpleButton):void
		{
			
			var myColorTransform:ColorTransform = new ColorTransform();
			myColorTransform.color = 0xD31515;
			button.transform.colorTransform = myColorTransform;
			button.enabled = false;
			
		}
		protected function _offState(button:SimpleButton):void
		{		
			button.transform.colorTransform = new ColorTransform();
			button.enabled = true;			
		}
		protected var _danceButtons:Array;
		protected function _onDanceBtnClicked(e:MouseEvent):void
		{
			if(_danceButtons.indexOf(e.target) != danceIndex) App.asset_bucket.last_mid_saved = null;
			_danceIndex = _danceButtons.indexOf(e.target); 
			
			WSEventTracker.event("ce"+(5+danceIndex));
			_mainUI.enhanced_end.visible = _mainUI.enhanced_prompt.visible = false;
			loadDance();	
		}
		protected function _onHanBtnClicked(e:MouseEvent):void
		{
			App.ws_art.han_bg.visible = true;
		}
		protected function _onHousePartyBtnClicked(e:MouseEvent):void
		{
			if(_danceIndex == 12) return;
			_danceIndex = 12; 
			_updateDanceButtons();
			
			if(App.asset_bucket.enhancedPhotos.length > 0) _mainUI.enhanced_end.visible = true;
			else	_mainUI.enhanced_prompt.visible = true;
			
			  
			if(_currentDanceClip){
				_currentDanceClip.stop();
				_currentDanceClip.allheads.stop();
				SoundMixer.stopAll();
				_currentDanceClip.removeEventListener("swapHeads", _updateHeads);
				if(_hold.contains(_currentDanceClip)) _hold.removeChild(_currentDanceClip);
				//_currentDanceClip = null;
			}
			
		}
		
		protected function _onClearPhotosClicked(e:MouseEvent):void
		{	
			App.asset_bucket.enhancedPhotos = [];
			loadHouseParty();
		}
		protected function _onNewPhotosClicked(e:MouseEvent):void
		{	
			App.asset_bucket.enhancedPhotos = [];
			_mainUI.enhanced_end.visible = false;
			_mainUI.enhanced_prompt.visible = true;
		}
		protected function _onNoThanksClicked(e:MouseEvent):void
		{	
			loadHouseParty();
		}
		protected function _onLetsDanceClicked(e:MouseEvent):void
		{
			loadHouseParty();
		}
		public function loadHouseParty():void
		{
			_mainUI.enhanced_end.visible = false;
			_mainUI.enhanced_prompt.visible = false;
			//if(_danceIndex != 12) App.asset_bucket.last_mid_saved = null;
			_danceIndex = Dances.HOUSE_PARTY_DANCE_INDEX; 
			WSEventTracker.event("ce26"); //WSEventTracker.event("ce"+(5+danceIndex)); //ce17 is used for "Let's Dance" so hardcode this to be 26 --- matt
			
			loadDance();
		}
		protected function _onReplayClicked(e:MouseEvent):void
		{
			//WSEventTracker.event("gce2");
			if(_currentDanceClip) {
				if(_playback){
					_playback.replay();
				}
			}
			_mainUI.end_screen.visible = false;
			_bigShowUI.btn_play.visible= false;
		}
		protected function _onDanceClicked(e:MouseEvent):void
		{	
			loadDance();
		}
		
		private function _makeDefaultHeads():void
		{
			_defaultHeads = [];
			if(_currentDanceClip == null){
				return;
			}
			for(var i:Number = 1; i<6; i++){
				var h:MovieClip = _currentDanceClip.allheads.getChildByName("head"+String(i)) as MovieClip;
				if(h) 
				{
					var face:MovieClip = h.getChildByName("face") as MovieClip;					
					if(face)	var bmp:* = face.getChildAt(0);					
				}
				if(bmp) _makeDefaultHead(bmp);
			}
			//App.ws_art.addChild(dist);
			App.mediator.autophoto_set_persistant_images( _defaultHeads );
		}
		protected function _onEnterFrame(e:Event):void
		{
			 
			if(_currentDanceClip == null) return;
			if(_currentDanceClip) 	{
				if(App.asset_bucket.endGreeting)
				{
					_mainUI.end_greeting.tf.text = _bigShowUI.end_greeting.tf.text = App.asset_bucket.endGreeting;
					if(_currentDanceClip.currentFrame >= _currentDanceClip.totalFrames-72)
					{
						_mainUI.end_greeting.visible = _bigShowUI.end_greeting.visible = true;
						_repositionControlsForEndScreenGreeting();
					} else
					{
						_mainUI.end_greeting.visible = _bigShowUI.end_greeting.visible = false;
						_resetControlsPosition();
					}

				}
				for(var i:Number = 0; i<5; i++){
					var head:MovieClip = _currentDanceClip.getHeadByDepth(i);
					if(head) head.gotoAndStop(_currentDanceClip.allheads.currentFrame);
				}
				_updateHeads();
			}
			
			if (_currentDanceClip.currentFrame >= _currentDanceClip.totalFrames) {
				_onDanceComplete();
			}
			if(_danceIndex == Dances.HOUSE_PARTY_DANCE_INDEX) _updateBackgroundImages();
			//App.mediator.doTrace("xxxxx ===> " + _currentDanceClip.currentFrame +"  "+_currentDanceClip.allheads.currentFrame);
		}
		
		public function dance():void
		{
			// check to see if the dance is loaded
			_mainUI.end_screen.visible = false;
			if(!_checkIfLoaded()) return;
			if(_defaultHeads == null) _makeDefaultHeads();
			if(_mainUI.end_screen.visible){
				_mainUI.end_screen.visible = false;
				_mainUI.end_screen.alpha = 0;
			}
			
			_looping = false;
			_mainUI.visible 	= !_inBigShow;
			
			this.x = this.y = 0;
		
			_hold.addChild(_currentDanceClip);
			if(!_inBigShow) _updateHeads();
			
			_currentDanceClip.visible = true;
			_currentDanceClip.gotoAndPlay(2);
			_currentDanceClip.allheads.gotoAndPlay(2);

			if (_playback) _playback.destroy();
			_playback = new DancePlayback_ws(_videoControls, _currentDanceClip, false, null);  // for >>> preview
			_playback.play();			
		}
		public static const DANCES_LOADED:String = "dancesLoaded";
		protected function _checkIfLoaded():Boolean {
			var boo:Boolean = true;
			boo = App.asset_bucket.danceScenes[_danceIndex];
			//if(boo) boo = App.asset_bucket.idleScenes[_danceIndex];
			
			if(!boo){
				//App.mediator.addEventListener(App.mediator.EVENT_WORKSHOP_LOADED_DANCES, _onDancesLoaded);
				loadDance();
			}
			return boo;
		}
		private function loadDance():void{
			if(_currentDanceClip){
				_currentDanceClip.stop();
				_currentDanceClip.allheads.stop();
				SoundMixer.stopAll();
				_currentDanceClip.removeEventListener("swapHeads", _updateHeads);
				if(_hold.contains(_currentDanceClip)) _hold.removeChild(_currentDanceClip);
				_currentDanceClip = null;
			}
			
			App.mediator.checkBandwidth(checkBandwidth_FIN);
			

			function checkBandwidth_FIN(_bw:Number):void{
				if ( _bw > 400 ) {
					App.mediator.doTrace("preview_1 ===> " + _bw + ' kb/s');	
					//App.asset_bucket.elfVideoRes = "high";
				} else {
					App.mediator.doTrace("preview_2 ===> " + _bw + ' kb/s');	
					//App.asset_bucket.elfVideoRes = "low";
				}
				
				var transform:SoundTransform = new SoundTransform(0);
				SoundMixer.soundTransform = transform;	
				var headCount:Number = 0;
				var head:HeadStruct;
				for(var i:Number = 0; i<App.mediator.savedHeads.length; i++){
					if(App.mediator.savedHeads[i] != null){						
						head = App.mediator.savedHeads[i];
						swapHead(head.image, headCount, head.mouthCutPoint);
						headCount++;
					}
				}
				//preview
				var dances:Array = Dances.list;//["Breakin","Feliz_Navidad","Office_Party","Elfspanol","EDM","Charleston","Disco","Singing","Honky_Tonk","80s","Hip_Hop"];//,"Classic","Soul"
				var swfURL:String;
				if (App.asset_bucket.elfVideoRes == "high") {
					swfURL = ServerInfo.content_url_door + "misc/" + dances[_danceIndex] + "_" + headCount + "h.swf";
					displayFinalVideo("mainPlayer", false);
				}else {
					swfURL = ServerInfo.content_url_door + "misc/" + dances[_danceIndex] + "_" + headCount + ".swf";
					displayFinalVideo("mainPlayer", false);
				}
				Gateway.retrieve_Loader( new Gateway_Request(swfURL, new Callback_Struct( fin ) ) );
				App.mediator.processing_start(DANCES_LOADED, null, -1, -1, true);
				_updateDanceButtons();
			}
			function fin(l:Loader):void{
				(l.content as MovieClip).stop();
				SoundMixer.stopAll();
				App.asset_bucket.danceScenes[_danceIndex] = (l.content as MovieClip);
				_currentDanceClip = (l.content as MovieClip);
				
				_currentDanceClip.addEventListener("swapHeads", _updateHeads);
				
				App.mediator.processing_ended(DANCES_LOADED);
				if(_defaultHeads == null) _makeDefaultHeads();
				
				var transform:SoundTransform = new SoundTransform(1);
				SoundMixer.soundTransform = transform;	
				dance();	
				
			}
		}
		
		
		protected function _onDanceComplete(e:Event = null):void
		{
			SoundMixer.stopAll();
			
			if (_inBigShow) {
				_currentDanceClip.gotoAndStop(2);
				_currentDanceClip.allheads.gotoAndStop(2);
				_playback.pause();
				_playback.forceShowControls();
				_bigShowUI.btn_play.visible = true;
				if (App.ws_art.stage.displayState == StageDisplayState.FULL_SCREEN){
					App.ws_art.stage.displayState = StageDisplayState.NORMAL;
				}
				_isBigshowFirsttime = false;
				_resetControlsPosition();
				displayFinalVideo("bigShow", false);
				WSEventTracker.event('ae');
			}else{
				TweenLite.to(_mainUI.end_screen, .4, {alpha:1, visible:true});
				_currentDanceClip.gotoAndStop(2);
				_currentDanceClip.allheads.gotoAndStop(2);
				_playback.pause();
				if (App.ws_art.stage.displayState == StageDisplayState.FULL_SCREEN){
					App.ws_art.stage.displayState = StageDisplayState.NORMAL;
				}
				displayFinalVideo("mainPlayer", false);
			}
		}
		protected function _updateHeads(e:Event = null):void
		{
			var dup:Number = 0;
			for( var i:Number = 0; i< 5; i++)
			{	
				var head:* = heads[i];
				var mouth:* = _mouths[i];
				if(head == null) {
					if(_danceIndex != 0){
						if(dup > heads.length-1) dup = 0;
						head = heads[dup];
						mouth = _mouths[dup];
						dup++;
					}
				}
				if(head != null) swapHead(head, i, mouth);
			}
			
		}
		public function swapHead( bmp:Bitmap, index:Number, mouth:* = null):void
		{
			_heads[index] 		= bmp;			
			//var mouthBmp:Bitmap = mouth is Bitmap ? mouth : _makeMouth(bmp, mouth);
			_mouths[index] 		=  mouth;
			//mouthBmp = new Bitmap(mouthBmp.bitmapData, "auto", true);
			if(_currentDanceClip == null) return;
			if(_defaultHeads == null) _makeDefaultHeads();
			if(bmp.bitmapData) bmp = new Bitmap(bmp.bitmapData, "auto", true);
			var headSize	:Rectangle 	= RatioUtil.scaleToFill( new Rectangle(0,0,bmp.width, bmp.height), _placementRects[index]);
				
			//if(_danceIndex == DANCE_INDEX_WITH_MOUTH) bmp = _makeNoMouthFace(bmp, bmp.height - mouthBmp.height);
			var mouthPerc:Number = mouth/bmp.height; 
			//set size
			bmp.width 				= headSize.width;
			bmp.scaleY 				= bmp.scaleX;
					
			var headMC:MovieClip 	= _currentDanceClip.allheads.getChildByName("head"+(index+1)) as MovieClip;
			if(_currentDanceClip.getHeadByDepth is Function) 
				headMC 	= _currentDanceClip.getHeadByDepth(index);
				
			if(headMC && headMC.numChildren > 0)
			{
				var mouthMC	:MovieClip = headMC.getChildByName("mouth") as MovieClip;
				var faceMC	:MovieClip = headMC.getChildByName("face") as MovieClip;
				
				if(_danceIndex == DANCE_INDEX_WITH_MOUTH)
				{
							
					var targY:Number = (mouth*bmp.scaleY);//-(52);//(mouthPerc*headSize.height)-43;
					//if(mouthMC) mouthMC.y = targY;
					setY("ahh");
					setY("eee");
					setY("mmm");
					setY("ooo");
					setY("rrr");
					setY("sss");
//					for(var i:Number =0; i<headMC.numChildren; i++){
//						trace("Child: "+headMC.getChildAt(i).name);
//					}
					function setY(id:String):void{
						var clip:MovieClip = headMC.getChildByName("mouth_"+id) as MovieClip;
						if(clip) 
						{
							
							//trace(headMC.name+" - "+clip.name+" alpha: "+clip.alpha);
							//clip.y = 32.2;
							var inner:DisplayObject = clip.getChildAt(0);
							inner.y = ((targY - 32.2 )*2)- 110;
							
						}
						
					}
					
				}
				
				if(faceMC)
				{
					if(faceMC.numChildren > 0) faceMC.removeChildAt( 0 );
					faceMC.addChild( bmp );
				}
			}
					
		}
		protected function _updateBackgroundImages():void
		{
			var uploads:Array = App.asset_bucket.enhancedPhotos;
			if(!uploads.length) return;
			
			for(var i:Number = 0; i < uploads.length; i++)
			{
				var uploaded:EnhancedPhoto = uploads[i] as EnhancedPhoto;
				if(uploaded.bitmap)
				{
					var image:MovieClip;
					var allHeads:MovieClip = (_currentDanceClip.getChildByName("allheads") as MovieClip)
					if(allHeads) image = allHeads.getChildByName("image"+(i+1)) as MovieClip;
					if(image)
					{	
						uploaded.bitmap.width = uploaded.bitmap.height = 205;
						if(image.numChildren > 0) image.removeChildAt(0);
						image.addChild(uploaded.bitmap);
						image.cacheAsBitmap = true;
					}
				}
			}
		}
		protected var _videoControls:VideoControls_UI;
		
	
		public function load_and_play_message( _mid:String, _edit_state_starter_callback:Function ):void
		{
			_inBigShow = true;
			if(!_hasBeenInit) _init();
			
			_gotoEditStateCallback = _edit_state_starter_callback;
			//x = 23;
			//y = 137;
			_videoControls = _bigShowUI.video_controls;
			_bigShowUI.player_hold.addChild(this);
			
			App.ws_art.upload_btns.visible 	= false;
			//App.ws_art.dance_Btn.visible 	= false;
			_bigShowUI.btn_create_your_own.visible 	= false;
			_bigShowUI.btn_create_your_own.addEventListener(MouseEvent.CLICK, _onCreateYourOwnClicked);
			_bigShowUI.btn_elfYourselfLogo.addEventListener(MouseEvent.CLICK, _onElfYourselfLogoClicked);
//			_bigShowUI.btn_elfYourselfLogo.buttonMode = true;
			_mainUI.visible 	= false;
			
			
			/*this._hold.addEventListener(MouseEvent.CLICK, _onHoldClicked);
			this._hold.buttonMode = true;*/

			var doc_query	:String = ServerInfo.acceleratedURL + 'php/api/playScene/doorId=' + ServerInfo.door + '/clientId=' + ServerInfo.client + '/mId=' + _mid;
			Gateway.retrieve_XML( doc_query, new Callback_Struct( fin, null, error ) );
			
			function fin( _xml:XML ):void {	
				if (_xml == null || _xml.name() == null) {
					error(null);
					return; 
				}else if (_xml.name().toString() == "APIERROR") {	
					var errorMsg:String = unescape(_xml.@ERRORSTR);
					error(errorMsg);
					return;		
				}
				mid_message = new WorkshopMessage( parseInt(_mid) );
				mid_message.parseXML( _xml);
				
				var is_for_demo:Boolean = (loaderInfo.parameters.demo != null && loaderInfo.parameters.demo == "1")?(true):(false);
				var is_from_android:Boolean = (mid_message.extraData.android != null && mid_message.extraData.android == "1")?(true):(false);
				if(mid_message.extraData.endGreeting)
				{
					App.asset_bucket.endGreeting = (mid_message.extraData.endGreeting).split("|").join("&");
				}
				is_for_demo = true;
				if (is_for_demo) {
					App.asset_bucket.campaign_is_expired = false;
				}else {
					App.asset_bucket.campaign_is_expired = (is_from_android==true)?(false):(true);
				}
				if (App.asset_bucket.campaign_is_expired) {
					_onCreateYourOwnClicked(null);
					return;
				}
				
				
				
				_danceIndex = parseFloat(mid_message.extraData.danceIndex) || 0;
				App.asset_bucket.mid_message = mid_message;
				
				_headsToBeLoaded = [];
				_headsToBeLoadedNum = 0;
				_enhancedToBeLoaded = [];
				//App.mediator.processing_start(LOADING_HEADS);
				
				for(var i:Number = 0; i<mid_message.sceneArr.length; i++){
					var scene:SceneStruct = mid_message.sceneArr[i];
					var image:WSBackgroundStruct = mid_message.sceneArr[i].bg as WSBackgroundStruct;
					var index:Number;
					if(image && image.url ) {
						if(image.name.indexOf("enhanced")>-1){
							// this is an enhanced photo
							var enhanced:EnhancedPhoto = new EnhancedPhoto(null, image.url);
							enhanced.addEventListener(Event.COMPLETE, _onEnhancedLoaded);
							index = parseFloat(image.name.split("enhanced_").join(""));
							App.asset_bucket.enhancedPhotos.push(enhanced);
							_enhancedToBeLoaded[index] = (enhanced);

						}else{
							var nameSansHead:String = image.name.split("head_").join("");
							index = parseFloat(nameSansHead);
							var cutPoint:Number = parseFloat(mid_message.extraData['mouthCutPoint_'+index]);
							var head:Head = new Head(image.url,index, cutPoint);
							head.addEventListener(Event.COMPLETE, _onHeadLoaded);
							_headsToBeLoaded.push( head );
							_headsToBeLoadedNum++;	
						}
						
					}
				}
				_onPrerollLoading();
			}	

			function error( _msg:String ):void {
				App.mediator.alert_user(new AlertEvent(AlertEvent.ERROR, "", "Invalid message ID", null, error2));
				App.mediator.workshop_finished_loading_playback_state();
			}
			function error2():void {
				_onCreateYourOwnClicked(null);
			}
		}
		private var _prerollSwf:MovieClip;
		
		private function _onPrerollLoading():void {
			App.mediator.checkBandwidth(checkBandwidth_FIN);
			
			
			function checkBandwidth_FIN(_bw:Number):void {
				if ( _bw > 250 ) {
					App.mediator.doTrace("bigshow_1 ===> " + _bw + ' kb/s');	
					App.asset_bucket.elfVideoRes = "high";
				} else {
					App.mediator.doTrace("bigshow_2 ===> " + _bw + ' kb/s');	
					App.asset_bucket.elfVideoRes = "low";
				}
				var swfURL:String;
				if (App.asset_bucket.elfVideoRes == "high") {
					swfURL = ServerInfo.content_url_door + "misc/preroll_h.swf";
				}else {
					swfURL = ServerInfo.content_url_door + "misc/preroll.swf";
				}
				Gateway.retrieve_Loader( new Gateway_Request(swfURL, new Callback_Struct( _onPrerollLoaded ) ) );
			}
		}
		private function _onPrerollLoaded(l:Loader):void{
			_prerollSwf = (l).content as MovieClip;
			_prerollSwf.stop();
			
			//bigshow
			//var dances:Array = ["Office_Party", "Elfspanol", "EDM", "Honky_Tonk", "Classic", "Soul", "Hip_Hop", "80s", "Charleston"];
			//var dances:Array = ["Breakin","Feliz_Navidad","Office_Party","Elfspanol","EDM","Charleston","Disco","Singing","Honky_Tonk","80s","Hip_Hop"];//,"Classic","Soul"
			var dances:Array = Dances.list;
			var swfURL:String;
			if (App.asset_bucket.elfVideoRes == "high") {
				swfURL = ServerInfo.content_url_door + "misc/" + dances[_danceIndex] + "_" + _headsToBeLoadedNum + "h.swf";
				_isBigshowFirsttime = true;
				displayFinalVideo("bigShow", true);
			}else {
				swfURL = ServerInfo.content_url_door + "misc/" + dances[_danceIndex] + "_" + _headsToBeLoadedNum + ".swf";
				_isBigshowFirsttime = true;
				displayFinalVideo("bigShow", true);
			}

			Gateway.retrieve_Loader( new Gateway_Request(swfURL, new Callback_Struct( _onBigDanceLoaded ) ) );
		}
		private function _onHoldClicked(e:MouseEvent):void
		{
			if(_inBigShow && !_looping)
			{
				_mainUI.btn_replay.visible 	= true;
				if (_currentDanceClip) {
					_currentDanceClip.gotoAndStop(1);
					_currentDanceClip.allheads.gotoAndStop(1);
				}
				SoundMixer.stopAll();
			}
		}
		private function _onBigDanceLoaded( l:Loader ):void
		{
			WSEventTracker.event("ev");
			WSEventTracker.event("pb", String(mid_message.mid));
		
			_currentDanceClip = (l).content as MovieClip;
			_currentDanceClip.gotoAndStop(1);
			_currentDanceClip.allheads.gotoAndStop(1);
			_currentDanceClip.addEventListener("swapHeads", _updateHeads);
			_makeDefaultHeads();
			

			if(_headsToBeLoaded.length == 0) _startPreroll();
			
		}
		public function _startPreroll():void
		{
			if(_headsToBeLoaded.length < 1 && _currentDanceClip)
			{
				_bigShowUI.visible = true;
				App.mediator.workshop_finished_loading_playback_state();
				_looping = false;
				_bigShowUI.video_controls.visible = false;
				_hold.addChild(_prerollSwf);
				_prerollSwf.visible = true;
				_prerollSwf.gotoAndPlay(2);
				_prerollSwf.addEventListener(Event.ENTER_FRAME, _onPrerollEventFrame);
				_bigShowUI.btn_create_your_own.visible 	= false;
			}
		}
		public function stop():void
		{
			App.ws_art.stop_btn.visible 	= false;
			
			SoundMixer.stopAll();
			if (_currentDanceClip) {
				_currentDanceClip.gotoAndStop(1);
				_currentDanceClip.allheads.gotoAndStop(1);
			}
		}
		
		public function _startBigShow():void{
			if (_headsToBeLoaded.length < 1 && _currentDanceClip) {	
				_playback = new DancePlayback_ws(_videoControls, _currentDanceClip, _isBigshowFirsttime, _replayCallback); // for >>> bigshow
				//_isBigshowFirsttime = false;
				
				_hold.addChild(_currentDanceClip);
				
				_currentDanceClip.visible = true;
				_currentDanceClip.gotoAndPlay(2);
				_currentDanceClip.allheads.gotoAndPlay(2);
				//dumb but he sometimes puts stop in there;
				_playback.play();
				_bigShowUI.btn_create_your_own.visible 	= true;
			}
		}
		protected function _onPrerollEventFrame(e:Event):void
		{
			if(_prerollSwf.currentFrame >= _prerollSwf.totalFrames){
				_prerollSwf.removeEventListener(Event.ENTER_FRAME, _onPrerollEventFrame);
				
				_prerollSwf.stop();
				_startBigShow()
			}
		}
		protected function _onElfYourselfLogoClicked(e:MouseEvent):void {
			var OFFICE_MAX_LINK:String = App.mediator.LOGO_LINK;//"http://www.officedepot.com/a/content/holiday/elf-yourself/";
			URL_Opener.open_url( OFFICE_MAX_LINK, "_blank");
		}
		
		protected function _onCreateYourOwnClicked(e:MouseEvent):void
		{
			//WSEventTracker.event("gce3");
			
			_inBigShow = false;
			_mainUI.visible = false;
			_bigShowUI.visible = false;
			App.asset_bucket.danceScenes = [];
			_heads = [];
			
			App.asset_bucket.mid_message =  null;
			App.asset_bucket.last_mid_saved = null;
			App.asset_bucket.enhancedPhotos = [];
			App.asset_bucket.endGreeting = null;
			
			if (_currentDanceClip) {
				_currentDanceClip.gotoAndStop(2);
				_currentDanceClip.allheads.gotoAndStop(2);
			}
			if(_playback) _playback.destroy();
			
			_gotoEditStateCallback();
			
			this._hold.buttonMode = false;
			this._hold.removeEventListener(MouseEvent.CLICK, _onHoldClicked);
		}
		protected function _onHeadLoaded(e:Event):void
		{
			var head:Head = e.target as Head;
			ArrayUtil.removeItem(_headsToBeLoaded, head);
			swapHead( head.bitmap, head.index, head.mouthCutPoint );
			
			if(_headsToBeLoaded.length == 0 && _currentDanceClip != null && _enhancedToBeLoaded.length == 0) {	
				_startPreroll();
			}
			
			head.destroy();
		}
		protected function _onEnhancedLoaded(e:Event):void
		{
			
			_enhancedToBeLoaded.splice(_enhancedToBeLoaded.indexOf(e.currentTarget), 1);
			
			if(_headsToBeLoaded.length == 0 && _currentDanceClip != null && _enhancedToBeLoaded.length == 0) {	
				_startPreroll();
			}
		}
		protected function _makeMouth(face:Bitmap, mouthCutPoint:Number):Bitmap
		{
			var data:BitmapData = new BitmapData(face.width, face.height-mouthCutPoint, true, 0x0000000);
			var mat:Matrix = new Matrix();
			
			var rect:Rectangle = new Rectangle(0,mouthCutPoint,face.width,face.height-mouthCutPoint);
			mat.translate( -rect.x, -rect.y);
			
			data.draw(face, mat);
			
			return new Bitmap(data, "auto", true);
		}
		
		protected function _makeNoMouthFace(face:Bitmap, mouthCutPoint:Number):Bitmap
		{
			var data:BitmapData = new BitmapData(face.width, mouthCutPoint, true, 0x0000000);
			var mat:Matrix = new Matrix();
			data.draw(face);//, mat);
			return new Bitmap(data, "auto", true);
		}
		/**
		 * 
		 * @param e
		 * 
		 */
		public function set danceIndex(value:Number):void
		{
			_danceIndex = value;
			
			//might need error checking or something here
			if(App.asset_bucket.danceScenes[value]) _currentDanceClip = App.asset_bucket.danceScenes[value];
			if(App.asset_bucket.idleScenes[value]) 	_idle = App.asset_bucket.idleScenes[value];
			
			_updateHeads();
		}
		public function get heads():Array
		{
			return _heads;
		}

		public function set heads(value:Array):void
		{
			_heads = value;
		}

		public function get danceIndex():Number
		{
			return _danceIndex;
		}

		protected var _defaultHeads:Array;
		protected var _danceDefaultHeads:Array;
		protected var _placementRects:Array = [];
		
		private function _makeDefaultHead( obj:DisplayObject ):Bitmap
		{
			_placementRects.push(new Rectangle( obj.x, obj.y, obj.width, obj.height ));
			var data	:BitmapData = new BitmapData(obj.width, obj.height, true, 0x0000000);
			var mat		:Matrix = new Matrix();
			var rect	:Rectangle = (obj).getBounds( obj.parent );
			mat.translate( -rect.x, -rect.y);
			data.draw(obj, mat);
			var bmp:Bitmap =  new Bitmap( data, "auto", true );
			_defaultHeads.push(bmp);
			return bmp;
		}
		//**************************************************************************************************
		public function _replayCallback():void {
			if(_playback) _playback.destroy();
			_startPreroll();
		}
		protected function _repositionControlsForEndScreenGreeting():void
		{	
			var cur_ui:MovieClip = _inBigShow? _bigShowUI : _mainUI;
				
			if (App.ws_art.stage.displayState == StageDisplayState.FULL_SCREEN ||  _isBigshowFirsttime) {
				cur_ui.video_controls.y = CONTROLS_Y_LS-114;
			}else{
				cur_ui.video_controls.y = _inBigShow ? CONTROLS_Y_BIG_SHOW-60 : CONTROLS_Y-50;
			}
			
		}
		private static var CONTROLS_X			:Number = 33;
		private static var CONTROLS_X_BIG_SHOW	:Number = 161;
		private static var CONTROLS_Y_LS		:Number = 22;
		private static var CONTROLS_X_LS		:Number = 18;
		private static var CONTROLS_Y			:Number = 103;		
		private static var CONTROLS_Y_BIG_SHOW	:Number = 85;
	
		private static var PLAYER_Y				:Number = 102;
		private static var PLAYER_Y_BIG_SHOW	:Number = 81;
		private static var PLAYER_Y_LS			:Number = 33;
		private static var PLAYER_X				:Number = 34;
		private static var PLAYER_X_BIG_SHOW	:Number = 159;
		
		
		protected function _resetControlsPosition():void
		{
			var cur_ui:MovieClip = _inBigShow ? _bigShowUI : _mainUI;
			
			if (App.ws_art.stage.displayState == StageDisplayState.FULL_SCREEN ||  _isBigshowFirsttime) {
				cur_ui.video_controls.y = CONTROLS_Y_LS;
			}else{
				cur_ui.video_controls.y = _inBigShow ? CONTROLS_Y_BIG_SHOW : CONTROLS_Y;
			}
			
			
			//hacky
			//if(_inBigShow && _bigShowUI.player_hold.scaleX > 
		}
		//**********************************************
		public function displayFinalVideo(_which_ui:String, isLargeSize:Boolean = false):void { //"bigshow","mainPlayer"
			var cur_ui:MovieClip = _inBigShow?(_bigShowUI):(_mainUI);
			//if(!_largeSize) _isBigshowFirsttime = false;
			App.mediator.doTrace("displayFinalVideo===> " + isLargeSize+"  "+_isBigshowFirsttime + "  " + App.asset_bucket.elfVideoRes);
			
			if (isLargeSize) 
			{
				cur_ui.video_controls.x = CONTROLS_X_LS; 
				cur_ui.video_controls.y = CONTROLS_Y_LS;
				cur_ui.player_hold.x = cur_ui.player_hold.y =0;
				
				cur_ui.end_greeting.y = _isBigshowFirsttime ? App.ws_art.stage.stageHeight-121 : App.ws_art.stage.stageHeight-117;
				cur_ui.end_greeting.scaleX = cur_ui.end_greeting.scaleY = _isBigshowFirsttime ? 1.8 : 1.844;
				cur_ui.end_greeting.x = _isBigshowFirsttime ? 10 : 0; 
				
				cur_ui.player_hold.mask = cur_ui.videoMaskBig;
				
				cur_ui.video_controls.visible = false;
				
				cur_ui.player_hold.scaleX =cur_ui.player_hold.scaleY = App.asset_bucket.elfVideoRes=="high" ? 0.977 : 1.954;				
			}else 
			{
				cur_ui.video_controls.x = _inBigShow ? CONTROLS_X_BIG_SHOW : CONTROLS_X;//222;
				cur_ui.video_controls.y = _inBigShow  ? CONTROLS_Y_BIG_SHOW : CONTROLS_Y;//155;		
				
				cur_ui.player_hold.x = _inBigShow ? PLAYER_X_BIG_SHOW : PLAYER_X;
				cur_ui.player_hold.y = _inBigShow ? PLAYER_Y_BIG_SHOW : PLAYER_Y;
				cur_ui.player_hold.scaleX = cur_ui.player_hold.scaleY = App.asset_bucket.elfVideoRes=="high" ? 0.555 : 1.3; 
				
				cur_ui.player_hold.mask = cur_ui.videoMask;
				
				cur_ui.end_greeting.x = _inBigShow ? 162 : 33.1;
				cur_ui.end_greeting.y = _inBigShow ? 391 : 409.55;
				cur_ui.end_greeting.scaleX = cur_ui.end_greeting.scaleY = 1;				
			}
						
			cur_ui.video_controls.scaleX = cur_ui.video_controls.scaleY = isLargeSize ? 1.425 :1;			 
			
			cur_ui.videoBorder.visible = cur_ui.videoMask.visible = cur_ui.bgMore.visible = !isLargeSize; 
			cur_ui.videoBorderBig.visible =  _isBigshowFirsttime ? isLargeSize : false;
			cur_ui.videoMaskBig.visible = isLargeSize;
			
			_toggleUI(!isLargeSize);	
		}
		
		private function _toggleUI(visible:Boolean = true):void
		{
			_bigShowUI.btn_elfYourselfLogo.visible =
			_bigShowUI.btn_create_your_own.visible = 
			_mainUI.btn_elfYourselfLogo.visible = 
			_mainUI.btn_deals.visible = 
			_mainUI.danceBtns.visible = 
			_mainUI.btn_merch.visible = 
			_mainUI.btn_details.visible =
			_mainUI.btn_storedownload.visible =
			_mainUI.shareBtns.visible = 
			_mainUI.btn_create_another.visible = visible;
			
		}
		//**************************************************************************************************
		
		
		
		
		
		
	}
}
import com.oddcast.utils.gateway.Gateway;
import com.oddcast.workshop.Callback_Struct;

import flash.display.Bitmap;
import flash.display.Loader;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.ProgressEvent;

import org.casalib.events.RemovableEventDispatcher;

class Head extends RemovableEventDispatcher
{
	public function Head( _url:String, _index:Number, _mouthCutPoint:Number):void
	{
		index = _index;
		mouthCutPoint = _mouthCutPoint;
		//_callback = callback;
		init(_url);
	}
	protected function init(url:String):void
	{
		Gateway.retrieve_Bitmap( url, new Callback_Struct(_imageLoaded));
	}
	private var _callback:Function;
	private function onLoadProgress(evt:ProgressEvent):void
	{
		trace("onLoadProgress - " + evt.bytesLoaded);
		var percent:Number = (evt.bytesTotal == 0)?0:(evt.bytesLoaded / evt.bytesTotal);
		//	dispatchEvent(new ProcessingEvent(ProcessingEvent.PROGRESS, ProcessingEvent.BG, percent));
	}
	protected function onError(evt:ErrorEvent):void {
		///	dispatchEvent(new ProcessingEvent(ProcessingEvent.DONE, ProcessingEvent.BG));
		//	dispatchEvent(new AlertEvent(AlertEvent.ERROR, "f9tp311", "Could not load BG : "+evt.text));
	}
	protected function _imageLoaded(bmp:Bitmap):void
	{
		bitmap = new Bitmap(bmp.bitmapData, "auto", true);
		//_callback(bitmap, index);
		//bitmap = new Bitmap(((evt.target as LoaderInfo).content as Bitmap).bitmapData, "auto", true);
		dispatchEvent(new Event(Event.COMPLETE));
		
	}
	public var mouthCutPoint:Number;
	private var _imgLoader:Loader;
	public var bitmap:Bitmap;
	public var index:Number;
}