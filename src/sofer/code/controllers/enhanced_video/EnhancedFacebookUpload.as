package code.controllers.enhanced_video
{
	import code.component.skinners.Custom_Scrollbar_Skinner;
	import code.component.skinners.Custom_TileList_Skinner;
	import code.controllers.facebook_friend.Facebook_Friends_TileList_CellRenderer;
	import com.oddcast.utils.ImageUtil;
	
	import com.oddcast.assets.structures.BackgroundStruct;
	import com.oddcast.event.AlertEvent;
	import com.oddcast.utils.gateway.Gateway;
	import com.oddcast.utils.gateway.Gateway_Request;
	import com.oddcast.workshop.Callback_Struct;
	import com.oddcast.workshop.WSBackgroundStruct;
	
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.ProgressEvent;
	
	import workshop.fbconnect.FacebookUser;
	import custom.EnhancedPhoto;

	public class EnhancedFacebookUpload
	{
		
	import code.skeleton.App;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	/**
	 * ...
	 * @author Me^
	 */
		public static const PROCESS_UPLOADING	:String = 'PROCESS_UPLOADING';
		public static const PROCESS_SEARCHING	:String = 'PROCESS_SEARCHING';
		
		/** user interface for this controller */
		private var ui					:EnhancedFacebookUpload_UI;
		/** button, generally outside of the UI which opens this view */
		private var btn_open			:DisplayObject;
		
		/*******************************************************
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
		 * ******************************** INIT */
		/**
		 * Constructor
		 */
		public function EnhancedFacebookUpload( _btn_open:DisplayObject, _ui:EnhancedFacebookUpload_UI) 
		{
			// listen for when the app is considered to have loaded and initialized all assets
			var loaded_event:String = App.mediator.EVENT_WORKSHOP_LOADED;
			//			var loaded_event:String = App.mediator.EVENT_WORKSHOP_LOADED_PLAYBACK_STATE;
			//			var loaded_event:String = App.mediator.EVENT_WORKSHOP_LOADED_EDITING_STATE;
			App.listener_manager.add(App.mediator, loaded_event, app_initialized, this);
			
			// reference to the controllers UI
			ui			= _ui;
			btn_open	= _btn_open;
			
			// provide the mediator a reference to communicate with this controller
			var registered:Boolean = App.mediator.register_controller(this);
			
			// calls made before the initialization starts
			close_win();
			
			/** called when the application has finished the inauguration process */
			function app_initialized(_e:Event):void
			{
				App.listener_manager.remove_caught_event_listener( _e, arguments );
				// init this after the application has been inaugurated
				init();
			}
		}
		/**
		 * initializes the controller if the check above passed
		 */
		private function init(  ):void 
		{	
			init_shortcuts();
						
			new Custom_Scrollbar_Skinner( ui.tileList );
			new Custom_TileList_Skinner( ui.tileList, Facebook_Friends_TileList_CellRenderer );
			//ui.user_image_placehold.visible = false;
			ui.tileList.width=530;
			
			set_ui_listeners();
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
		 ***************************** PUBLIC INTERFACE */
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
		 ***************************** PRIVATE */
		
		
		private function start_search_processing(  ):void
		{
			App.mediator.processing_start( PROCESS_SEARCHING );
		}
		private function retrieve_facebook_user_own_images(  ):void
		{
			if (App.mediator.facebook_connect_is_logged_in())
				user_logged_in_get_own_photos();
			else	
				App.mediator.facebook_connect_login(user_logged_in_get_own_photos);
			
			function user_logged_in_get_own_photos(  ):void 
			{	
				start_search_processing();
				getFacebookUserImages();
			}
		}
		protected function getFacebookUserImages():void
		{
			if (!App.mediator.facebook_connect_is_logged_in())
			{
				App.mediator.alert_user(new AlertEvent(AlertEvent.ERROR, "f9t219", "We could not access your facebook images.  Please make sure you are logged in."));
				App.mediator.processing_ended( PROCESS_SEARCHING );
			}
			else
				App.mediator.facebook_connect_get_user_photos(gotFacebookUserImages);
		}
		
		private function gotFacebookUserImages(arr:Array):void {
			if (arr == null ||
				arr.length == 0) 
			{
				App.mediator.processing_ended( PROCESS_SEARCHING );
				App.mediator.alert_user(new AlertEvent(AlertEvent.ERROR, "f9t220", "We could not retreive any facebook images.  Please make sure you are tagged in your photos."));
				return;
			}
			populate_image_selector(arr);
		}
		private var num_of_images:Number;
		private function populate_image_selector( arr:Array ):void
		{	
			App.mediator.processing_ended( PROCESS_SEARCHING );			
			ui.tileList.removeAll();			
			
			if (arr.length == 0) 
			{
				App.mediator.alert_user(new AlertEvent(AlertEvent.ERROR, 'f9t212', 'Your friend does not allow applications to access their photos. Please try another friend.'));
				
				return;
			}
			else 
			{
				num_of_images = 0;
			}
			
			var user:FacebookUser = App.mediator.facebook_connect_user();
			for (var n:int = arr.length, i:int = 0; i < n; i++)
			{
				var image:WSBackgroundStruct = arr[i];
				num_of_images++;
				if(image && image.url) {
					var item:* = ui.tileList.addItem( {thumb:image.thumbUrl, label:"", data:image} );
					
				}
					
			}
		}
		
		private function friend_selected( _e:Event ):void
		{
			select_image();
			var selected_item:Object = ui.tileList.selectedItem;
			if (selected_item)
			{
				
				
			}
		}
		private var _selectedItems:Array = [];	
		protected function _reselectItems():void
		{
			if(_selectedItems.length < 1)
			{
				ui.tileList.selectedItem = null;
			}else{
				ui.tileList.selectedItems =  _selectedItems;
				ui.tileList.drawNow();	
			}
			
			ui.tf_counter.text = _selectedItems.length +" of 6";
		}
		private function select_image(  ):void
		{
			var selected_item:Object = ui.tileList.selectedItem;
			
			var items:Array = ui.tileList.selectedItems;
			
			for(var i:Number = 0; i<items.length; i++)
			{
				var item:Object = items[i];
				var alreadySelected:Boolean;
				for(var j:Number= 0; j<_selectedItems.length; j++){
					if(item == _selectedItems[j]) alreadySelected = true;
				}
				if(!alreadySelected) 
				{
					selected_item = item;
				}
			}
		
			if (selected_item)
			{
				if(_selectedItems.indexOf(selected_item) > -1) 
				{
					_selectedItems.splice(_selectedItems.indexOf(selected_item), 1);
					
				} else{
					_selectedItems.push(selected_item);	
					
				}
				_reselectItems();
				
				if(_selectedItems.length >= 6) _uploadPhotosAndExit();
				
			}
			else
			{
				App.mediator.alert_user(new AlertEvent(AlertEvent.ERROR, 'f9t210', 'Please select an image'));
			}
		}
		
		protected function _uploadPhotosAndExit(e:MouseEvent = null):void
		{
			if(_selectedItems.length > 0) _uploadNextPhoto();
			else _exit();
		}
		protected function _exit():void
		{
			close_win();
			App.mediator.loadHouseParty();
		}
		private static const LOADING_UPLOADED_BITMAP:String = "loading uploaded bitmap";
		
		protected function _uploadNextPhoto():void
		{
			var item:Object = _selectedItems.shift(); 
			var image:WSBackgroundStruct = item.data as WSBackgroundStruct;			
			if(image.isUploadPhoto)
			{
				fin(image);
			}else
			{
				App.mediator.processing_start( PROCESS_UPLOADING );
				
				//close_win();
				App.utils.image_uploader.upload_url( new Callback_Struct( fin, progress, error ), image.url, true);
			}
			function fin(_bg:BackgroundStruct):void 
			{	
				image.url = _bg.url;
				image.isUploadPhoto = true;
				App.mediator.processing_ended( PROCESS_UPLOADING );
				var enhanced:EnhancedPhoto = new EnhancedPhoto(null, _bg.url);
				enhanced.addEventListener(Event.COMPLETE, _downloaded);
				App.asset_bucket.enhancedPhotos.push(enhanced);
				function _downloaded(e:Event):void
				{
					if(_selectedItems.length > 0) 
					{
						_uploadNextPhoto();
					}
					else 
					{
						_exit();
					}	
				}
				
				
				//App.mediator.autophoto_analyze_photo( _bg.url );
			}
			function progress(_percent:int):void 
			{	
				App.mediator.processing_start( PROCESS_UPLOADING, null, _percent );
			}
			function error(_e:AlertEvent):void 
			{	
				App.mediator.processing_ended( PROCESS_UPLOADING );
				App.mediator.alert_user(_e);
			}
		}
		/*******************************************************
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
		 * ******************************** VIEW MANIPULATION - PRIVATE */
		/**
		 * displays the UI
		 * @param	_e
		 */
		private function open_win(  ):void 
		{	
			ui.visible = true;
			set_tab_order();
			set_focus();
			
			retrieve_facebook_user_own_images();
		}
		/**
		 * hides the UI
		 * @param	_e
		 */
		private function close_win(  ):void 
		{	
			ui.visible = false;
			
		}
		/**
		 * adds listeners to the UI
		 */
		private function set_ui_listeners():void 
		{
			App.listener_manager.add_multiple_by_object( 
				[
					btn_open, 
					ui.btn_close 
				], MouseEvent.CLICK, mouse_click_handler, this );
			
			ui.btn_letsdance.addEventListener(MouseEvent.CLICK, _uploadPhotosAndExit);
			App.listener_manager.add(ui.tileList, Event.CHANGE, friend_selected, this);
			
		}
		/**
		 * handler for Click MouseEvents from the UI
		 * @param	_e
		 */
		private function mouse_click_handler( _e:MouseEvent ):void
		{
			switch ( _e.currentTarget )
			{	
				case btn_open:		
					open_win();		
					break;
				case ui.btn_close:	
					close_win();	
					break;
			}
		}
		/**
		 *sets the tab order of ui elements 
		 * 
		 */		
		private function set_tab_order():void
		{
			App.utils.tab_order.set_order( [ ui.tf_one, ui.tf_two, ui.btn ] );// SAMPLE
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
		 ***************************** KEYBOARD SHORTCUTS */
		/**
		 * sets stage focus to the UI
		 */
		private function set_focus():void
		{	
			ui.stage.focus = ui;
		}
		/**
		 * initializes keyboard shortcuts
		 */
		private function init_shortcuts():void
		{	
			App.shortcut_manager.api_add_shortcut_to( ui, Keyboard.ESCAPE, shortcut_close_win );
		}
		/**
		 * hides the UI
		 */
		private function shortcut_close_win(  ):void 		
		{	
			if (ui.visible)		
				close_win();	
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