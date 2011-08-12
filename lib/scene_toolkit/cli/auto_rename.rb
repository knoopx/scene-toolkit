# encoding: utf-8

require 'nestful'
require 'scene_toolkit/ext'

module SceneToolkit
  class CLI < Optitron::CLI
    class GoogleMatcher
      def self.match(name)
        regex = Regexp.new(Regexp.escape(name), Regexp::IGNORECASE)
        response = Nestful.get("http://www.google.com/search", :params => { :q => name, :num => 100 })
        response.scan(regex).uniq.reject(&:downcase?)
      end
    end

    class OrlyDbMatcher
      def self.match(name)
        regex = Regexp.new(Regexp.escape(name), Regexp::IGNORECASE)
        response = Nestful.get("http://orlydb.com", :params => { :q => name.to_search_string })
        response.scan(regex).uniq.reject(&:downcase?)
      end
    end

    desc "Repair release names"

    def auto_rename(directory_string)
      each_release(directory_string) do |release|
        next if release.valid_name? and not release.name.downcase?

        if release.valid_name?
          release_name = release.name
        else
          release_name = release.heuristic_name
        end

        next if release_name.blank?

        match = nil
        [OrlyDbMatcher, GoogleMatcher].each do |matcher|
          matches = matcher.match(release_name)
          if matches.one?
            match = matches.first
            break
          end
        end

        if match.present?
          heading(release, :green) { info "Renamed #{release.name} => #{match}" }
          release.rename!(match)
        else
          heading(release, :red) { error "No matches found for #{release.name}" }
        end
      end
    end
  end
end
