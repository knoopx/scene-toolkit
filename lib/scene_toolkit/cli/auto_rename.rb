# encoding: utf-8

require 'nestful'
require 'nokogiri'
require 'scene_toolkit/ext'

module SceneToolkit
  class CLI < Optitron::CLI
    class GoogleMatcher
      def self.match(name)
        response = Nestful.get("http://www.google.com/search", :params => {:q => name, :num => 100})
        response = Nokogiri::HTML(response).search(".g").text.encode("utf-8", "utf-8", :invalid => :replace)

        if name =~ /[\d+]$/ # artist-ablum-2012
          regex = /#{Regexp.escape(name)}(?:-[A-Za-z0-9]+)*/i
          matches = response.scan(regex).reject(&:downcase?).reject { |m| m.size == name.size }.uniq

        else # artist-ablum-2012-group
          regex = /#{Regexp.escape(name)}/i
          matches = response.scan(regex).reject(&:downcase?).select { |m| m.size == name.size }.uniq
        end

        matches.reject { |m| m == name }.select { |m| m =~ Release::Validations::Name::REGEXP }
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
        matches = []
        [GoogleMatcher].each do |matcher|
          matches = matcher.match(release_name)
          if matches.one?
            match = matches.first
            break
          end
        end

        if match.present?
          heading(release, :green) { info "Renamed #{release.name} => #{match}" }
          release.rename!(match)
        elsif matches.any?
          heading(release, :red) { error (["Multiple matches found for #{release_name}:"] + matches).join("\r\n    * ") }
        else
          heading(release, :red) { error "No matches found for #{release_name}" }
        end
      end
    end
  end
end
