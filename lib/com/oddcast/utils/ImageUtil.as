package com.oddcast.utils
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.PixelSnapping;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	public class ImageUtil
	{
		public function ImageUtil()
		{
		}
		/**
		 * fitImage
		 * @ARG_object   the display object to work with
		 * @ARG_width    width of the box to fit the image into
		 * @ARG_height   height of the box to fit the image into
		 * @ARG_center   should it offset to center the result in the box
		 * @ARG_fillBox  should it fill the box, may crop the image (true), or fit the whole image within the bounds (false)
		 **/
		public static function fitImageProportionally( ARG_object:DisplayObject, ARG_width:Number, ARG_height:Number, ARG_center:Boolean = true, ARG_fillBox:Boolean = true ):Bitmap {
			
			var tempW:Number = ARG_object.width;
			var tempH:Number = ARG_object.height;
			
			ARG_object.width = ARG_width;
			ARG_object.height = ARG_height;
			
			var scale:Number = (ARG_fillBox) ? Math.max(ARG_object.scaleX, ARG_object.scaleY) : Math.min(ARG_object.scaleX, ARG_object.scaleY);
			
			ARG_object.width = tempW;
			ARG_object.height = tempH;
			
			var scaleBmpd:BitmapData = new BitmapData(ARG_object.width * scale, ARG_object.height * scale);
			var scaledBitmap:Bitmap = new Bitmap(scaleBmpd, PixelSnapping.ALWAYS, true);
			var scaleMatrix:Matrix = new Matrix();
			scaleMatrix.scale(scale, scale);
			scaleBmpd.draw( ARG_object, scaleMatrix );
			
			if (scaledBitmap.width > ARG_width || scaledBitmap.height > ARG_height) {
				
				var cropMatrix:Matrix = new Matrix();
				var cropArea:Rectangle = new Rectangle(0, 0, ARG_width, ARG_height);
				
				var croppedBmpd:BitmapData = new BitmapData(ARG_width, ARG_height);
				var croppedBitmap:Bitmap = new Bitmap(croppedBmpd, PixelSnapping.ALWAYS, true);
				
				if (ARG_center) {
					var offsetX:Number = Math.abs((ARG_width -scaleBmpd.width) / 2);
					var offsetY:Number = Math.abs((ARG_height - scaleBmpd.height) / 2);
					
					cropMatrix.translate(-offsetX, -offsetY);
				}
				
				croppedBmpd.draw( scaledBitmap, cropMatrix, null, null, cropArea, true );
				return croppedBitmap;
				
			} else {
				return scaledBitmap;
			}
			
		}
		/**
		 * scaleBitmap
		 * @ARG_object   the display object to scale
		 * @ARG_scaleX   the amount to scale horizontally (1 = no scale)
		 * @ARG_scaleY   the amount to scale vertically (1 = no scale)
		 **/
		public static function scaleBitmap( ARG_object:DisplayObject, ARG_scaleX:Number, ARG_scaleY:Number ):Bitmap {
			// create a BitmapData object the size of the crop
			var bmpd:BitmapData = new BitmapData(ARG_object.width * ARG_scaleX, ARG_object.height * ARG_scaleY);
			// create the scaled Bitmap object from the BitmapData
			var scaledBitmap:Bitmap = new Bitmap(bmpd, PixelSnapping.ALWAYS, true);
			// create the matrix that will perform the scaling
			var scaleMatrix:Matrix = new Matrix();
			scaleMatrix.scale(ARG_scaleX, ARG_scaleY);
			// draw the object to the BitmapData, applying the matrix to scale
			bmpd.draw( ARG_object, scaleMatrix );
			return scaledBitmap; // return the scaled Bitmap
		}
		
		/**
		 * cropBitmap
		 * @ARG_object   the display object to crop
		 * @ARG_x        the horizontal amount to shift the crop (0 = no shift)
		 * @ARG_y        the vertical amount to shift the crop (0 = no shift)
		 * @ARG_width    width to crop to
		 * @ARG_height   height to crop to
		 **/
		public static function cropBitmap( ARG_object:DisplayObject, ARG_x:Number, ARG_y:Number, ARG_width:Number, ARG_height:Number):Bitmap {
			// create a rectangle of the specific crop size
			var cropArea:Rectangle = new Rectangle(0, 0, ARG_width, ARG_height);
			// create a BitmapData object the size of the crop
			var bmpd:BitmapData = new BitmapData(ARG_width, ARG_height);
			// create the cropped Bitmap object from the bitmap data
			var croppedBitmap:Bitmap = new Bitmap(bmpd, PixelSnapping.ALWAYS, true);
			// create the matrix that will shift the crop from 0,0
			var cropMatrix:Matrix = new Matrix();
			cropMatrix.translate(-ARG_x, -ARG_y);
			// draw the supplied object, cropping to the cropArea with the cropMatrix offseting the result
			bmpd.draw( ARG_object, cropMatrix, null, null, cropArea, true );
			return croppedBitmap; // return the cropped bitmap
		}
	}
}