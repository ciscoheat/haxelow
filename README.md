# HaxeLow

A Haxe port of [lowdb](https://github.com/typicode/lowdb) which is a flat JSON file database.

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

This is nice and simple, but if your class contains the field `var id : String` or `var _id : String` it gets better:

```haxe
class Person {
	public function new(name, age) {
		this.name = name; this.age = age;
	}

	public var id : String;
	public var name : String;
	public var age : Int;
}

class Main {
	static function main() {
		var db = new HaxeLow('db.json');

		// Use idCol instead of col:
		var persons = db.idCol(Person);

		// And you have some useful 'id' methods on the collection
		// (it still works as an array too)
		var person = persons.idInsert(new Person("Test", "45"));

		// A v4 UUID has been generated for the id
		var id = person.id;

		var samePerson = persons.idGet(id);
		persons.idUpdate(id, { age: 46 });
		var stillSame = persons.idRemove(id);

		// Remember to save! (empty db in this case)
		db.save();
	}
}
```

If your id field is named `_id`, use the method `db._idCol(Person)` instead.

## API reference

`HaxeLow.uuid()` - Generates a v4 UUID where the first four bytes are the timestamp, so they can be sorted quite easily.

`db.col<T>(cls : Class<T>)` - Returns an `Array<T>` for a class.

`db.idCol<T>(cls : Class<T>)` - Returns an `Array<T>` with extra id methods, for classes with an `id : String` field.

`db._idCol<T>(cls : Class<T>)` - Returns an `Array<T>` with extra id methods, for classes with an `_id : String` field.

`db.backup(?file : String)` - Returns the DB as a JSON `String`. If `file` is specified, the DB is saved to that file.

`db.restore(s : String)` - Restores the DB based on a JSON `String`, but as with other operations, does not save the DB automatically.

`db.save()` - Saves the DB to disk.

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

Thanks to the lowdb authors for the idea.
