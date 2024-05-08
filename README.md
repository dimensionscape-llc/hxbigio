# HxBigIO
This library is intended to enable the handling of large buffers and files with lengths measured in the Int64 range.

### Requirements

- HXCPP 4.0.0+ Recommended 
- Haxe 4.0.0+ Recommended
- Requires 64-bit build
  - *HXCPP_M64*

 
***Note: This works only on Native Windows at the moment***

### Usage

#### BigBytes

##### **Load File Content (Bytes)**
```hx
var file:BigBytes = BigBytes.fromFile("<your-file-path>");
```

##### **Save file Content (Bytes)**
```hx
BigBytes.toFile("<your-file-path>", file);
```

##### **Large Allocation**
```hx
var bytes:BigBytes = new BigBytes(Int64.fromFloat(5073741824));
```

*Readme in progress!*

