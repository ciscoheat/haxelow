# HaxeLow

A Haxe port of [lowdb](https://github.com/typicode/lowdb) which is a flat JSON file database.

## How to use

`haxelib install haxelow`, then put `-lib haxelow` in your `.hxml` file.

**For Node.js:** Define `-D nodejs` or use `-lib hxnodejs`. The npm packages `steno` and `graceful-fs` are required.

**In the browser, or for `Sys` targets:** It works straight out-of-the-box.

## Example

```haxe
class Person {
	public function new(name, birth) {
		this.name = name; this.birth = birth;
	}

	public var name : String;
	public var birth : Int;
}

class Main {
	static function main() {
		// Create the database
		var db = new HaxeLow('db.json');

		// Get a collection of a class
		var persons = db.col(Person);

		// persons is now an Array<Person>
		// that can be manipulated as you like
		persons.push(new Person("Test", 1977));

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
    public function new(name, birth) {
        this.name = name; this.birth = birth;
    }

    // Easy way to generate a v4 UUID:
    public var id : String = HaxeLow.uuid();
    public var name : String;
    public var birth : Int;
}

class Main {
    static function main() {
        var db = new HaxeLow('db.json');

        // If your id field is named id, use idCol instead of col:
        var persons = db.idCol(Person);

        var person = new Person("Test", 1978);

        // And you have some useful 'id' methods on the collection
        // (it still works as an array too)
        persons.idInsert(person); // returns true

        // Inserting person with same id will return false
        persons.idInsert(person); // false

        // Update the person entry
        persons.idUpdate(person.id, { birth: 1979 });

        // idReplace will replace if same id, insert otherwise
        var anotherPerson = new Person("Test2", 1980);
        anotherPerson.id = person.id;
        persons.idReplace(anotherPerson); // true

        // Remember to save!
        db.save();
    }
}
```

If your id field is named `_id`, use the method `db._idCol(Person)`, or you can use `db.keyCol(Person, idFieldName)` for any field.

## In-memory and browser DB

If you don't pass a filename when creating a `HaxeLow` object, it will be in-memory only. For the browser, if you pass a filename, HaxeLow will save the data in localStorage with the same key as the filename.

## When to use HaxeLow

Straight from the lowdb docs:

HaxeLow/lowdb is a convenient method for storing data without setting up a database server. It's fast enough and safe to be used as an embedded database.

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

## Making it work everywhere

The ways to store the DB varies a lot between platforms, so the only real solution is to let people implement their own disk storage. HaxeLow uses a simple interface for that, `HaxeLow.HaxeLowDisk`:

```haxe
interface HaxeLowDisk {
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

## Credits

HaxeLow uses [TJSON](https://github.com/martamius/TJSON), the tolerant JSON parser for Haxe.

Thanks to the lowdb authors for the idea!
