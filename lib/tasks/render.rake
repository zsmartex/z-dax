
require_relative '../z-dax/renderer'

namespace :render do
  desc 'Render configuration and compose files and keys'
  task :config do
    renderer = ZDax::Renderer.new
    renderer.render_keys
    renderer.render
  end
end
