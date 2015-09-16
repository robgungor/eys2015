package code.controllers.instagram_connect
{
	
	import code.skeleton.App;
	
	import com.adobe.serialization.json.JSON;
	import com.adobe.utils.ArrayUtil;
	import com.oddcast.event.AlertEvent;
	import com.oddcast.utils.Event_Expiration;
	import com.oddcast.utils.gateway.Gateway;
	import com.oddcast.utils.gateway.Gateway_Request;
	import com.oddcast.workshop.Callback_Struct;
	import com.oddcast.workshop.ExternalInterface_Proxy;
	import com.oddcast.workshop.ServerInfo;
	import com.oddcast.workshop.WSEventTracker;
	import com.oddcast.workshop.WorkshopMessage;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.utils.Dictionary;
	
	import workshop.fbconnect.FacebookImage;
	import workshop.fbconnect.FacebookUser;
	import workshop.fbconnect.Facebook_Friend_Item;
	
	
	/**
	 * FaceBook Connect interfaces with javascript for retrieving user information, friends and photos
	 * @author Me^
	 */
	public class Instagram_Connect 
	{
		
		private const EVENT_GET_PHOTOS_KEY	:String = 'EVENT_GET_PHOTOS_KEY';
		private const PROCESSING_LOADING_GOOGLEPLUS_DATA :String = 'Loading GooglePlus data'
		
		private var ui					:Facebook_Connect_Status_UI;
		
		private var GoogleplusId					:String;//isaac
		
		
		/** current user thumb */
		private var cur_thumb				: Loader;
		/** get user pictures callback */
		private var get_user_pictures_callback:Function;
		/** when the user logs in something might need to be notified so this is how. */
		private var on_logged_in_callback:Function;
		/** keeps track of external calls that timeout */
		private var event_expiration		:Event_Expiration = new Event_Expiration();
		
		/** previous results stored by user id key... so dic[userid] = String of previous javascript query */
		private var cached_results_friends_info:Dictionary 			= new Dictionary();
		/** previous results stored by user id key... so dic[userid] = String of previous javascript query */
		private var cached_results_users_pictures:Dictionary 		= new Dictionary();
		/** previous results stored by user id key... so dic[userid] = String of previous javascript query */
		private var cached_results_friends_pictures:Dictionary 		= new Dictionary();
		/** previous results stored by user id key... so dic[userid] = String of previous javascript query */
		private var cached_results_friends_album_pictures:Dictionary = new Dictionary();
		/*
		* 
		* 
		* 
		* 
		* 
		* 
		* 
		* 
		***************************** INIT */
		/**
		 * Constructor
		 */
		public function Instagram_Connect(  ) 
		{
			// listen for when the app is considered to have loaded and initialized all assets
			var loaded_event:String = App.mediator.EVENT_WORKSHOP_LOADED;
			App.listener_manager.add(App.mediator, loaded_event, app_initialized, this);
			
			// provide the mediator a reference to send data to this controller
			var registered:Boolean = App.mediator.register_controller(this);
			
			/** called when the application has finished the inauguration process */
			function app_initialized(_e:Event):void
			{
				App.listener_manager.remove_caught_event_listener( _e, arguments );
				init();// init after inauguration since allow domain is set up there
			}
		}
		/**
		 * initializes the controller if the check above passed
		 */
		private function init(  ):void 
		{	
			try 
			{				
				ExternalInterface_Proxy.marshallExceptions = true;
			
				ExternalInterface_Proxy.addCallback("flash_Instagram_Callback_photos", InstagramCallback_photos);
				
			}
			catch (e:Error) 
			{
				trace('(Oo) Instagram_Connect CANT SET JAVASCRIPT LISTENERS');
			}
			
			
			
		}
		/************************************************
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 ***************************** INTERFACE API */
		/**
		 * displays the UI
		 * @param	_e
		 */
		public function open_win(  ):void 
		{	
			ui.visible = true;
		}
		/**
		 * hides the UI
		 * @param	_e
		 */
		public function close_win(  ):void 
		{	
			ui.visible = false;
		}
		
		
		//*********************************************************************
		
		
		private var _onLoginCallback:Function;
		
		public function is_googlePlus_logged_in():Boolean { ///Isaac
			
			return(GoogleplusId != '0' && GoogleplusId != null);
		}
		public function InstagramCallback_photos (_data:*):void {
			trace("InstagramCallback_photos - data = " + _data);
			
			//JSON.decode(_data);
			//trace("InstagramCallback_photos - JSON.decode(_data) = " + JSON.decode(_data) );
			
			var JSON_object:Object = JSON.decode(_data);
			for ( var prop in JSON_object) {
				//trace ("InstagramCallback_photos ---> '"+prop+"' = '"+JSON_object[prop]+"'");
				
				for ( var prop2 in JSON_object[prop]) {
					//trace ("InstagramCallback_photos --- ==> '"+prop2+"' = '"+JSON_object[prop][prop2]+"'");
					if ( prop2=="id" || prop2=="images") {
						trace ("InstagramCallback_photos --- ==> '" + prop2 + "' = '" + JSON_object[prop][prop2] + "'");
						
						for ( var prop3 in JSON_object[prop][prop2]) {
							trace ("InstagramCallback_photos --- ====> '"+prop3+"' = '"+JSON_object[prop][prop2][prop3]+"'");
							
							for ( var prop4 in JSON_object[prop][prop2][prop3]) {
								trace ("InstagramCallback_photos --- ======> '"+prop4+"' = '"+JSON_object[prop][prop2][prop3][prop4]+"'");
							}
						}
					}
					
					
				}
			}
		}
		public function igcSetConnectState(n:Object):void { ///Isaac
			trace("Instagram_Connect::gpSetConnectState - googlePlus - n='"+n+"'");
			//if (n.valueOf() < 0) 				n = '0';
			//if (n == GoogleplusId) 	return;
			ExternalInterface_Proxy.call("oddcastInstagram_init");
			
			GoogleplusId = n.toString();	
			trace("Instagram_Connect::gpSetConnectState - GoogleplusId = '"+GoogleplusId+"'");
			
			if ( is_googlePlus_logged_in() ) {
				if(_onLoginCallback != null) 
				{
					_onLoginCallback();
					return;
				}
				
				WSEventTracker.event("edfbc");
			}else{					
				//App.mediator.googlePlusLoginFail();	
			}
			
		}
		//private const PROCESSING_LOADING_GOOGLEPLUS_DATA :String = 'Loading google plus data';
		public function igcGetPictures( _fin:Function, _friends_id:String=null ):void {///Isaac
			trace("Instagram_Connect::gpcGetPictures - googlePlus - ");
			
			get_user_pictures_callback = _fin;
			App.mediator.processing_start(PROCESSING_LOADING_GOOGLEPLUS_DATA,PROCESSING_LOADING_GOOGLEPLUS_DATA);
			event_expiration.add_event( EVENT_GET_PHOTOS_KEY, App.settings.EVENT_TIMEOUT_MS+30000, get_friends_timedout );
			
			
			function get_friends_timedout(  ):void 
			{	
				get_user_pictures_callback = null;	// remove callbacks in case it comes in later on
				_fin(null);	// indicate there was an error
			}
			
			ExternalInterface_Proxy.call("gpGetUserPictures");//isaac
			
		}
		
		public function login(cb:Function):void
		{
			_onLoginCallback = cb;
			ExternalInterface_Proxy.call("gpLogin");
			
		}
		
		public function gpSetUserPictures(inputXML:String):void { ///Isaac
			trace("Facebook_Connect::gpSetUserPictures - googlePlus - inputXML='" + inputXML + "'");
			
			App.mediator.processing_ended(PROCESSING_LOADING_GOOGLEPLUS_DATA);
			event_expiration.remove_event( EVENT_GET_PHOTOS_KEY );
			
			var _xml:XML = new XML(inputXML);
			var res:String = _xml.response.@result.toString();
			
			if (res == "OK") {
				trace("Instagram_Connect::gpSetUserPictures - googlePlus - res="+res);
				var photoArr:Array = build_photos_array(inputXML);
				
				if (get_user_pictures_callback != null){	// possibly removed because it timed out
					trace("Instagram_Connect::gpSetUserPictures - googlePlus - photoArr.length="+photoArr.length);
					
					if (photoArr.length == 0) {
						trace("Instagram_Connect::gpSetUserPictures - googlePlus - no photos");
						get_user_pictures_callback(null)		// no photos
					}else{
						get_user_pictures_callback(photoArr);	// everything is ok
					}
				}
			}else if (res == "ERROR") {
				trace("Instagram_Connect::gpSetUserPictures - googlePlus - res="+res);
				if (get_user_pictures_callback != null)		get_user_pictures_callback(null);		// possibly removed because it timed out
			}
		}
		
	
		/************************************************
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 ***************************** INTERNALS */
		
		
		/**
		 * builds an array of FacebookImage 
		 * @param _raw_xml XML photo node
		 <1>
		 <pid>23687925792340515</pid>
		 <aid>23687925755872275</aid>
		 <owner>5515275</owner>
		 <src>http://photos-f.ak.fbcdn.net/hphotos-ak-snc1/hs026.snc1/2357_625662839546_5515275_38894115_6564_s.jpg</src>       <!-- aprox 130x97 -->
		 <src_big>http://sphotos.ak.fbcdn.net/hphotos-ak-snc1/hs026.snc1/2357_625662839546_5515275_38894115_6564_n.jpg</src_big>    <!-- aprox 600x450 -->
		 <src_small>http://photos-f.ak.fbcdn.net/hphotos-ak-snc1/hs026.snc1/2357_625662839546_5515275_38894115_6564_t.jpg</src_small>    <!-- aprox 75x56 -->
		 <link>http://www.facebook.com/photo.php?pid=38894115&amp;id=5515275</link>
		 <caption/>
		 <created>1235426176</created>
		 <modified>1252470728</modified>
		 <object_id>625662839546</object_id>
		 <src_small_height>56</src_small_height>
		 <src_small_width>75</src_small_width>
		 <src_big_height>450</src_big_height>
		 <src_big_width>600</src_big_width>
		 <src_height>97</src_height>
		 <src_width>130</src_width>
		 </1>
		 * 
		 * @return
		 */		
		private function build_photos_array(_raw_xml:String):Array
		{
			var xml			:XML = new XML(_raw_xml);
			var photoXML	:XML;
			var photo		:FacebookImage;
			var arr_photos	:Array = new Array();
			var num_of_images:int = xml.response.children().length();
			var profileImage:FacebookImage;
			for (var i:int = 0; i < num_of_images; i++)
			{
				photoXML			= xml.response.children()[i];
				
				photo				= new FacebookImage();
				photo.id			= parseInt(photoXML.pid.toString());
				
				photo.albumId		= parseInt(photoXML.aid.toString());
				photo.userId		= photoXML.owner.toString();
				photo.name			= photoXML.caption.toString();
				photo.url			= photoXML.src_big.toString();
				photo.thumbUrl		= photoXML.src_small.toString();//photoXML.src_small.toString(); // too small
				photo.linkUrl		= photoXML.link.toString();
				photo.creationTime	= parseInt(photoXML.created.toString());
				photo.modifyTime	= parseInt(photoXML.modified.toString());
				
				arr_photos.push(photo);
				
			}
			
			return arr_photos;
		}
		/************************************************
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 * 
		 */
		
		
		
	}
	
}