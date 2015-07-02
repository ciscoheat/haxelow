# HaxeLow

A Haxe port of [lowdb](https://github.com/typicode/lowdb) which is a flat JSON file database. It is tested to work when targeting javascript, but may work elsewhere too.

## How to use

If you're on Node.js or in the browser, you can use HaxeLow straight out-of-the-box:

```haxe
class Person {
	public function new(name, age) {
		this.name = name; this.age = age;
	}

	public var name : String;
	public var age : Int;
}

class Main {
	static function main() {
		// Create the database
		var db = new HaxeLow('db.json');

		// Get a collection of a class
		var persons = db.col(Person);

		// persons is now an Array<Person>
		// that can be manipulated as you like
		persons.push(new Person("Test", 50));

		// Save all collections to disk.
		// This is the only way to save, no automatic saving
		// takes place.
		db.save();
	}
}
```

This is nice and simple, but wait, there's more! You can use any field in your class as an ID field:

```haxe
class Person {
	public function new(name, age) {
		this.name = name; this.age = age;
	}

	// Easy way to generate a v4 UUID:
	public var id : String = HaxeLow.uuid();
	public var name : String;
	public var age : Int;
}

class Main {
	static function main() {
		var db = new HaxeLow('db.json');

		// If your id field is named id, use idCol instead of col:
		var persons = db.idCol(Person);

		// And you have some useful 'id' methods on the collection
		// (it still works as an array too)
		persons.idInsert(new Person("Test", 45)); // returns true
		
		// Inserting person with same id will return false
		persons.idInsert(person); // false
		
		var id = person.id;

		var samePerson = persons.idGet(id);
		samePerson.idUpdate(id, { age: 46 });

		// idReplace will replace if same id, insert otherwise
		var anotherPerson = new Person("Test2", 40);
		anotherPerson.id = person.id;
		persons.idReplace(anotherPerson); // true
		
		// Remember to save!
		db.save();
	}
}
```

If your id field is named `_id`, use the method `db._idCol(Person)`, or you can use `db.keyCol(Person, idFieldName)` for any field.

## When to use HaxeLow

Straight from the lowdb docs:

HaxeLow is a convenient method for storing data without setting up a database server. It's fast enough and safe to be used as an embedded database.

However, if you need high performance and scalability more than simplicity, you should stick to databases like MongoDB.

## API reference

`var db = new HaxeLow(?filename : String)` - Creates the HaxeLow database. If no filename is specified, an in-memory DB is created.

`HaxeLow.uuid()` - Generates a v4 UUID where the first four bytes are the timestamp, so the generated id's can be sorted easily.

`db.col<T>(cls : Class<T>)` - Returns an `Array<T>` for a class.

`db.idCol<T, K>(cls : Class<T>, ?keyType : Class<K>)` - Returns an `Array<T>` with extra id methods, for classes with an `id : K` field.

`db._idCol<T, K>(cls : Class<T>, ?keyType : Class<K>)` - Returns an `Array<T>` with extra id methods, for classes with an `_id : K` field.

`db.keyCol<T, K>(cls : Class<T>, keyField : String, ?keyType : Class<K>)` - Returns an `Array<T>` with extra id methods, for any `keyField : K` that exists on a class.

`db.backup(?file : String)` - Returns the DB as a JSON `String`. If `file` is specified, the DB is saved to that file.

`db.restore(s : String)` - Restores the DB based on a JSON `String`, but as with other operations, does not save the DB automatically.

`db.save()` - Saves the DB to disk. (Does nothing for in-memory DB's)

`db.file` - Filename for the current DB.

## Making it work on other targets than js

The ways to store the DB varies a lot between platforms, so the only real solution is to let people implement their own disk storage. HaxeLow uses a simple interface for that, `HaxeLow.Disk`:

```haxe
interface Disk {
	// Read a file synchronously and return its contents.
	public function readFileSync(file : String) : String;

	// Write to a file async or sync, it's up to you.
	public function writeFile(file : String, data : String) : Void;
}
```

When you have implemented this interface, just pass an instance of the implemented class as the second argument to `HaxeLow`:

```haxe
class Main {
	static function main() {
		var db = new HaxeLow('db.json', new YourDiskInterface());
	}
}
```

As mentioned, there is built-in support for Node.js (which requires the [steno](https://www.npmjs.com/package/steno) npm package) and for the browser, which uses [localStorage](https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API). [Check the source](https://github.com/ciscoheat/haxelow/blob/master/src/HaxeLow.hx) for the implementations, it's not much code.

## Installation

`haxelib install haxelow`, then put `-lib haxelow` in your `.hxml` file.

## Credits

HaxeLow uses [TJSON](https://github.com/martamius/TJSON), the tolerant JSON parser for Haxe.

Thanks to the lowdb authors for the original idea!
