defmodule JakeTestRef do
  use ExUnitProperties
  use ExUnit.Case
  doctest Jake

  def test_generator_property(jschema) do
    schema = Jason.decode!(jschema)
    gen = Jake.generator(schema)

    check all a <- gen do
      assert ExJsonSchema.Validator.valid?(schema, a)
    end
  end

  property "test ref simple" do
    jschema = ~s({"properties": {
                "foo": {"type": "integer"},
                "bar": {"$ref": "#/properties/foo"}
                }})
    test_generator_property(jschema)
  end

  property "test ref escape pointer" do
    jschema = ~s({"tilda~field": {"type": "integer"},
            "slash/field": {"type": "integer"},
            "percent%field": {"type": "integer"},
            "properties": {
                "tilda": {"$ref": "#/tilda~0field"},
                "slash": {"$ref": "#/slash~1field"},
                "percent": {"$ref": "#/percent%25field"}
            }})
    test_generator_property(jschema)
  end

  property "test ref nested schema" do
    jschema = ~s({"definitions": {
                "a": {"type": "integer"},
                "b": {"$ref": "#/definitions/a"},
                "c": {"$ref": "#/definitions/b"}
            },
            "$ref": "#/definitions/c"})
    test_generator_property(jschema)
  end

  property "test ref overrides any sibling keywords" do
    jschema = ~s({"definitions": {
                "reffed": {
                    "type": "array"
                }
            },
            "properties": {
                "foo": {
                    "$ref": "#/definitions/reffed",
                    "maxItems": 2
                }
            }})
    test_generator_property(jschema)
  end

  property "test ref not reference" do
    jschema = ~s({"properties": {
                "$ref": {"type": "string"}
            }})
    test_generator_property(jschema)
  end

  property "test ref array index" do
    jschema = ~s({"items": [
                {"type": "integer"},
                {"$ref": "#/items/0"}
            ]})
    test_generator_property(jschema)
  end

  property "test ref root" do
    jschema = ~s({"properties": {
                "bar" : {"type":"integer"},
                "foo": {"$ref": "#"}
            },
            "additionalProperties": false})
    test_generator_property(jschema)
  end

  property "test ref simple recursive" do
    jschema = ~s({"properties": {
                "foo_bar" : {"type":"integer"}, 
                "bar" : {"$ref": "#/properties"},
                "foo": {"$ref": "#/properties/bar"}
            },
            "additionalProperties": false})
    test_generator_property(jschema)
  end

  property "test ref complex recursive" do
    jschema = ~s({"definitions": {
                    "person": {
                      "type": "object",
                      "properties": {
                        "name": { "type": "string" },
                        "children": {
                          "type": "array",
                          "items": { "$ref": "#/definitions/person" }
                          
                        }
                      }, "required": ["name"], "additionalProperties": false
                    }
                  },
                  "type": "object",
                  "properties": {
                    "person": { "$ref": "#/definitions/person" }
                  }, "required": ["person"], "additionalProperties": false
                })
    test_generator_property(jschema)
  end

  property "test ref complex recursive no required" do
    jschema = ~s({"definitions": {
                    "person": {
                      "type": "object",
                      "properties": {
                        "name": { "type": "string", "minLength": 5 },
                        "children": {
                          "type": "array",
                          "items": { "$ref": "#/definitions/person" }
                          
                        }
                      }, "additionalProperties": false
                    }
                  },
                  "type": "object",
                  "properties": {
                    "person": { "$ref": "#/definitions/person" }
                  }, "additionalProperties": false
                })
    test_generator_property(jschema)
  end

  property "test complex ref" do
    jschema = ~s({ "definitions": {
                        "address": {
                          "type": "object",
                          "additionalProperties": false,
                          "properties": {
                            "street_address": { "type": "string" },
                            "city":           { "type": "string" },
                            "state":          { "type": "string" }
                          },
                          "required": ["street_address", "city", "state"]
                        }
                      },
                      "type": "object",
                      "properties": {
                        "billing_address": { "$ref": "#/definitions/address" },
                        "shipping_address": { "$ref": "#/definitions/address" }
                      },
                      "additionalProperties": false
                })
    test_generator_property(jschema)
  end
end
