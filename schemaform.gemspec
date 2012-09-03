Gem::Specification.new do |s|
  s.name        = "schemaform"
  s.version     = "0.0.1"
  s.license     = "Apache License, v2.0"
  s.authors     = ["Chris Poirier"]
  s.email       = "chris@couragemyfriend.org"
  s.homepage    = "http://schemaform.org"
  s.summary     = "A DSL giving the power of spreadsheets in a relational setting."
  s.description = <<-end
    Schemaform provides a high-level database programming DSL within Ruby that makes it 
    easy to define complex webs of data in a normalized form. Schemaform then uses your
    high-level description and formulas to generate a fast, always-up-to-date, easy-to-use
    relational system. 
  end
  
  s.required_rubygems_version = ">= 1.3.6"
  
  s.files        = Dir["{lib}/**/*.rb", "**/*.markdown"]
  s.require_path = "lib"
end