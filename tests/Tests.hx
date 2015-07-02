
import buddy.*;
using buddy.Should;

class SomeObject {
	public function new() {
		internal = "internal";
	}

	public var id(default, null) : String = HaxeLow.uuid();
	public var name : String;
	public var array : Array<Int>;

	var internal : String;
}

class PublicId {
	public function new() {}
	public var _id : String;
	public var name : String;
}

class Tests extends BuddySuite implements Buddy<[Tests]> {	
	public function new() {
		#if js
		var fs : Dynamic = js.Lib.require('fs');
		#end
		var db : HaxeLow;
		var o : SomeObject;
		var filename = 'test.json';
		
		describe("HaxeLow", {
			#if js
			describe("The file database", {

				before({
					if(fs.existsSync(filename))	fs.unlinkSync(filename);
					db = new HaxeLow(filename);

					o = new SomeObject();
					o.name = "Name";
					o.array = [1,2,3];
				});

				it("should have a filename", {
					db.file.should.be(filename);
				});

				it("should write to the file when saved", function(done) {
					fs.existsSync(filename).should.be(false);
					db.save().should.be(db);
					haxe.Timer.delay(function() {
						fs.existsSync(filename).should.be(true);
						done();
					}, 250);
				});

				it("should make a backup to a file when specified, still keeping the db object", function(done) {
					var objects = db.col(SomeObject);
					var backup = 'backup.json';
					if(fs.existsSync(backup)) fs.unlinkSync(backup);
					objects.push(o);

					db.backup(backup).should.beType(String);
					db.col(SomeObject).should.be(objects);

					haxe.Timer.delay(function() {
						fs.existsSync(backup).should.be(true);
						done();
					}, 250);
				});
				
				it("should not save automatically after restore()", function() {
					db = new HaxeLow(filename, new HaxeLow.NodeJsDiskSync());
					db.col(SomeObject).push(o);
					db.save();
					
					var saved : String = fs.readFileSync(filename, {encoding: 'utf8'});
					var backupStr = '{"SomeObject":[]}';
					
					db.restore(backupStr);
					var objAfterRestore = db.col(SomeObject);
					
					objAfterRestore.length.should.be(0);
					fs.readFileSync(filename, {encoding: 'utf8'}).should.not.be(saved.length);
				});

				it("should save the db as JSON", function(done) {
					var objects = db.col(SomeObject);
					untyped o.id = null; // Simplifies the test
					objects.push(o);

					db.save();

					haxe.Timer.delay(function() {
						var saved = fs.readFileSync(filename, {encoding: 'utf8'});
						~/\s/g.replace(saved, "").should.be(
							'{"SomeObject":[{"_hxcls":"SomeObject","id":null,"name":"Name","array":[1,2,3],"internal":"internal"}]}'
						);
						done();
					}, 250);
				});				
			});
			#end

			describe("The in-memory database", {
				before({
					db = new HaxeLow();

					o = new SomeObject();
					o.name = "Name";
					o.array = [1,2,3];
				});

				it("shouldn't have a filename", {
					db.file.should.be(null);
				});

				it("shouldn't do anything when saved", {
					db.save().should.be(db);
				});

				it("should store objects in strongly typed collections", {
					var objects = db.col(SomeObject);
					objects.length.should.be(0);

					objects.push(o);
					objects[0].should.be(o);
					objects[0].name.should.be("Name");

					var objects2 = db.col(SomeObject);
					objects2.should.be(objects);
				});

				it("should backup the database to JSON when needed", {
					var objects = db.col(SomeObject);
					untyped o.id = null; // Simplifies the test
					objects.push(o);

					~/\s/g.replace(db.backup(), "").should.be(
						'{"SomeObject":[{"_hxcls":"SomeObject","id":null,"name":"Name","array":[1,2,3],"internal":"internal"}]}'
					);
				});

				it("should restore the database from JSON when needed, invalidating the current collections", {
					var objects = db.col(SomeObject);
					objects.push(o);

					var backup = db.backup();

					objects.pop();
					objects.length.should.be(0);
					db.col(SomeObject).length.should.be(0);

					db.restore(backup);

					var objects2 = db.col(SomeObject);
					db.col(SomeObject).length.should.be(1);
					objects2.should.not.be(objects);
				});
			});

			describe("Id-collections", {
				before({
					db = new HaxeLow();

					o = new SomeObject();
					o.name = "Name";
					o.array = [1,2,3];
				});
				
				it("should use the id field of a class to enable convenient id handling", {
					var objects = db.idCol(SomeObject);
					o.id.should.match(~/^[\da-f]{8}-[\da-f]{4}-4[\da-f]{3}-[89ab][\da-f]{3}-[\da-f]{12}$/);
					objects.idInsert(o).should.be(true);
					objects.idInsert(o).should.be(false);
					objects.length.should.be(1);

					objects.idGet(o.id).should.be(o);
					objects.idUpdate(o.id, { name: "Another name" } ).should.be(o);
					o.name.should.be("Another name");
					
					objects.idUpdate("Not existing ID", {name: "Another name"}).should.be(null);

					objects[0].should.be(o);
					objects.idRemove(o.id);
					objects.length.should.be(0);
				});

				it("should handle _id fields with _idCol()", {
					var objects = db._idCol(PublicId, String);
					var o = new PublicId();
					var o2 = new PublicId();
					
					objects.idInsert(o).should.be(true);
					objects.idInsert(o).should.be(false);
					objects.length.should.be(1);

					objects.idGet(null).should.be(o);
					o._id = "123";
					objects.idGet("123").should.be(o);
					
					objects.idUpdate(o._id, {name: "Another name"});
					o.name.should.be("Another name");
					
					o2._id = o._id;
					objects.idInsert(o2).should.be(false);
					objects.length.should.be(1);
					objects[0].should.be(o);
					
					objects.idReplace(o2).should.be(true);
					objects[0].should.be(o2);
					objects.length.should.be(1);
					
					objects.idReplace(o2).should.be(false);
					objects[0].should.be(o2);
					objects.length.should.be(1);

					objects.idRemove(o2._id);
					objects.length.should.be(0);
				});

				it("should handle arbitrary id fields with keyCol()", {
					var objects = db.keyCol(SomeObject, 'name');
					
					objects.idInsert(o).should.be(true);
					objects.idInsert(o).should.be(false);
					objects.length.should.be(1);

					objects.idGet('Name').should.be(o);
					o.name = "123";
					objects.idGet("123").should.be(o);
					
					objects.idUpdate(o.name, {name: "Another name"});
					o.name.should.be("Another name");
					
					objects.idRemove(o.name);
					objects.length.should.be(0);
				});				
			});
		});
	}
}
