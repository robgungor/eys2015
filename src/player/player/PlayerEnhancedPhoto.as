package player
{
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
	
	public class PlayerEnhancedPhoto extends EventDispatcher
	{
		private const PROCESS_UPLOADING		:String = 'PROCESS_UPLOADING uploading enhanced image';
		
		public function PlayerEnhancedPhoto(bmp:Bitmap = null, $url:String = "")
		{
			// we do this if we are using an already uploaded a bitmap 
			if($url != '') 
			{
				_url = $url;
				_loadBitmap();
			}
			
			
			
		}
		private function _loadBitmap():void
		{
			Gateway.retrieve_Bitmap(_url, new Callback_Struct(fin));
			
			function fin(bmp:Bitmap):void
			{
				_bitmap = ImageUtil.fitImageProportionally(bmp, 200, 200);
				dispatchEvent(new Event(Event.COMPLETE));
			}
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