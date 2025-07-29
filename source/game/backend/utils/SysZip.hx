package game.backend.utils;

#if sys
import haxe.io.Input;
import haxe.zip.Entry;
import haxe.zip.Reader;
import sys.io.File;
import sys.io.FileInput;
import haxe.zip.InflateImpl;

/**
 * Class that extends Reader allowing you to load ZIP entries without blowing your RAM up!!
 * Half of the code is taken from haxe libraries btw
 */
class SysZip extends Reader {
	var input:Input;
	var fileInput:FileInput;

	public var entries:List<SysZipEntry>;

	/**
	 * Opens a zip from a specified path.
	 * @param path Path to the zip file.
	 */
	public static function openFromFile(path:String) {
		return new SysZip(File.read(path, true));
	}

	/**
	 * Creates a new SysZip from a specified file input.
	 * @param input File input.
	 */
	public function new(input:FileInput) {
		super(fileInput = input);
	}

	/**
	 * Reads all the data present in a specified entry.
	 * NOTE: If the entry is compressed, the data won't be decompressed. For decompression, use `unzipEntry`.
	 * @param e Entry
	 */
	public function readEntryData(e:SysZipEntry) {
		var bytes:haxe.io.Bytes = null;
		var buf = null;
		var tmp = null;

		fileInput.seek(e.seekPos, SeekBegin);
		if (e.crc32 == null) {
			if (e.compressed) {
				#if neko
				// enter progressive mode : we use a different input which has
				// a temporary buffer, this is necessary since we have to uncompress
				// progressively, and after that we might have pending read data
				// that needs to be processed
				var bufSize = 65536;
				if (buf == null) {
					buf = new haxe.io.BufferInput(i, haxe.io.Bytes.alloc(bufSize));
					tmp = haxe.io.Bytes.alloc(bufSize);
					i = buf;
				}
				var out = new haxe.io.BytesBuffer();
				var z = new neko.zip.Uncompress(-15);
				z.setFlushMode(neko.zip.Flush.SYNC);
				while (true) {
					if (buf.available == 0)
						buf.refill();
					var p = bufSize - buf.available;
					if (p != buf.pos) {
						// because of lack of "srcLen" in zip api, we need to always be stuck to the buffer end
						buf.buf.blit(p, buf.buf, buf.pos, buf.available);
						buf.pos = p;
					}
					var r = z.execute(buf.buf, buf.pos, tmp, 0);
					out.addBytes(tmp, 0, r.write);
					buf.pos += r.read;
					buf.available -= r.read;
					if (r.done)
						break;
				}
				bytes = out.getBytes();
				#else
				var bufSize = 65536;
				if (tmp == null)
					tmp = haxe.io.Bytes.alloc(bufSize);
				var out = new haxe.io.BytesBuffer();
				var z = new InflateImpl(i, false, false);
				while (true) {
					var n = z.readBytes(tmp, 0, bufSize);
					out.addBytes(tmp, 0, n);
					if (n < bufSize)
						break;
				}
				bytes = out.getBytes();
				#end
			} else
				bytes = i.read(e.dataSize);
			e.crc32 = i.readInt32();
			if (e.crc32 == 0x08074b50)
				e.crc32 = i.readInt32();
			e.dataSize = i.readInt32();
			e.fileSize = i.readInt32();
			// set data to uncompressed
			e.dataSize = e.fileSize;
			e.compressed = false;
		} else
			bytes = i.read(e.dataSize);
		return bytes;
	}

	/**
	 * Unzips and returns all of the data present in an entry.
	 * @param f Entry to read from.
	 */
	public function unzipEntry(f:SysZipEntry) {
		var data = readEntryData(f);

		if (!f.compressed)
			return data;
		var c = new haxe.zip.Uncompress(-15);
		var s = haxe.io.Bytes.alloc(f.fileSize);
		var r = c.execute(data, 0, s, 0);
		c.close();
		if (!r.done || r.read != data.length || r.write != f.fileSize)
			throw "Invalid compressed data for " + f.fileName;
		data = s;
		return data;
	}

	public override function readEntryHeader():Entry {
		var i = this.i;
		var h = i.readInt32();
		// trace(StringTools.hex(h));
		if (h == 0x02014B50 || h == 0x06054B50)
			return null;
		if (h != 0x04034B50)
			throw "Invalid Zip Data";
		var version = i.readUInt16();
		var flags = i.readUInt16();
		var utf8 = flags & 0x800 != 0;
		if ((flags & 0xF7F1) != 0)
			throw "Unsupported flags " + flags;
		var compression = i.readUInt16();
		var compressed = (compression != 0);
		if (compressed && compression != 8)
			throw "Unsupported compression " + compression;
		var mtime = readZipDate();
		var crc32:Null<Int> = i.readInt32();
		var csize = i.readInt32();
		var usize = i.readInt32();
		var fnamelen = i.readInt16();
		var elen = i.readInt16();
		var fname = i.readString(fnamelen, UTF8);
		var fields = readExtraFields(elen);
		if (utf8)
			fields.push(FUtf8);
		var data = null;
		// we have a data descriptor that store the real crc/sizes
		// after the compressed data, let's wait for it
		if ((flags & 8) != 0)
			crc32 = null;
		return {
			fileName: fname,
			fileSize: usize,
			fileTime: mtime,
			compressed: compressed,
			dataSize: csize,
			data: data,
			crc32: crc32,
			extraFields: fields,
		};
	}


	public override function read():List<Entry> {
		if (entries != null)
			return entries;
		entries = new List();
		var e;
		while (true) {
			e = readEntryHeader();
			if (e == null)
				break;

			// trace(e.fileName);
			// trace(e.data);
			var zipEntry:SysZipEntry = cast e;
			zipEntry.seekPos = fileInput.tell();
			entries.add(zipEntry);
			fileInput.seek(e.dataSize, SeekCur);
		}
		return entries;
	}

	public function dispose() {
		if (input != null)
			input.close();
	}
}

typedef SysZipEntry = {
	> Entry,
	var seekPos:Int;
}
#end