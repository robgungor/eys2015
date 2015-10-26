package custom
{
	import code.skeleton.App;
	
	import com.adobe.images.PNGEncoder;
	import com.oddcast.event.AlertEvent;
	import com.oddcast.event.SendEvent;
	import com.oddcast.utils.URL_Opener;
	import com.oddcast.utils.gateway.Gateway;
	import com.oddcast.utils.gateway.Gateway_Request;
	import com.oddcast.workshop.Callback_Struct;
	import com.oddcast.workshop.ServerInfo;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import org.casalib.events.RemovableEventDispatcher;
	import org.casalib.util.RatioUtil;
	
	public class DanceScreenShot extends RemovableEventDispatcher
	{
		private const PROCESS_UPLOADING			:String = 'PROCESS_UPLOADING dance screen shot';
		protected var _swf				:MovieClip;
		protected var _bitmap			:Bitmap;
		protected var _printTempURL		:String;
		protected var _pinTempURL		:String;
		protected var _heads			:Array;
		protected var _mouths			:Array;
		protected var _defaultHeads		:Array;
		protected var _placementRects	:Array;
		protected var _action			:String; //"doPrint","doPinterest"
		
		public function DanceScreenShot(heads:Array, mouths:Array, action:String)
		{
			super();
			_heads = heads;
			_mouths = mouths;
			_action = action;
			_init();
		}
		protected function _init():void{
			App.ws_art.printProcessing.visible = (_action=="doPrint")?true:false;
			App.ws_art.pinProcessing.visible = (_action=="doPinterest")?true:false;
			App.mediator.processing_start( PROCESS_UPLOADING);
			_saveMessage();
		}
		protected function _saveMessage():void {
			if (App.asset_bucket.last_mid_saved == null) {
				App.utils.mid_saver.save_message(new SendEvent(SendEvent.SEND, SendEvent.DOWNLOAD_VIDEO), new Callback_Struct( fin, null, null ) );
			}else {
				fin(); 
			}
			
			function fin():void {	
				_loadSwf();
			}	
		}
		protected function _loadSwf():void{	
			//var dances:Array = ["Office_Party","Elfspanol","EDM","Honky_Tonk","Classic","Soul","Hip_Hop","80s","Charleston"];;
			var dances:Array = Dances.list;
			var headCount:Number = 0;
			for(var i:Number = 0; i<App.mediator.savedHeads.length; i++){	
				if(App.mediator.savedHeads[i] != null) headCount++;
			}
			var url:String = ServerInfo.content_url_door + "misc/"+dances[App.mediator.danceIndex]+"_"+headCount+"_screenshot.swf";
			Gateway.retrieve_Loader( new Gateway_Request(url, new Callback_Struct( _onSwfLoaded ) ) );
		}
		protected function _onSwfLoaded(l:Loader):void{
			_swf = (l).content as MovieClip;
			_makePlacementRects();
			_updateHeads();
			_takeScreenShot();
		}
		protected function _updateHeads(e:Event = null):void{
			var dup:Number = 0;
			for( var i:Number = 0; i< 5; i++)
			{	
				var head:* = _heads[i];
				if(head == null && App.mediator.danceIndex == 4) 
				{
					if(dup > _heads.length-1) dup = 0;
					head = _heads[dup];
					dup++;
				}
				if(head != null) swapHead(head, i, _mouths[i]);
			}			
		}
		public function swapHead( bmp:Bitmap, index:Number, mouth:* = null):void
		{
//			var mouthBmp:Bitmap;
//			
//			if(mouth is Number)
//			{
//				mouth = _makeMouth(bmp, mouth);
//			}
//			if( mouth is Bitmap ) mouthBmp = mouth;
//			mouthBmp = new Bitmap(mouthBmp.bitmapData, "auto", true);
			
			var head:MovieClip = _swf.getChildByName("head"+(index+1)) as MovieClip
			var headSize	:Rectangle 	= RatioUtil.scaleToFill( new Rectangle(0,0,bmp.width, bmp.height), _placementRects[index]);
			
			
			if(bmp is Bitmap) bmp = new Bitmap((bmp as Bitmap).bitmapData.clone(), "auto", true);
				
			//if(App.mediator.danceIndex == 4) bmp = _makeNoMouthFace(bmp, bmp.height - mouthBmp.height);
			
			//set size
			bmp.width 			= headSize.width;
			bmp.scaleY 			= bmp.scaleX;
	
			//if(_currentDanceClip.getHeadByDepth is Function) head = _currentDanceClip.getHeadByDepth(index);
				
			//_currentDanceClip.getChildAt(faceOrder[index]) as MovieClip;
			if(head && head.numChildren > 0)
			{
				var mouthMC	:MovieClip = head.getChildByName("mouth") as MovieClip;
				var faceMC	:MovieClip = head.getChildByName("face") as MovieClip;
				
				if(App.mediator.danceIndex == 4)
				{
//					mouthBmp.scaleX = bmp.scaleX;
//					mouthBmp.scaleY = bmp.scaleY;
//					mouthBmp.y 		= (bmp.height+bmp.y);				
//					
//					if(mouthMC)
//					{
//						mouthMC.removeChildAt( 0 );
//						mouthMC.addChild( mouthBmp );
//					}
					
					head.addChildAt(faceMC, 1); 
				}
				
				if(faceMC)
				{
					faceMC.removeChildAt( 0 );
					faceMC.addChild( bmp );
				}
			}
			
		}
		private function _makePlacementRects():void
		{
			_placementRects = [];
			for(var i:Number = 1; i<6; i++)
			{
				var h:MovieClip = _swf.getChildByName("head"+String(i)) as MovieClip;
				var bmp:* = (h.getChildByName("face") as MovieClip).getChildAt(0);
				if(bmp) _makePlacementRect(bmp);
			} 	
		}
		private function _makePlacementRect( obj:DisplayObject ):void
		{
			_placementRects.push(new Rectangle( obj.x, obj.y, obj.width, obj.height ));
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
		
		protected function _makeNoMouthFace(face:Bitmap, mouthCutPoint:Number):Bitmap{
			var data:BitmapData = new BitmapData(face.width, mouthCutPoint, true, 0x0000000);
			var mat:Matrix = new Matrix();
			data.draw(face);//, mat);
			return new Bitmap(data, "auto", true);
		}
		protected function _takeScreenShot():void
		{
			_bitmap = new Bitmap();
			_bitmap.bitmapData = new BitmapData(_swf.width, _swf.height, true);
			_bitmap.bitmapData.draw(_swf);
			if (_action == "doPrint") {
				_uploadImage_print();
			}else if (_action == "doPinterest") {	
				_uploadImage_pinterest();
			}
		}
		protected function _uploadImage_print():void {
			var img_data:ByteArray = PNGEncoder.encode( _bitmap.bitmapData );
			App.utils.image_uploader.upload_binary( new Callback_Struct( fin, null, error ), img_data, "png", serverCapacity_error);
			
			
			function fin(bg:*):void{
				App.mediator.processing_ended( PROCESS_UPLOADING);
				
				_printTempURL = bg.url;
				App.ws_art.printProcessing.visible 	= false;
				App.ws_art.printReady.visible 		= true;
				App.ws_art.printReady.btn_ok.addEventListener(MouseEvent.CLICK, onOkClicked);
				App.ws_art.printReady.btn_close.addEventListener(MouseEvent.CLICK, onCloseClicked);
			}
			function error(e:*):void {
				App.mediator.processing_ended( PROCESS_UPLOADING);	
				App.mediator.alert_user(new AlertEvent(AlertEvent.ERROR, 'f9t201', 'Error saving image.'));
			}
			function serverCapacity_error():void {
				App.mediator.doTrace("serverCapacity_error===> xxxxxx");
				App.mediator.processing_ended( PROCESS_UPLOADING);	
			}
		}
		protected function _uploadImage_pinterest():void {
			add_listeners();
			App.asset_bucket.video_downloader.captureScreen(_bitmap.bitmapData);
			
			App.listener_manager.add(App.asset_bucket.video_downloader, SendEvent.DONE, fin , this );
			App.listener_manager.add(App.asset_bucket.video_downloader, AlertEvent.EVENT, error , this );
				function add_listeners(  ):void {	
					App.listener_manager.add(App.asset_bucket.video_downloader, SendEvent.DONE, fin , this );
					App.listener_manager.add(App.asset_bucket.video_downloader, AlertEvent.EVENT, error , this );
				}
				function remove_listeners(  ):void {	
					App.listener_manager.remove(App.asset_bucket.video_downloader, SendEvent.DONE, fin );
					App.listener_manager.remove(App.asset_bucket.video_downloader, AlertEvent.EVENT, error );
				}
			
			function fin( _e:SendEvent ):void {	
				remove_listeners();
				App.mediator.processing_ended( PROCESS_UPLOADING);
				
				_pinTempURL = App.asset_bucket.video_downloader.capturedSceneUrl;
				App.ws_art.pinProcessing.visible 	= false;
				App.ws_art.pinReady.visible 		= true;
				App.ws_art.pinReady.btn_ok.addEventListener(MouseEvent.CLICK, onOkClicked);
				App.ws_art.pinReady.btn_close.addEventListener(MouseEvent.CLICK, onCloseClicked);
			}
			function error( _e:AlertEvent ):void {	
				remove_listeners();
				App.mediator.processing_ended( PROCESS_UPLOADING);
				
				App.mediator.alert_user(new AlertEvent(AlertEvent.ERROR, 'f9t201', 'Error saving image.'));
			}
		}

		
		
		
		protected function onCloseClicked(e:MouseEvent):void{
			destroy();
		}
		protected function onOkClicked(e:MouseEvent):void {
			//var url:String;	
			if (_action == "doPrint") {	
				var url:String = ServerInfo.localURL + "api_misc/1177/getCode.php?mId=" + App.asset_bucket.last_mid_saved + "&url=" + _printTempURL;
				URL_Opener.open_url( url, "_blank");
			}else if (_action == "doPinterest") {	
				var _url:String = ServerInfo.pickup_url + '?mId=0.3';
				ExternalInterface.call("pinit", _url, _pinTempURL, "");
			}
			//URL_Opener.open_url( url, "_blank");
			destroy();
		}
		override public function destroy():void {
			if (_action == "doPrint") {	
				App.ws_art.printReady.visible = false;
				App.ws_art.printReady.btn_ok.removeEventListener(MouseEvent.CLICK, onOkClicked);
				App.ws_art.printReady.btn_close.removeEventListener(MouseEvent.CLICK, onCloseClicked);
			}else if (_action == "doPinterest") {	
				App.ws_art.pinReady.visible = false;
				App.ws_art.pinReady.btn_ok.removeEventListener(MouseEvent.CLICK, onOkClicked);
				App.ws_art.pinReady.btn_close.removeEventListener(MouseEvent.CLICK, onCloseClicked);
			}
			super.destroy();
		}
		protected function _onImageSaved(e:*):void{
		}
		
	}
}