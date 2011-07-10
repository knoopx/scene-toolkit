# encoding: utf-8

require 'nestful'
require 'scene_toolkit/ext'

module SceneToolkit
  class CLI < Optitron::CLI
    class GoogleMatcher
      def self.match(release)
        regex = Regexp.new(Regexp.escape(release.name), Regexp::IGNORECASE)
        response = Nestful.get("http://www.google.com/search", :params => { :q => release.name, :num => 100 })
        response.scan(regex).uniq.reject(&:downcase?)
      end
    end

    class OrlydbMatcher
      def self.match(release)
        regex = Regexp.new(Regexp.escape(release.name), Regexp::IGNORECASE)
        response = Nestful.get("http://orlydb.com", :params => { :q => release.name.to_search_string })
        response.scan(regex).uniq.reject(&:downcase?)
      end
    end

    desc "Repair release names"

    def auto_rename(directory_string)
      each_release(directory_string) do |release|
        unless release.name.downcase?
          heading(release, :green) { info "Skipping. Release name seems to be OK." }
          next
        end

        match = nil
        [OrlydbMatcher, GoogleMatcher].each do |matcher|
          matches = matcher.match(release)
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
