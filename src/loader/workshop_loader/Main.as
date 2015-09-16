﻿package workshop_loader 
{
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.system.*;
	import flash.text.*;
	
	/**
	 * TROUBLESHOOT:
	 * 1 check the workshop_art url that this is loading is correct
	 * 2 remove wmode from embed code
	 * 3 references to stage have to be made once the Event.ADDED_TO_STAGE is fired inside the child
	 * 4 check that allowDomain is set up correctly in the shell as well as children
	 * @author Me^
	 */
	public class Main extends MovieClip
	{
		private var loader:Loader = new Loader();
		public var tf_loaded:TextField;
		
		public function Main() 
		{
			Security.allowDomain('*');
			loader.load( new URLRequest( workshop_url() ) );
			loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS			, update_loader);
			loader.contentLoaderInfo.addEventListener(Event.INIT						, workshop_loaded );
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR				, error		);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.NETWORK_ERROR		, error		);
			loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR	, error		);
			loader.contentLoaderInfo.addEventListener(HTTPStatusEvent.HTTP_STATUS		, http_status);
			tf_loaded.text = '';
		}
		
		private function error( _e:Event ):void
		{
			tf_loaded.text = 'Error loading application, please refresh the browser.';
		}
		
		/**
		 * needed to catch events when the network is diconnected
		 * @param	_e
		 */
		private function http_status( _e:HTTPStatusEvent ):void
		{}
		
		private function update_loader( _e:ProgressEvent ):void 
		{
			var percent:int = (_e.bytesLoaded * 100) / _e.bytesTotal;
			tf_loaded.text = 'downloading application ' + percent.toString();
		}
		
		private function workshop_loaded( _e:Event ):void 
		{
			loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, update_loader);
			loader.contentLoaderInfo.removeEventListener(Event.INIT, workshop_loaded );
			addChild(loader);
			tf_loaded.visible = false;
		}
		
		private function workshop_url(  ):String
		{
			var mId:Number			= parseFloat(loaderInfo.parameters.mId);
			var mId_query:String	= (isNaN(mId) ? '' : '&mId=' + mId);
			var dId_query:String	= loaderInfo.parameters.dId ? '&dId='+loaderInfo.parameters.dId  : '';	// distribution id
			var demo_query:String	= loaderInfo.parameters.demo ? '&demo='+loaderInfo.parameters.demo  : '';	// demo id
			var stem_query:String	= '?stem=' + loaderInfo.parameters.stem;	// stem xml for getWorkshopInfo
			var full_query:String	= stem_query + mId_query + dId_query+demo_query;	// full query
			
			var shell_filename:String = loaderInfo.url.split('.swf')[0];
			var last_slash:int = shell_filename.lastIndexOf('/');
			var shell_folder:String = shell_filename.substr(0, last_slash) + '/';	// same folder as the loader
			
			var full_url:String = shell_folder + 'editor_art.swf' + full_query;
			return full_url;
		}
		
	}
	
}