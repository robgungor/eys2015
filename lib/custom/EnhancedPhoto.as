package custom 
{
	import code.skeleton.App;
	import com.oddcast.utils.ImageUtil;
	
	import com.oddcast.event.AlertEvent;
	import com.oddcast.utils.gateway.Gateway;
	import com.oddcast.utils.gateway.Gateway_Request;
	import com.oddcast.workshop.Callback_Struct;
	
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	
	import org.aswing.image.png.AsPngEncoder;
	import org.aswing.image.png.Strategy8BitMedianCutAlpha;

	/**
	 * Dispatched when the image has been uploaded.
	 *
	 * @eventType flash.events.Event.COMPLETE
	 *
	 * @see #event:complete
	 */
	[Event(name="complete", type="flash.events.Event")]
	
	public class EnhancedPhoto extends EventDispatcher
	{
		private const PROCESS_UPLOADING		:String = 'PROCESS_UPLOADING uploading enhanced image';
		
		public function EnhancedPhoto(bmp:Bitmap = null, $url:String = "")
		{
			// we do this if we are using an already uploaded a bitmap 
			if($url != '') 
			{
				_url = $url;
				if(bmp == null) _loadBitmap();
			}
			else if(bmp != null)
			{
				_bitmap = bmp;
				_upload();
			}
			
			
		}
		private function _loadBitmap():void
		{
			Gateway.retrieve_Bitmap(_url, new Callback_Struct(fin));
			
			function fin(bmp:Bitmap):void
			{
				_bitmap = ImageUtil.fitImageProportionally(bmp, 205, 205);
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		private function _upload():void
		{
			var encoder:AsPngEncoder = new AsPngEncoder();			
			var img_data:ByteArray = encoder.encode(_bitmap.bitmapData, new Strategy8BitMedianCutAlpha());
			//App.mediator.processing_start( PROCESS_UPLOADING);
			App.utils.image_uploader.upload_binary( new Callback_Struct( _fin, _progress, _error ), img_data, "png", _serverCapacity_error);
		}
		private function _fin(_bg:*):void 
		{	
			_url = _bg.url;
			App.mediator.processing_ended( PROCESS_UPLOADING);
			dispatchEvent( new Event(Event.COMPLETE) );
			
		}
		public function _progress(_percent:int):void {	
			
		}
		public function _error(_e:AlertEvent):void 
		{	//App.mediator.processing_ended( PROCESS_UPLOADING );
			App.mediator.alert_user(_e);
		}
		private function _serverCapacity_error():void {
			App.mediator.doTrace("serverCapacity_error===> xxxxxx");
			App.mediator.alert_user( new AlertEvent(AlertEvent.ERROR, "", "Server capacity surpassed.  Please try again later."));
				
			//App.mediator.autophoto_open_mode_selector();
			//++++++++++++++++++++++++++++++
			
			//++++++++++++++++++++++++++++++
		}
		private var _url:String;
		private var _bitmap:Bitmap;		
		
		public function get url():String
		{
			return _url;
		}

		public function set url(value:String):void
		{
			_url = value;
		}

		public function get bitmap():Bitmap
		{
			return _bitmap;
		}

		public function set bitmap(value:Bitmap):void
		{
			_bitmap = value;
		}


	}
}