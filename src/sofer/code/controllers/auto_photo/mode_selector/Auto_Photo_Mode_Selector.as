package code.controllers.auto_photo.mode_selector 
{
	import code.HeadStruct;
	import code.models.*;
	import code.skeleton.*;
	
	import com.oddcast.data.ThumbSelectorData;
	import com.oddcast.event.SelectorEvent;
	import com.oddcast.workshop.Persistent_Image.IPersistent_Image_Item;
	import com.oddcast.workshop.WSEventTracker;
	import com.oddcast.utils.URL_Opener;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import workshop.persistent_image.Persistent_Image_Selector_Item;

	/**
	 * ...
	 * @author Me^
	 */
	public class Auto_Photo_Mode_Selector implements IAuto_Photo_Mode_Selector
	{
		private var ui		:Mode_Selection_UI;
		
		public function Auto_Photo_Mode_Selector( _ui:Mode_Selection_UI ) 
		{
			// listen for when the app is considered to have loaded and initialized all assets
			var loaded_event:String = App.mediator.EVENT_WORKSHOP_LOADED_EDITING_STATE;
			App.listener_manager.add(App.mediator, loaded_event, app_initialized, this);
			
			// reference to UI and external assets
			ui		= _ui;
			
			// provide the mediator a reference to send data to this controller
			var registered:Boolean = App.mediator.register_controller(this);
			
			// calls made before the initialization starts
			close_win();
			
			/** called when the application has finished the inauguration process */
			function app_initialized(_e:Event):void
			{
				App.listener_manager.remove_caught_event_listener( _e, arguments );
				// init this after the application has been inaugurated
				init();
				open_win();
			}
		}
		private function init(  ):void 
		{	
			App.listener_manager.add_multiple_by_object([
				ui.btn_elfYourselfLogo,
				ui.btn_browse, 
				ui.btn_facebook, 
				//ui.btn_instagram, 
				ui.btn_webcam, 
				ui.btn_close ], MouseEvent.CLICK, btn_handler, this);
			
			init_selector();
			
			ui.accept_Cb.addEventListener(MouseEvent.CLICK, _onCbClicked);
			
			App.listener_manager.add( ui.termsConditions, MouseEvent.CLICK, show_terms, this );
		}
		private function show_terms( _e:MouseEvent ):void 
		{
			App.mediator.open_hyperlink(App.settings.TERMS_CONDITIONS_LINK, "_blank");
		}
		private var _termsHasBeenClicked:Boolean = false;
		private function _onCbClicked( e:MouseEvent = null):void
		{
			if(ui.accept_Cb.selected)
			{
				//ui.btn_browse.mouseEnabled = ui.btn_facebook.mouseEnabled= ui.btn_instagram.mouseEnabled = ui.btn_webcam.mouseEnabled = true;
				ui.btn_browse.mouseEnabled = ui.btn_facebook.mouseEnabled = ui.btn_webcam.mouseEnabled = true;
				//ui.btn_browse.alpha = ui.btn_facebook.alpha = ui.btn_instagram.alpha = ui.btn_webcam.alpha = 1;
				ui.btn_browse.alpha = ui.btn_facebook.alpha = ui.btn_webcam.alpha = 1;
				_termsHasBeenClicked = true;
				
			} else{
				//ui.btn_browse.mouseEnabled = ui.btn_facebook.mouseEnabled = ui.btn_instagram.mouseEnabled = ui.btn_webcam.mouseEnabled = false;
				ui.btn_browse.mouseEnabled = ui.btn_facebook.mouseEnabled = ui.btn_webcam.mouseEnabled = false;
				//ui.btn_browse.alpha = ui.btn_facebook.alpha = ui.btn_instagram.alpha = ui.btn_webcam.alpha = .35;
				ui.btn_browse.alpha = ui.btn_facebook.alpha = ui.btn_webcam.alpha = .35;
			}
			
		}
		public function get optedIn():Boolean
		{
			return ui.accept_Cb.selected;
		}
		/**
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
		 * **************************************************************/
		public function open_win(  ) : void
		{
			App.mediator.doTrace("===> xxxxx 4");
			ui.visible = true;
			App.ws_art.dancers.visible = true;
			_onCbClicked();
			//populate_selector();
		}
		public function close_win(  ) : void
		{
			ui.visible = false;
			App.mediator.hideDancers();
		}
		/*****************************************************************
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
		 * 
		 * 
		 * 
		 * **************************************************************/
		private function btn_handler( _e:MouseEvent ):void 
		{	
			switch (_e.target) 
			{	
				case ui.btn_elfYourselfLogo:	var OFFICE_MAX_LINK:String = App.mediator.LOGO_LINK;//"http://www.officedepot.com/a/content/holiday/elf-yourself/";
												URL_Opener.open_url( OFFICE_MAX_LINK, "_blank");				
												break;
				case ui.btn_browse:				App.mediator.doTrace("Auto_photo_mode_selector ===> btn_browse");
												App.mediator.checkOptIn(App.mediator.autophoto_mode_browse);				
												break;
				case ui.btn_facebook:	
					App.mediator.checkOptIn(_optInSearchConfirm);
					break;
//				case ui.btn_instagram:	
//					break;
				case ui.btn_webcam:			
					App.mediator.checkOptIn(_webCamConfirm);
					break;
				case ui.btn_close:			close_win();
			}
			
		}
		private function _optInSearchConfirm():void
		{
			App.mediator.autophoto_mode_search();
			WSEventTracker.event("ce3");
			close_win();
		}
		private function _webCamConfirm():void
		{
			close_win();
			WSEventTracker.event("ce2");
			App.mediator.autophoto_mode_webcam();
		}
		/*****************************************************************
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
		 */
		private function init_selector(  ):void 
		{
			ui.image_selector.addScrollBtn( ui.btn_scroll_prev, -2 );
			ui.image_selector.addScrollBtn( ui.btn_scroll_next, 2 );
			ui.image_selector.addItemEventListener( Persistent_Image_Selector_Item.DELETE_IMAGE_EVENT, delete_image );
			ui.image_selector.addItemEventListener( Persistent_Image_Selector_Item.SELECT_EVENT, image_selected );
		}
		private function delete_image( _e:SelectorEvent ):void 
		{
			var thumb_data:ThumbSelectorData = _e.currentTarget.data;
			var cur_photo:IPersistent_Image_Item = thumb_data.obj as IPersistent_Image_Item;
			var cur_id:String = cur_photo.id();
		
		}
		private function image_selected( _e:SelectorEvent ):void 
		{
			//if(!ui.accept_Cb.selected) return;
			//App.mediator.checkOptIn( image_selected_fin );
			image_selected_fin();
			function image_selected_fin():void {
				var head		:HeadStruct		= _e.currentTarget.data as HeadStruct;
				//var selected_image	:IPersistent_Image_Item	= wrapper_obj.obj as IPersistent_Image_Item; 
				//App.mediator.persistant_swap_head(head);
				WSEventTracker.event("edbgs",head.url);
				close_win();
			
			}
		}
		
		private function populate_selector(  ):void 
		{
			ui.image_selector.clear();
			var num_of_images:int = App.mediator.persistantImages.length;//pi_api.get_num_of_images();
			for (var i:int = 0; i < num_of_images; i++) 
			{
				var cur_image:HeadStruct = App.mediator.persistantImages[i];
				var id:int = parseInt( cur_image.url );
				//var image:ThumbSelectorData = new ThumbSelectorData( cur_image.id, cur_image);
				var nume:String = '';
				ui.image_selector.add( i, nume, cur_image, false );
			}
			ui.image_selector.update();
		}
	}

}