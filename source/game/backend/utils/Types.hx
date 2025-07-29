package game.backend.utils;

typedef Byte = #if cpp cpp.Int8 #elseif cs cs.Int8 #elseif java java.Int8 #else Int #end;
typedef Short = #if cpp cpp.Int16 #elseif cs cs.Int16 #elseif java java.Int16 #else Int #end;
typedef Int32 = #if cpp cpp.Int32 #else Int #end;
typedef Long = #if cpp cpp.Int64 #elseif cs cs.Int64 #elseif java java.Int64 #elseif hl hl.I64 #else Int #end;

typedef UByte = #if cpp cpp.UInt8 #elseif cs cs.UInt8 #elseif hl hl.UI8 #else Int #end;
typedef UShort = #if cpp cpp.UInt16 #elseif cs cs.UInt16 #elseif hl hl.UI16 #else Int #end;
typedef UInt32 = #if cpp cpp.UInt32 #else Int #end;
typedef ULong = #if cpp cpp.UInt64 #else Int #end;

typedef Float32 = #if cpp cpp.Float32 #elseif hl hl.F32 #else Float #end;
typedef Double = #if cpp cpp.Float64 #elseif hl hl.F64 #else Float #end;

#if (!java && !cs && !hl && !cpp)
typedef Single = Float;
#end