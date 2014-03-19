log_level :debug

root = File.absolute_path(File.dirname(__FILE__))

file_cache_path root
cookbook_path File.expand_path("cookbooks", root)
