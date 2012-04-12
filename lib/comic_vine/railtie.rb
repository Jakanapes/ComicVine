module ComicVine
  class Railtie < Rails::Railtie
    config.after_initialize do
      if File.exists? Rails.root.join('config', 'cv_key.yml')
        keyfile = YAML::load(File.open(Rails.root.join('config', 'cv_key.yml')))
        ComicVine::API.key = keyfile['cvkey']
      else
        ComicVine::API.key = 'no_keyfile_found'
      end
    end
  end
end