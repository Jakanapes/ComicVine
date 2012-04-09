module ComicVine
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      desc "This generator installs the blank keyfile for ComicVine and copies the initializer"
      def copy_the_keyfile
        copy_file "cv_key.yml", "config/cv_key.yml"
      end
      
      def copy_the_init
        copy_file "initializer.rb", "config/initializers/comic_vine.rb"
      end

    end
  end
end