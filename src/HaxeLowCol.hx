using Lambda;

@:forward
abstract HaxeLowCol<T, K>(Array<T>) to Array<T> {
	inline public function new(array : Array<T>, keyField : String) {		
		this = array;
		if(keyField != null) Reflect.setField(this, '__haxeLowId', keyField);
	}

	public function idGet(id : K) : T {
		return this.find(function(o) return keyValue(o) == id);
	}

	/**
	 * Returns true if the object was inserted, false if not.
	 */
	public function idInsert(obj : T) : Bool {
		if (idGet(keyValue(obj)) == null) {
			this.push(obj);
			return true;
		}
			
		return false;
	}

	public function idUpdate(id : K, props : {}) : T {
		var exists = idGet(id);
		if(exists == null) return null;

		for(field in Type.getInstanceFields(Type.getClass(exists))) 
			if(Reflect.hasField(props, field))
				Reflect.setProperty(exists, field, Reflect.field(props, field));

		return exists;
	}

	/**
	 * Returns true if the object replaced another, false if it was inserted or existed already.
	 */
	public function idReplace(obj : T) : Bool {
		var exists = idGet(keyValue(obj));
		if (exists != null) {
			if (exists == obj) return false;
			this.remove(exists);
		}
		
		this.push(obj);
		return exists != null;
	}
	
	public function idRemove(id : K) : T {
		var exists = idGet(id);
		if(exists == null) return null;
		this.remove(exists);
		return exists;
	}
	
	inline function keyValue<T>(obj : T) return Reflect.field(obj, Reflect.field(this, '__haxeLowId'));
}
