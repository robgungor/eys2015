package code.controllers.add_greeting
{
	import code.skeleton.App;
	
	import com.oddcast.event.AlertEvent;
	import com.oddcast.workshop.WSEventTracker;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	/**
	 * ...
	 * @author Me^
	 */
	public class Add_Greeting
	{
		/** user interface for this controller */
		private var ui					:Add_Greeting_PopUp_UI;
		/** button, generally outside of the UI which opens this view */
		private var btn_open			:DisplayObject;
		
		private static var DEFAULT_GREETING:String = "Enter your greeting here. 45 characters max.";
		
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
		public function Add_Greeting( _btn_open:DisplayObject, _ui:Add_Greeting_PopUp_UI) 
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
			set_ui_listeners();
			ui.tf_input.restrict = "A-Za-z0-9 \-!@#$&'\", . / ?";
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
			
			ui.tf_input.text = App.asset_bucket.endGreeting || DEFAULT_GREETING; 
			ui.tf_count.text = App.asset_bucket.endGreeting ? ui.tf_input.length + " of 45" : "0 of 45";
			
			set_tab_order();
			set_focus();
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
					ui.btn_cancel,
					ui.btn_ok,
					ui.btn_clear
				], MouseEvent.CLICK, mouse_click_handler, this );
			
			ui.tf_input.addEventListener(Event.CHANGE, _onTFChange);
			ui.tf_input.addEventListener(FocusEvent.FOCUS_IN, _onTFFocusIn);
			ui.tf_input.addEventListener(FocusEvent.FOCUS_OUT, _onTFFocusOut);
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
				case ui.btn_ok:		
					if(check_for_badwords(ui.tf_input.text, false)){
						if(ui.tf_input.text.length > 0 && ui.tf_input.text != DEFAULT_GREETING) App.asset_bucket.endGreeting = ui.tf_input.text;
						close_win();
						App.mediator.gotoMakeAnother();
						WSEventTracker.event("ce18");
					}
					break;
				case ui.btn_clear:		
					ui.stage.focus = ui.btn_clear;
					_clearGreeting();					
					break;
				case ui.btn_cancel:	
					close_win();	
					break;
			}
		}
		protected function _onTFChange(e:Event = null):void
		{
			_updateCounter();			
		}
		protected function _onTFFocusIn(e:Event):void
		{
			if(ui.tf_input.text == DEFAULT_GREETING) ui.tf_input.text = "";
		}
		protected function _onTFFocusOut(e:Event):void
		{
			if(ui.tf_input.text == "") ui.tf_input.text = DEFAULT_GREETING;
		}
		protected function _updateCounter():void
		{
			ui.tf_count.text = ui.tf_input.text.length + " of 45";
			
		}
		protected function _clearGreeting():void
		{
			ui.tf_count.text = "0 of 45";
			ui.tf_input.text = DEFAULT_GREETING;
			App.asset_bucket.endGreeting = null;
		}
		/**
		 *sets the tab order of ui elements 
		 * 
		 */		
		private function set_tab_order():void
		{
			App.utils.tab_order.set_order( [ ui.tf_one, ui.tf_two, ui.btn ] );// SAMPLE
		}
		
		
		/**
		 * checks if a string has a bad word or not
		 * @param	_s	string that might contain a badword
		 * @param	_replace_bad_words	if to replace the bad words or leave
		 * @return	returns null if an error is thrown, otherwise returns converted/orignal string
		 */
		private function check_for_badwords( _s:String, _replace_bad_words:Boolean ):String 
		{
			var rtnValue:String;
			if (App.asset_bucket.profanity_validator.is_loaded) {
				if (_replace_bad_words) 
					rtnValue = App.asset_bucket.profanity_validator.replaceBadWords(_s);
				else {
					var badWord:String = App.asset_bucket.profanity_validator.validate(_s);
					if (badWord == "") {
						rtnValue = _s;
					}else {
						App.mediator.alert_user(new AlertEvent(AlertEvent.ERROR, "f9t331", "You cannot use the word " + badWord + ". Please try with a different word.", { badWord:badWord } ));
						rtnValue = null;
					}
				}
			}else {
				rtnValue =_s;
			}
			return rtnValue;
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