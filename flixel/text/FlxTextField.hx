package flixel.text;

import flash.display.BitmapData;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;
import flash.text.TextFormatAlign;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import flixel.util.FlxPoint;
import openfl.Assets;

/**
 * Extends <code>FlxText</code> for better support rendering text on cpp target.
 * Doesn't have multicamera support.
 * Displays over all other objects.
 */
class FlxTextField extends FlxText
{
	private var _camera:FlxCamera;
	private var _addedToDisplay:Bool = false;
	
	/**
	 * Creates a new <code>FlxText</code> object at the specified position.
	 * @param	X				The X position of the text.
	 * @param	Y				The Y position of the text.
	 * @param	Width			The width of the text object (height is determined automatically).
	 * @param	Text			The actual text you would like to display initially.
	 * @param	EmbeddedFont	Whether this text field uses embedded fonts or not
	 * @param	Camera			Camera to display. FlxG.camera is used by default (if you pass null)
	 */
	public function new(X:Float, Y:Float, Width:Int, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true, ?Camera:FlxCamera)
	{
		super(X, Y, Width, Text, Size, EmbeddedFont);
		
		height = (Text.length <= 0) ? 1 : 10;
		
		_textField.multiline = false;
		_textField.wordWrap = false;
		
		if (Camera == null)
		{
			Camera = FlxG.camera;
		}
		
		_camera = Camera;
		_regen = dirty = false;
	}
	
	/**
	 * Clean up memory.
	 */
	override public function destroy():Void
	{
		if (_textField.parent != null)
		{
			_textField.parent.removeChild(_textField);
		}
		
		_camera = null;
		super.destroy();
	}
	
	override public function stamp(Brush:FlxSprite, X:Int = 0, Y:Int = 0):Void 
	{
		// This class doesn't support this operation
	}
	
	override public function pixelsOverlapPoint(point:FlxPoint, Mask:Int = 0xFF, ?Camera:FlxCamera):Bool
	{
		// This class doesn't support this operation
		return false;
	}
	
	override private function simpleRenderSprite():Bool
	{
		// This class doesn't support this operation
		return true;
	}
	
	/**
	 * Set <code>pixels</code> to any <code>BitmapData</code> object.
	 * Automatically adjust graphic size and render helpers.
	 */
	override private function get_pixels():BitmapData
	{
		#if !(flash || bitfive)
		calcFrame(true);
		#else
		calcFrame();
		#end
		return cachedGraphics.bitmap;
	}
	
	override private function set_pixels(Pixels:BitmapData):BitmapData
	{
		// This class doesn't support this operation
		return Pixels;
	}
	
	override private function set_alpha(Alpha:Float):Float
	{
		if (Alpha > 1)
		{
			Alpha = 1;
		}
		if (Alpha < 0)
		{
			Alpha = 0;
		}
		
		alpha = Alpha;
		_textField.alpha = alpha;
		
		return Alpha;
	}
	
	override private function set_height(Height:Float):Float
	{
		Height = super.set_height(Height);
		if (_textField != null)	_textField.height = Height;
		return Height;
	}
	
	override private function set_visible(Value:Bool):Bool
	{
		_textField.visible = Value;
		return super.set_visible(Value);
	}
	
	override public function kill():Void 
	{
		visible = false;
		super.kill();
	}
	
	override public function revive():Void 
	{
		visible = true;
		super.revive();
	}
	
	/**
	 * Called by game loop, updates then blits or renders current frame of animation to the screen
	 */
	override public function draw():Void
	{
		if (_camera == null)	
		{
			return;
		}
		
		if (!_addedToDisplay)
		{
			#if !(flash || bitfive)
			_camera._canvas.addChild(_textField);
			#else
			_camera._flashSprite.addChild(_textField);
			#end
			
			_addedToDisplay = true;
			updateFormat(_format);
		}
		
		if (!_camera.visible || !_camera.exists || !onScreen(_camera))
		{
			_textField.visible = false;
		}
		else
		{
			_textField.visible = true;
		}
		
		_point.x = x - (_camera.scroll.x * scrollFactor.x) - (offset.x);
		_point.y = y - (_camera.scroll.y * scrollFactor.y) - (offset.y);
		
		#if !flash
		_textField.x = _point.x;
		_textField.y = _point.y;
		#else
		_textField.x = _point.x - FlxG.camera.width * 0.5;
		_textField.y = _point.y - FlxG.camera.height * 0.5;
		#end
		
		#if !FLX_NO_DEBUG
		FlxBasic._VISIBLECOUNT++;
		#end
	}
	
	override private function regenGraphics():Void
	{
		if (_regen)
		{
			var key:String = cachedGraphics.key;
			FlxG.bitmap.remove(key);
			
			makeGraphic(Std.int(width + _widthInc), Std.int(height + _heightInc), FlxColor.TRANSPARENT, false, key);
			frameHeight = Std.int(height);
			_flashRect.x = 0;
			_flashRect.y = 0;
			_flashRect.width = width + _widthInc;
			_flashRect.height = height + _heightInc;
			_regen = false;
		}
		// Else just clear the old buffer before redrawing the text
		else
		{
			cachedGraphics.bitmap.fillRect(_flashRect, FlxColor.TRANSPARENT);
		}
	}
	
	/**
	 * Camera on which this text will be displayed. Default is FlxG.camera.
	 */
	public var camera(get, set):FlxCamera;
	
	private function get_camera():FlxCamera 
	{
		return _camera;
	}
	
	private function set_camera(Value:FlxCamera):FlxCamera 
	{
		if (_camera != Value)
		{
			if (Value != null)
			{
				#if !(flash || bitfive)
				Value._canvas.addChild(_textField);
				#else
				Value._flashSprite.addChild(_textField);
				#end
				
				_addedToDisplay = true;
			}
			else
			{
				if (_camera != null)
				{
					_textField.parent.removeChild(_textField);
				}
				
				_addedToDisplay = false;
			}
			
			_camera = Value;
		}
		return Value;
	}
	
	public var textField(get, never):TextField;
	
	private function get_textField():TextField 
	{
		return _textField;
	}
}