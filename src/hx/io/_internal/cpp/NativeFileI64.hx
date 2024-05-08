package hx.io._internal.cpp;
import cpp.Int64;
import hx.io._internal.cpp.impl.FileI64Impl;

/**
 * ...
 * @author Christopher Speciale
 */
@:access(hx.io._internal.cpp.impl.FileI64Impl)
class NativeFileI64 
{
	public static function file_get_content_bytes(path:String):Array<Dynamic>{
		return FileI64Impl._file_get_content_bytes(path);
	}
	
}