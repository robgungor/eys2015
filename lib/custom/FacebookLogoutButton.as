package custom
{
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.text.TextField;
	
	public class FacebookLogoutButton extends MovieClip
	{
		public var inner:MovieClip;
		public var btn:SimpleButton;
		public function FacebookLogoutButton()
		{
			super();
			_init();
		}
		protected function _init():void
		{
			this.addEventListener(MouseEvent.ROLL_OVER, _onOver);
			this.addEventListener(MouseEvent.ROLL_OUT, _onOut);
			this.mouseChildren = false;
			this.buttonMode = true;
		}
		protected function _onOver(e:MouseEvent):void
		{
			var myColorTransform = new ColorTransform();
			myColorTransform.color = 0xAAEEFF;
			inner.transform.colorTransform = myColorTransform;
		}
		protected function _onOut(e:MouseEvent):void
		{
			inner.transform.colorTransform = new ColorTransform();
		}
		public function setName(val:String):void
		{
			inner.tf_name.text = val;
			inner.tf_name.width = inner.tf_name.textWidth+5;
			inner.underline.width = (inner.tf_name.x-2)+inner.tf_name.textWidth+5;
		}
	}
}