ABModel
=======

ABModel is a class that parse a JSon dictionary to create an instance of ABModel.
This class make model cration from REST API easier as you don't have to parse the server response

## Usage

In order to benefit this powerful parsing you just have to create your model class and made it inherit from ABModel. 

You must use : `INSTANCE_TYPE(dictionary:Dictionary<String, AnyObject>)` to create your instance with a JSon dictionary

I use introspection to retrieve all the properties of your model from the JSon.
In order to write less code you just have to name your object's properties the same way as your JSon keys. If you prefer to code multiple method, you can override `replaceKey(key:String) -> String` in your ABModel subclass and for each JSon key you want to rename return your property name as a string 

#### Sample
```class Example : ABModel {
	var exampleID = 0
	var name = ""
	var tests = []
	public func replaceKey(key:String) -> String {
		if (key == "id") {
			return "exampleID"
		}
	}
}```

To create an instance of Example

```func createExampleWithDictionary(JSonExample:Dictionary<String, AnyObject>) -> Exemple {
	 return Exemple(dictionary:JSonExample)
}```