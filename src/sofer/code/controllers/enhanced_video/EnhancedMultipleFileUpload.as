package code.controllers.enhanced_video
{

	import code.models.*;
	import code.skeleton.*;
	
	import com.oddcast.event.*;
	import com.oddcast.oc3d.content.*;
	import com.oddcast.utils.*;
	import com.oddcast.utils.ImageUtil;
	import com.oddcast.utils.gateway.Gateway;
	import com.oddcast.utils.gateway.Gateway_Error;
	import com.oddcast.utils.gateway.Gateway_FileReference_Result;
	import com.oddcast.workshop.*;
	import com.oddcast.workshop.throttle.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.ui.*;
	
	import org.casalib.util.RatioUtil;
	import custom.EnhancedPhoto;

	public class EnhancedMultipleFileUpload
	{
		
	/**
	 * ...
	 * @author Me^
	 */
		private const PROCESSING_WAITING_FOR_USER:String = 'Waiting for file selection';
		private const PROCESS_UPLOADING		:String = 'PROCESS_UPLOADING uploading autophoto image';
		
		private var btn_open			:InteractiveObject;
		private var model_bgs			:Model_Item;	
		private var _currentFileIndex	:Number = 0;
		private var _fileReferenceList	:FileReferenceList;
		private var _confirmUI			:EnhancedPhotoDesktopConfirm_UI;
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
		public function EnhancedMultipleFileUpload( _btn_open:InteractiveObject ) 
		{
			// listen for when the app is considered to have loaded and initialized all assets
			var loaded_event:String = App.mediator.EVENT_WORKSHOP_LOADED_EDITING_STATE;
			App.listener_manager.add(App.mediator, loaded_event, app_initialized, this);
			
			// reference to controllers UI
			btn_open		= _btn_open;
			
			// provide the mediator a reference to send data to this controller
			var registered:Boolean = App.mediator.register_controller(this);
			
			// calls made before the initialization starts
			
			_confirmUI = App.ws_art.enhanced_upload_confirm;
			_confirmUI.visible = false;
			
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
		{	App.listener_manager.add( btn_open, MouseEvent.CLICK, btn_handler, this );
			App.listener_manager.add( _confirmUI.btn_close, MouseEvent.CLICK, _onConfirmClose, this );
			init_file_ref();
		}
		
		private function _onConfirmClose(e:MouseEvent):void
		{
			_confirmUI.visible = false;
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
		private function btn_handler( _e:MouseEvent ):void
		{
			switch ( _e.target )
			{	
				case btn_open:	_upload();
			}
		}
		private function _upload():void
		{
			init_file_ref();
			
			if (Throttler.last_response_was_instant)
				build_request(true);
			else
			{
				_confirmUI.visible = true;
				_confirmUI.btn_continue.addEventListener(MouseEvent.CLICK, build_request);
			}
			
			function build_request(e:MouseEvent):void 
			{
				_confirmUI.visible = false;
				
				toggle_processing_on_waiting(true);
				_fileReferenceList.browse([_fileFilter,_fileFilter,_fileFilter,_fileFilter,_fileFilter,_fileFilter]);				
			}
						
		}
		private function init_file_ref(  ):void 
		{	
			_fileReferenceList  = new FileReferenceList();
			
			App.listener_manager.add( _fileReferenceList, Event.SELECT, _selectHandler, this );
			App.listener_manager.add( _fileReferenceList, Event.CANCEL, user_cancelled_upload, this );
			App.listener_manager.add( _fileReferenceList, IOErrorEvent.IO_ERROR, browse_io_error , this );			
		}
		
		private function _selectHandler(event:Event):void
		{
			
			_currentFileIndex = 0;
			_loadNextFile();	
		}		
		private function _loadNextFile():void
		{
			var file:FileReference = FileReference(_fileReferenceList.fileList[_currentFileIndex]);
			file.addEventListener ( Event.COMPLETE, _onDataLoaded ) ;
			file.load();
			
			function _onDataLoaded ( evt : Event ) : void
			{
				var tempFileRef : FileReference = FileReference ( evt.target ) ;
				var _loader:Loader = new Loader ( ) ;
				_loader.contentLoaderInfo.addEventListener ( Event.COMPLETE, _onImageLoaded ) ;
				_loader.loadBytes ( tempFileRef.data ) ;
			}
			
			function _onImageLoaded ( evt : Event ) : void
			{
				var _bitmap:Bitmap = ImageUtil.fitImageProportionally(Bitmap(evt.target.content ), 200, 200);
				var enhancedPhoto:EnhancedPhoto = new EnhancedPhoto(_bitmap);
				enhancedPhoto.addEventListener(Event.COMPLETE, onUploadComplete);
			}
			
			function onUploadComplete(e:Event):void
			{
				_currentFileIndex++;
				App.asset_bucket.enhancedPhotos.push((e.target as EnhancedPhoto));
				if(_currentFileIndex < _fileReferenceList.fileList.length) _loadNextFile();
				else {
					App.mediator.processing_ended( PROCESS_UPLOADING);
					toggle_processing_on_waiting(false);
					App.mediator.loadHouseParty();
				}
			}
			
		}
		private function user_cancelled_upload( _e:Event ):void
		{
			toggle_processing_on_waiting(false);
			//App.mediator.autophoto_open_mode_selector();
		}
		private function browse_io_error( _e:IOErrorEvent ):void 
		{
			App.utils.image_uploader.upload_failed();
			App.mediator.processing_ended( PROCESS_UPLOADING );
			App.mediator.alert_user(new AlertEvent(AlertEvent.ERROR, "fue003", "Error uploading file : "+_e.text,{details:_e.text}));
		}
		
		
		protected function get _fileFilter():FileFilter
		{
			return new FileFilter("Images (*.jpg, *.jpeg, *.gif, *.png)", "*.jpg;*.jpeg;*.gif;*.png");
		}
		private function toggle_processing_on_waiting( _start:Boolean ):void
		{
			var processing_text:String = App.asset_bucket.model_store.list_errors.get_error_text('f9t546', PROCESSING_WAITING_FOR_USER);
			if (_start)
				App.mediator.processing_start( processing_text, processing_text );
			else
				App.mediator.processing_ended( processing_text );
		}
		private function browse_multiple(  ):void
		{
			Throttler.autophoto_upload_allowed( upload_files, capacity_surpassed, capacity_surpassed );
			
			function upload_files(  ):void
			{
				if (Throttler.last_response_was_instant)
					build_request(true);
				else   
				{
					var alert:AlertEvent = new AlertEvent(AlertEvent.CONFIRM, 'f9t542', 'Click ok to continue', false, build_request);
					alert.report_error = false;
					App.mediator.alert_user( alert );
				}
				
				function build_request(_ok:Boolean):void 
				{
					if (_ok)
					{
						toggle_processing_on_waiting(true);
						Gateway.upload_fileReferenceList( new Callback_Struct( fin, null, error ), 6, null, user_cancelled );
					}
				}
				function fin( _gateway_results:Array ):void 
				{	
					toggle_processing_on_waiting(false);
					for (var n:int = _gateway_results.length, i:int = 0; i < n; i++)
					{
						var gr:Gateway_FileReference_Result = _gateway_results[i];
						var unique_id:int = --App.asset_bucket.bg_counter_id;
						var image:WSBackgroundStruct = new WSBackgroundStruct( gr.full_url, unique_id, gr.thumb_url );
						App.asset_bucket.enhancedPhotos.push(gr.full_url);
					
					}
					
					App.mediator.loadHouseParty();
				}
				function user_cancelled():void
				{
					toggle_processing_on_waiting(false);
				}
				function error( _error:Gateway_Error ):void
				{
					toggle_processing_on_waiting(false);
					App.mediator.alert_user( new AlertEvent( AlertEvent.ERROR, _error.error_code, _error.error_message, _error.error_text_params ));
				}
			}
			function capacity_surpassed(  ):void
			{
				App.mediator.alert_user( new AlertEvent(AlertEvent.ERROR, "", "Server capacity surpassed.  Please try again later."));
			}
		}
	}
}
