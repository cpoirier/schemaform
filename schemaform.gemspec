Gem::Specification.new do |s|
  s.name        = "schemaform"
  s.version     = "0.0.1"
  s.authors     = ["Chris Poirier"]
  s.email       = "chris@couragemyfriend.org"
  s.homepage    = "http://schemaform.org"
  s.summary     = "A DSL giving the power of spreadsheets in a relational setting."
  s.description = <<-end
    A DSL giving the power of spreadsheets in a relational setting. With Schemaform,
    you describe your data and the relationships within it, and Schemaform worries
    about making it run correctly and fast. 
  end
  
  
  s.required_rubygems_version = ">= 1.3.6"
  
  s.files        = Dir["{lib}/**/*.rb", "**/*.markdown"]
  s.require_path = "lib"
end