import tjson.TJSON;

#if js
import js.Lib;
#end

using Lambda;

interface Disk {
	public function readFileSync(file : String) : String;
	public function writeFile(file : String, data : String) : Void;
}

#if js
class LocalStorageDisk implements Disk {
	public function new() {}

	public function readFileSync(file : String) 
		return js.Browser.getLocalStorage().getItem(file);

	public function writeFile(file : String, data : String)
		js.Browser.getLocalStorage().setItem(file, data);
}

class NodeJsDisk implements Disk {
	public function new() {}

	public function readFileSync(file : String) {
		var fs = Lib.require('fs');
		return fs.existsSync(file) ? fs.readFileSync(file, {encoding: 'utf8'}) : null;
	}

	public function writeFile(file : String, data : String) {
		Lib.require('steno').writeFile(file, data, function(_) {});
	}
}

class NodeJsDiskSync implements Disk {
	public function new() {}

	public function readFileSync(file : String) {
		var fs = Lib.require('fs');
		return fs.existsSync(file) ? fs.readFileSync(file, {encoding: 'utf8'}) : null;
	}

	public function writeFile(file : String, data : String) {
		Lib.require('steno').writeFileSync(file, data);
	}
}
#end

// Based on https://github.com/typicode/lowdb
class HaxeLow
{
	public static function uuid() {
		// Based on https://gist.github.com/LeverOne/1308368
	    var uid = new StringBuf(), a = 8;
        uid.add(StringTools.hex(Std.int(Date.now().getTime()), 8));
	    while((a++) < 36) {
	        uid.add(a*51 & 52 != 0
	            ? StringTools.hex(a^15 != 0 ? 8^Std.int(Math.random() * (a^20 != 0 ? 16 : 4)) : 4)
	            : "-"
	        );
	    }
	    return uid.toString().toLowerCase();
	}

	public var file(default, null) : String;

	var db : Dynamic;
	var checksum : String;
	var disk : Disk;

	public function new(?file : String, ?disk : Disk) {
		this.file = file;
		this.db = {};

		#if js
		// Node.js detection from http://stackoverflow.com/a/5197219/70894
		var isNode = untyped __js__("typeof module !== 'undefined' && module.exports");
		this.disk = (disk == null && file != null) 
			? (isNode ? new NodeJsDisk() : new LocalStorageDisk())
			: disk;
		#else
		this.disk = disk;
		#end

		if(this.file != null) {
			if(this.disk == null) throw 'HaxeLow: no disk storage set.';

			this.checksum = this.disk.readFileSync(this.file);
			if(this.checksum != null) try {
				this.db = TJSON.parse(checksum);
			} catch(e : Dynamic) {
				throw 'HaxeLow: JSON parsing failed: file "${this.file}" is corrupt.';
			}
		}
	}

	public function backup(?file : String) {
		var backup = TJSON.encode(db, 'fancy');
		if(file != null) disk.writeFile(file, backup);
		return backup;
	}
	
	public function restore(s : String) {
		db = TJSON.parse(s); 
		return this; 
	}

	public function save() : HaxeLow {
		if(file == null) return this;

		var data = backup();
		if(data == checksum) return this;

		checksum = data;
		disk.writeFile(file, data);

		return this;
	}

	public function col<T>(cls : Class<T>) : Array<T> {
		var name = Type.getClassName(cls);
		if(!Reflect.hasField(db, name)) {
			Reflect.setField(db, name, new Array<T>());
			save();
		}

		return cast Reflect.field(db, name);
	}

	public function idCol<T : HaxeLowId>(cls : Class<T>) : HaxeLowCollection<T> {
		return col(cls);
	}

	public function _idCol<T : HaxeLowdashId>(cls : Class<T>) : HaxeLowdashCollection<T> {
		return col(cls);
	}
}

typedef HaxeLowId = {
	public var id : String;
}

@:forward
abstract HaxeLowCollection<T : HaxeLowId>(Array<T>) from Array<T> to Array<T> {
	inline public function new(array : Array<T>) {
		this = array;
	}

	public function idGet(id : String) : T {
		return this.find(function(o) return o.id == id);
	}

	public function idInsert(obj : T) : T {
		if(obj.id != null) {
			var exists = idGet(obj.id);
			if(exists != null) {
				this[this.indexOf(exists)] = obj;
				return obj;
			}
		} else {
			obj.id = HaxeLow.uuid();
		}

		this.push(obj);
		return obj;
	}

	public function idUpdate(id : String, props : {}) : T {
		var exists = idGet(id);
		if(exists == null) return null;

		for(field in Type.getInstanceFields(Type.getClass(exists))) 
			if(Reflect.hasField(props, field))
				Reflect.setProperty(exists, field, Reflect.field(props, field));

		return exists;
	}

	public function idRemove(id : String) : T {
		var exists = idGet(id);
		if(exists == null) return null;
		this.remove(exists);
		return exists;
	}
}

///// Do not edit: Copy the above class and change only <T : HaxeLowId> to <T : HaxeLowdashId> /////

typedef HaxeLowdashId = {
	public var _id : String;
}

@:forward
abstract HaxeLowdashCollection<T : HaxeLowdashId>(Array<T>) from Array<T> to Array<T> {
	inline public function new(array : Array<T>) {
		this = array;
	}

	public function idGet(id : String) : T {
		return this.find(function(o) return o._id == id);
	}

	public function idInsert(obj : T) : T {
		if(obj._id != null) {
			var exists = idGet(obj._id);
			if(exists != null) {
				this[this.indexOf(exists)] = obj;
				return obj;
			}
		} else {
			obj._id = HaxeLow.uuid();		
		}

		this.push(obj);
		return obj;
	}

	public function idUpdate(id : String, props : {}) : T {
		var exists = idGet(id);
		if(exists == null) return null;

		for(field in Type.getInstanceFields(Type.getClass(exists))) 
			if(Reflect.hasField(props, field))
				Reflect.setProperty(exists, field, Reflect.field(props, field));

		return exists;
	}

	public function idRemove(id : String) : T {
		var exists = idGet(id);
		if(exists == null) return null;
		this.remove(exists);
		return exists;
	}
}
