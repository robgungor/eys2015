﻿package custom
{
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import code.skeleton.App;

	public class BandwidthTester extends EventDispatcher
	{
		public var URL:String;
		public var debug:Boolean = false;
		private var _speed:Number;
		private var _startTime:Number;
		private var _loader:Loader;

		public function BandwidthTester( testFileLocation:String ):void{
			URL = testFileLocation;
		}

		public function get speed( ):Number{ return _speed; }

		public function start( ):void{
			URL += "?" + ( Math.random( ) * 100000 );
			_startTime = ( new Date( ) ).getTime( );

			_loader = new Loader( );
			_loader.contentLoaderInfo.addEventListener( Event.COMPLETE, downloadComplete );
			_loader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, ioErrorHandler );
			_loader.load( new URLRequest( URL ) );
		}

		public function downloadComplete( e:Event ):void
		{
			var endTime:Number = ( new Date( ) ).getTime( );
			var totalTime:Number = ( endTime - _startTime ) / 1000;
			var totalKB:Number = e.currentTarget.bytesTotal / 1024;
			_speed = totalKB / totalTime;
			
			if( debug ){
				App.mediator.doTrace( "total time: " + totalTime + " total KB: " + totalKB + " speed: " + speed + "KBps" );
			}

			dispatchEvent( e );
		}

		public function ioErrorHandler( e:IOErrorEvent ):void
		{
			_speed = -1;
			trace( "URL not found" );
		}
	}
}