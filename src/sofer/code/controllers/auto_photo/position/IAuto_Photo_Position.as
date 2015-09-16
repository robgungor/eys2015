package code.controllers.auto_photo.position 
{
	import code.controllers.auto_photo.IAuto_Photo_Win;
	
	/**
	 * ...
	 * @author Me^
	 */
	//public interface IAuto_Photo_Position extends IAuto_Photo_Win
	public interface IAuto_Photo_Position
	{
		function open_win(_action:String=null):void;
		function close_win():void;
	}
	
}