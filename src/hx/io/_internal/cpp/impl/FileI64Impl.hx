package hx.io._internal.cpp.impl;
import cpp.UInt8;
import cpp.Int64;

/**
 * ...
 * @author Christopher Speciale
 */
@:include('./FileI64Impl.cpp')
extern class FileI64Impl 
{
	@:native("file_contents_big_bytes")
	extern private static function _file_get_content_bytes(path:String):Array<Dynamic>;
	
	
}