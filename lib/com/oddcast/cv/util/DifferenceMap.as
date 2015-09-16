﻿/* *   simply returns the difference between successive frames  *  */package com.oddcast.cv.util//import com.oddcast.cv.util.DifferenceMap;{	import flash.display.BitmapData;	import flash.display.BlendMode;		public class DifferenceMap	{				public function DifferenceMap(){}				public function findDifference(thisFrame:BitmapData):BitmapData {			var ret:BitmapData;			if (lastFrame != null &&				lastFrame.width == thisFrame.width &&				lastFrame.height == thisFrame.height) {				ret = thisFrame.clone();				ret.draw(lastFrame, null, null, BlendMode.DIFFERENCE, null, false);			}else {				if (lastFrame)					trace(lastFrame.width + " " + thisFrame.width + " " + lastFrame.height + " " + thisFrame.height );				ret = new BitmapData(thisFrame.width, thisFrame.height, thisFrame.transparent, 0xFF000000);			}				lastFrame = thisFrame.clone();			return ret;		}		private var lastFrame:BitmapData;	}}