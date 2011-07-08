# encoding: utf-8

module SceneToolkit
  class CLI < Optitron::CLI
    desc "Generate missing or invalid release playlists"
    opt "force", "Force the modification of existing files"

    def playlists(directory_string)
      each_release(directory_string) do |release|
        if release.valid_playlist?
          heading(release, :green) do
            info("Skipping. Playlist seems to be OK.")
          end
        else
          heading(release, :green) do
            print_errors(release)

            candidates = release.files.select { |f| %w(.nfo .m3u .sfv).include?(File.extname(f).downcase) }.group_by { |f| File.basename(f, '.*') }
            if candidates.none?
              error "Unable to guess playlist filename"
              next
            end

            playlist_filename = [candidates.max { |k, v| v.size }.first, ".m3u"].join

            playlist_path = File.join(release.path, playlist_filename)
            if File.exist?(playlist_path) and not params[:force]
              error "Playlist #{playlist_filename} already exists. Use --force to replace it."
            else
              info "Generating new playlist: #{playlist_filename}"
              File.open(playlist_path, "w") do |playlist_file|
                release.mp3_files.map { |f| File.basename(f) }.each do |mp3_file|
                  playlist_file.puts mp3_file
                end
              end
            end
          end
        end
      end
    end
  end
end
