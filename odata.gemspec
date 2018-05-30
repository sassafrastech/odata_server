$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "odata/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "odata"
  s.version     = Odata::VERSION
  s.authors     = ["Mark Borkum", "Brad Langhorst", "Nigel Sheridan-Smith", "Lawrence McAlpin", "Jason Hamilton", "Sebastian Kliem", "Tim Schmelmer"]
  s.email       = ["tim.schmelmer@gmail.com"]
  s.homepage    = ""
  s.summary     = "A simple gem that exposes ActiveRecord models as OData collections."
  s.description = ""

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.2.0"

  s.add_development_dependency "capybara"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "sqlite3"

  s.require_paths = ["lib"]
  s.test_files = Dir["spec/**/*"]


end
