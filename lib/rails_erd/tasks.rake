def say(message)
  puts message unless Rake.application.options.silent
end

namespace :erd do
  task :options do
    (RailsERD.options.keys.map(&:to_s) & ENV.keys).each do |option|
      RailsERD.options[option.to_sym] = case ENV[option]
      when "true", "yes" then true
      when "false", "no" then false
      when /,/ then ENV[option].split(/\s*,\s*/).map(&:to_sym)
      else ENV[option].to_sym
      end
    end
  end

  task :load_models do
    say "Loading application environment..."
    Rake::Task[:environment].invoke

    say "Loading code in search of Active Record models..."
    begin
      Dir["/app/models"].each {|f| require f}
    rescue Exception => err
      if Rake.application.options.trace
        raise
      else
        error = (["Loading models failed!\nError occurred while loading application: #{err} (#{err.class})"]).join("\n    ")
        raise error
      end
    end

    raise "Active Record was not loaded." unless defined? ActiveRecord
  end

  task :generate => [:options, :load_models] do
    say "Generating Entity-Relationship Diagram for #{ActiveRecord::Base.descendants.length} models..."

    require "rails_erd/diagram/graphviz"
    file = RailsERD::Diagram::Graphviz.create

    say "Done! Saved diagram to #{file}."
  end
end

desc "Generate an Entity-Relationship Diagram based on your models"
task :erd => "erd:generate"
