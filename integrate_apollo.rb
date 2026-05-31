#!/usr/bin/env ruby
$LOAD_PATH.unshift(*Gem.paths.path.flat_map { |p| Dir["#{p}/gems/*/lib"] })
require 'rubygems'
Gem.use_paths(Gem.user_dir, *Gem.path)
require 'xcodeproj'

PROJECT = ARGV[0] or abort "usage: integrate_apollo.rb <project.xcodeproj>"
proj = Xcodeproj::Project.open(PROJECT)
target = proj.targets.find { |t| t.name == 'NewLXP' } or abort "no target NewLXP"

# 1) Add Apollo iOS SwiftPM dependency.
url = "https://github.com/apollographql/apollo-ios.git"
existing = proj.root_object.package_references.find { |r| r.repositoryURL == url }
unless existing
  pkg = proj.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  pkg.repositoryURL = url
  pkg.requirement = { 'kind' => 'upToNextMajorVersion', 'minimumVersion' => '2.0.3' }
  proj.root_object.package_references << pkg
  existing = pkg
end

['Apollo','ApolloAPI'].each do |product_name|
  next if target.package_product_dependencies.any? { |d| d.product_name == product_name }
  dep = proj.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dep.package = existing
  dep.product_name = product_name
  target.package_product_dependencies << dep
  # Also add to Frameworks build phase as build file referencing the dep.
  bf = proj.new(Xcodeproj::Project::Object::PBXBuildFile)
  bf.product_ref = dep
  target.frameworks_build_phase.files << bf
end

proj.save
puts "Saved #{PROJECT}"
