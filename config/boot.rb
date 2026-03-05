ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# Add Homebrew lib path to FFI search path for libvips (non-standard Homebrew prefix)
homebrew_lib = File.join(Dir.home, ".homebrew", "lib")
if File.directory?(homebrew_lib)
  require "ffi"
  new_path = [ homebrew_lib, *FFI::DynamicLibrary::SEARCH_PATH ]
  FFI::DynamicLibrary.send(:remove_const, :SEARCH_PATH)
  FFI::DynamicLibrary.const_set(:SEARCH_PATH, new_path.freeze)
end
