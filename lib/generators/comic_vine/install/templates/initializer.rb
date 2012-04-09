

keyfile = YAML::load(File.open(Rails.root.join('config', 'cv_key.yml')))

ComicVine::API.key = keyfile['cvkey']