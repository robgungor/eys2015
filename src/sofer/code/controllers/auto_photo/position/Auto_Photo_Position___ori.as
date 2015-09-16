package code.controllers.auto_photo.position 
{
	import code.controllers.auto_photo.apc.Auto_Photo_APC;
	import code.models.*;
	import code.skeleton.*;
	
	import com.oddcast.event.*;
	import com.oddcast.utils.*;
	import com.elfyourself.photo.OFCWrapper;
	
	import custom.SlideBar;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	import org.casalib.util.NumberUtil;
	

	
	/**
	 * ...
	 * @author Me^
	 */
	public class Auto_Photo_Position implements IAuto_Photo_Position
	{
		private var ui_position			:Position_UI;
		private var _imageHold:MovieClip;
		private var _mask:DisplayObject;
		private var _rotationSlider:SlideBar;
		private var _zoomSlider:SlideBar;
		private var face_finding_utility:OFCWrapper;
		protected var image_positioner:MoveZoomUtil;
		
		
		public function Auto_Photo_Position( _ui:Position_UI ) 
		{	
			// listen for when the app is considered to have loaded and initialized all assets
			var loaded_event:String = App.mediator.EVENT_WORKSHOP_LOADED_EDITING_STATE;
			App.listener_manager.add(App.mediator, loaded_event, app_initialized, this);
			
			// reference to UI and external assets
			ui_position		= _ui;
			
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
			}
		}
		private function init(  ):void 
		{	
			_imageHold 	= App.ws_art.auto_photo_position.placeholder_apc.image_hold;
			_mask		= App.ws_art.auto_photo_position.placeholder_apc.mask_mc;
			App.mediator.autophoto_set_apc_display_size( new Point(_imageHold.width, _imageHold.height ) );
			
			App.listener_manager.add( ui_position.btn_close, MouseEvent.CLICK, btn_step_handler, this);
			App.listener_manager.add( ui_position.btn_next, MouseEvent.CLICK, btn_step_handler, this);
			App.listener_manager.add( ui_position.btn_change_photo, MouseEvent.CLICK, btn_step_handler, this);
			
			App.listener_manager.add_multiple_by_object( [	ui_position.btn_move_up,
															ui_position.btn_move_down,
															ui_position.btn_move_right,
															ui_position.btn_move_left,
															/*ui_position.btn_zoom_in,
															ui_position.btn_zoom_out,
															ui_position.btn_rot_cc,
															ui_position.btn_rot_c,*/
															ui_position.btn_reset], MouseEvent.MOUSE_DOWN, btn_position_handler, this);
			
			_rotationSlider = new SlideBar(App.ws_art.auto_photo_position.rotate_handle, App.ws_art.auto_photo_position.rotate_slider_bar, App.ws_art.auto_photo_position.btn_rot_cc, App.ws_art.auto_photo_position.btn_rot_c);
			_zoomSlider 	= new SlideBar(App.ws_art.auto_photo_position.zoom_handle, App.ws_art.auto_photo_position.zoom_slider_bar, App.ws_art.auto_photo_position.btn_zoom_in, App.ws_art.auto_photo_position.btn_zoom_out);
			_zoomSlider.addEventListener(Event.CHANGE, _onZoomSliderChange);
			_rotationSlider.addEventListener(Event.CHANGE, _onRotationSliderChange);
			ui_position.cutter.addEventListener(MouseEvent.MOUSE_DOWN, _onCutterMouseDown);
			ui_position.cutter.addEventListener(MouseEvent.MOUSE_UP, _onCutterMouseUp);
			ui_position.cutter.buttonMode = true;
			
			
			face_finding_utility = new OFCWrapper();
			face_finding_utility.load_face_finder();
			image_positioner = new MoveZoomUtil(ui_position.uploadFace.mc_face.mc_image_holder);
			ui_position.position_controls.setTarget(image_positioner);
			image_positioner.enableDragging(true);
		}
		protected function _onCutterMouseDown(e:MouseEvent):void
		{
			var bounds:Rectangle = new Rectangle();
			bounds.bottom 	= ui_position.uploadFace.mask_mc.localToGlobal(new Point(0, ui_position.uploadFace.mask_mc.height-20)).y;
			bounds.top 		= ui_position.uploadFace.y+100;
			bounds.left 	= ui_position.cutter.x;
			bounds.right 	= ui_position.cutter.x;
			
			ui_position.cutter.startDrag(false, bounds);
			ui_position.stage.addEventListener(MouseEvent.MOUSE_UP, _onCutterMouseUp);	
		}
		public function get cutPoint():Number{
			return ui_position.uploadFace.mask_mc.globalToLocal(new Point(0,ui_position.cutter.y+17)).y;
		}
		protected function _onCutterMouseUp(e:Event):void
		{
			ui_position.cutter.stopDrag();
			ui_position.stage.removeEventListener(MouseEvent.MOUSE_UP, _onCutterMouseUp);
		}
		protected function _onZoomSliderChange(e:Event):void
		{
			var scale:Number;//= NumberUtil.map( _zoomSlider.value, 0, 1, MIN_ZOOM, MAX_ZOOM);
			if(_zoomSlider.value < .5)
			{
				scale = NumberUtil.map( _zoomSlider.value, 0, .5, MIN_ZOOM, 1);
			}
			if(_zoomSlider.value >= .5)
			{
				scale = NumberUtil.map( _zoomSlider.value, .5, 1, 1, MAX_ZOOM);
			}
			App.mediator.autophoto_zoom_to(scale);
		}
		protected function _onRotationSliderChange(e:Event):void
		{
			var rot:Number = NumberUtil.map( _rotationSlider.value, 1, 0, -MAX_ROTATION, MAX_ROTATION);
			App.mediator.autophoto_rotate_to(rot);
		}
		/*
		* 
		* 
		* 
		* 
		* 
		* 
		* 
		* 
		***************************** interface methods */
		public function open_win(_action:String=null):void {	
			ui_position.visible = true;
			if(_imageHold.numChildren > 0){
				for(var i:Number = 0; i<_imageHold.numChildren; i++){
					_imageHold.removeChild(_imageHold.getChildAt(i));
				}
			}
			
			_imageHold.addChild( App.mediator.autophoto_get_apc_display_obj() );
			App.mediator.autophoto_get_apc_display_obj().x = (App.mediator.autophoto_get_apc_display_obj().width)/2;
			App.mediator.autophoto_get_apc_display_obj().y = (App.mediator.autophoto_get_apc_display_obj().height) / 2;
			
			_mask.cacheAsBitmap = true;
			_imageHold.mask = _mask;
			App.mediator.autophoto_get_apc_display_obj().addEventListener(MouseEvent.MOUSE_DOWN, _onImageMouseDown);
			//+++++++++++++++++++++++++++++++++
			if (_action == "fromComeback") {
				//doNothing
			}else {
				image_positioner.x = 0;
				image_positioner.y = 0;
				
				var _bmp:Bitmap = App.mediator.autophoto_get_apc_oriBitmap();
				clear_mc(ui_position.uploadFace.mc_face.mc_image_holder);
				ui_position.uploadFace.mc_face.mc_image_holder.addChild(_bmp);
				
				var curX:Number;
				var curY:Number;
				var curRot:Number;
				var curScale:Number;
				var face_location:Array = (_action == "fromWebcam")?(null):( face_finding_utility.find_face(_bmp.bitmapData) );
				if (face_location != null) {	
					App.mediator.doTrace("face_location 111===> "+face_location[0]+"  "+face_location[1]+"  "+face_location[2]+"  "+face_location[3]);
					curX= -face_location[0];
					curY= -face_location[1]-25;
					curRot = ( -180 * face_location[3] / Math.PI);
					curScale = (face_location[2] / 14);
				}else {
					App.mediator.doTrace("face_location 222===> null: "+_bmp.width+"  "+_bmp.height);
					curX = -_bmp.width  * 0.5;
					curY = -_bmp.height * 0.5;
					curRot=0;
					curScale = Math.max((256 / _bmp.width), (256 / _bmp.height));
				}
				_bmp.x = curX;
				_bmp.y = curY;
				image_positioner.scaleTo(curScale);
				image_positioner.rotateTo(curRot);
				
				ui_position.position_controls.updateOriPosition((face_location!=null), curX, curY, curScale, curRot);
			}
			//+++++++++++++++++++++++++++++++++
			
			function clear_mc(_mc:MovieClip):void{
				while(_mc.numChildren > 0){
					_mc.removeChildAt(0);
				}
			}	
		}
		protected function _resetPosition():void{
			_rotationSlider.value = NumberUtil.map(0, -MAX_ROTATION, MAX_ROTATION, 0, 1);			
			_zoomSlider.value = .5;//NumberUtil.map(1, MIN_ZOOM, MAX_ZOOM, 0, 1);
			App.mediator.autophoto_get_apc_display_obj().x = Math.round(App.mediator.autophoto_get_apc_display_size().x/2);
			App.mediator.autophoto_get_apc_display_obj().y = Math.round(App.mediator.autophoto_get_apc_display_size().y/2);
		}
		public function close_win():void 
		{	ui_position.visible = false;
			//trace("POSITION UI x: "+ui_position.x+"; y: "+ui_position.y);
			if(App.mediator.autophoto_get_apc_display_obj())	
			{
			trace("CLOSE autophoto_get_apc_display x: "+App.mediator.autophoto_get_apc_display_obj().x+"; y: "+App.mediator.autophoto_get_apc_display_obj().y);
		
				App.mediator.autophoto_get_apc_display_obj().removeEventListener(MouseEvent.MOUSE_DOWN, _onImageMouseDown);
				_imageHold.buttonMode = true;
			}
		}
		protected function _onImageMouseDown(e:MouseEvent):void
		{
			(App.mediator.autophoto_get_apc_display_obj() as Sprite).startDrag();
			App.mediator.autophoto_get_apc_display_obj().addEventListener(MouseEvent.MOUSE_UP, _onImageMouseUp);
			App.ws_art.stage.addEventListener(MouseEvent.MOUSE_UP, _onImageMouseUp);
		}
		protected function _onImageMouseUp(e:MouseEvent):void
		{
			(App.mediator.autophoto_get_apc_display_obj() as Sprite).stopDrag();
			App.mediator.autophoto_get_apc_display_obj().removeEventListener(MouseEvent.MOUSE_UP, _onImageMouseUp);
			App.ws_art.stage.removeEventListener(MouseEvent.MOUSE_UP, _onImageMouseUp);
			
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
		***************************** PRIVATEEEEEERS */
		private function btn_step_handler( _e:MouseEvent ):void 
		{	switch ( _e.target )
			{	case ui_position.btn_change_photo:	App.mediator.autophoto_change_photo();
													break;
				case ui_position.btn_next:			/*var snapshot:Bitmap = take_snapshot();
													close_win();
													App.mediator.save_masked_photo(snapshot, cutPoint);	*/
													//+++++++++++++++++++++
													var snapshot2:Bitmap = take_snapshot2();
													close_win();
													App.mediator.save_masked_photo(snapshot2, cutPoint);
													//+++++++++++++++++++++
													break;
				case ui_position.btn_close:
					App.mediator.autophoto_close();
					break;
				default:
			}
		}
		private function take_snapshot():Bitmap{
			var maskPosition:Point = new Point(_mask.x, _mask.y);
			_mask.x=_mask.y = 0;
			_imageHold.x -=  maskPosition.x;
			_imageHold.y -=  maskPosition.y;
						
			var data:BitmapData = new BitmapData(_mask.width, _mask.height, true, 0x000000);	
			var mat:Matrix = new Matrix();
			data.draw(_imageHold.parent);//,null,null,null,new Rectangle(face_masker.getMask().x, face_masker.getMask().y, face_masker.getMask().width, face_masker.getMask().height), true);
			var map:Bitmap = new Bitmap(data, "auto", true);			
			_imageHold.x = _imageHold.y = 0;
			_mask.x = maskPosition.x;
			_mask.y = maskPosition.y;
			return map;
		}
		private function take_snapshot2():Bitmap {	//face only
			var _imageHold:MovieClip = ui_position.uploadFace.mc_face;
			var _mask:MovieClip		= ui_position.uploadFace.mask_mc;
			
			var facePosition:Point = new Point(_imageHold.x, _imageHold.y);
			var maskPosition:Point = new Point(_mask.x, _mask.y);
			_mask.x=_mask.y = 0;
			_imageHold.x -=  maskPosition.x;
			_imageHold.y -=  maskPosition.y;
						
			var data:BitmapData = new BitmapData(_mask.width+6, _mask.height, true, 0x000000);	
			var mat:Matrix = new Matrix();
			data.draw(_imageHold.parent);//,null,null,null,new Rectangle(face_masker.getMask().x, face_masker.getMask().y, face_masker.getMask().width, face_masker.getMask().height), true);
			var map:Bitmap = new Bitmap(data, "auto", true);			
			_imageHold.x = facePosition.x;
			_imageHold.y = facePosition.y;
			_mask.x = maskPosition.x;
			_mask.y = maskPosition.y;
			return map;
		}
		private static const MAX_ZOOM:Number = 6.0;
		private static const MIN_ZOOM:Number = .1;
		private static const MAX_ROTATION:Number = 180;
		private function btn_position_handler( _e:MouseEvent ):void 
		{	var dir		:String;
			
			var amount	:int;
			
			switch ( _e.target )
			{	case ui_position.btn_move_up:		dir = Auto_Photo_APC.MOVE_UP;				amount = App.settings.APC_MOVE_AMT;	break;
				case ui_position.btn_move_down:		dir = Auto_Photo_APC.MOVE_DOWN;				amount = App.settings.APC_MOVE_AMT;	break;
				case ui_position.btn_move_right:	dir = Auto_Photo_APC.MOVE_RIGTH;			amount = App.settings.APC_MOVE_AMT;	break;
				case ui_position.btn_move_left:		dir = Auto_Photo_APC.MOVE_LEFT;				amount = App.settings.APC_MOVE_AMT;	break;
				case ui_position.btn_zoom_in:		dir = Auto_Photo_APC.ZOOM_IN;				amount = 1; break;//App.settings.APC_ZOOM_AMT;	break;
				case ui_position.btn_zoom_out:		dir = Auto_Photo_APC.ZOOM_OUT;				amount = 1; break;//App.settings.APC_ZOOM_AMT;	break;
				case ui_position.btn_rot_cc:		dir = Auto_Photo_APC.ROT_COUNTER_CLOCKWISE;	amount = App.settings.APC_ROT_AMT ;	break;
				case ui_position.btn_rot_c:			dir = Auto_Photo_APC.ROT_CLOCKWISE;			amount = App.settings.APC_ROT_AMT ;	break;
				case ui_position.btn_reset:			_resetPosition(); return;//dir = Auto_Photo_APC.RESET_IMAGE;			amount = 0;	break;
				default:
			}
			
			_move( dir, amount );
			
			// do it on repeat if possible
			if (ui_position.stage)	// only if we have access to the stage
			{	var timer:Timer = new Timer(50, 0);//App.settings.APC_REPEAT_TIME, 0);
				timer.start();
				App.listener_manager.add( ui_position.stage, MouseEvent.MOUSE_UP, stop_timer, this );
				App.listener_manager.add( ui_position.stage, MouseEvent.MOUSE_OUT, stop_timer, this );
				App.listener_manager.add( timer, TimerEvent.TIMER, call_on_repeat, this );
				function call_on_repeat( _e:TimerEvent ):void 
				{	_move( dir, amount );
					
				}
				function stop_timer( _e:MouseEvent ):void
				{	App.listener_manager.remove( ui_position.stage, MouseEvent.MOUSE_UP, stop_timer );
					App.listener_manager.remove( ui_position.stage, MouseEvent.MOUSE_OUT, stop_timer );
					App.listener_manager.remove_all_listeners_on_object( timer );
					timer.stop();
					timer = null;
				}
			}
		}
		protected function _move(dir:String, amount:Number):void
		{
			trace("MOVE: "+dir+" ; "+amount);
			if(dir == Auto_Photo_APC.ROT_CLOCKWISE || dir == Auto_Photo_APC.ROT_COUNTER_CLOCKWISE)
			{
				var rot:Number = NumberUtil.map( _rotationSlider.value, 0, 1, -MAX_ROTATION, MAX_ROTATION);
				_rotationSlider.value = NumberUtil.map(rot+amount, -MAX_ROTATION, MAX_ROTATION, 0, 1);
			}
			var scale:Number = NumberUtil.map( _zoomSlider.value, 0, 1, MIN_ZOOM, MAX_ZOOM);
			if(dir == Auto_Photo_APC.ZOOM_IN)
			{	
				_zoomSlider.value = NumberUtil.map(scale+(scale*.035), MIN_ZOOM, MAX_ZOOM, 0, 1);
			}
			if( dir == Auto_Photo_APC.ZOOM_OUT)
			{
				_zoomSlider.value = NumberUtil.map(scale-(scale*.035), MIN_ZOOM, MAX_ZOOM, 0, 1);
			}
			//App.mediator.autophoto_move_photo( dir, amount );
		}
		//*********************************************************************
		//*********************************************************************
	}

}