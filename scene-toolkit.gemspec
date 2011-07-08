require File.expand_path("../lib/scene_toolkit", __FILE__)

Gem::Specification.new do |s|
  s.name = %q{scene-toolkit}
  s.version = SceneToolkit::VERSION
  s.platform = Gem::Platform::RUBY
  s.homepage = "http://github.com/knoopx/scene-toolkit"
  s.authors = ["Víctor Martínez"]
  s.email = ["knoopx@gmail.com"]
  s.summary = "Tool to assist scene MP3 library maintenance"
  s.description = "Tool to assist scene MP3 library maintenance"

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }

  s.add_dependency("activesupport", ["~> 3.0.0"])
  s.add_dependency("i18n")
  s.add_dependency("colored")
  s.add_dependency("optitron")
  s.add_dependency("nestful")
end

