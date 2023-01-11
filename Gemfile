require('bundler/inline')


gemfile(install=true) do

  # We must only add a Gem once, or it will end up with multiple source paths
  # even if those paths are the same.
  seen = ::Set::new

  # Any non-`path`/`git` sources will come from here.
  source('https://rubygems.org')

  # Most DD top-level directories will have one of these.
  ::Dir::glob("*/**/Gemfile").map!(&::Pathname::method(:new)).each { |gf|

    # Parse each `Gemfile` and extract their deps.
    ::Bundler::Definition::build(gf, gf.dirname.join('Gemfile.lock'), unlock=false).dependencies.each {

      # Skip any dependencies for the `cwd`.
      next if _1.source&.path&.eql?(::Pathname::new(?.))

      # Avoid a `Warning` e.g. —
      #   “Your Gemfile lists the gem checking-you-out (>= 0) more than once."
      next if seen.include?(_1.name)
      seen.add(_1.name)

      # T0DO: A `path` dependency should override any non-path dependency for the same Gem.
      if _1.source&.path then
        gem(_1.name, :path=>_1.source.path)
      else
        gem(_1.name)
      end

    }  # ::Bundler::Definition::build#each

  }  # ::Dir::glob

end  # gemfile do
