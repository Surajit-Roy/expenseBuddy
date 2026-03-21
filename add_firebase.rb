require 'xcodeproj'
project_path = 'ExpenseBuddy.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Find the package dependency
package_dep = project.root_object.package_references.find { |p| p.repositoryURL && p.repositoryURL.include?('firebase-ios-sdk') }
if package_dep
  puts "Found Firebase SDK Package Dependency"
  
  # Check if already linked
  already_linked = target.package_product_dependencies.any? { |d| d.product_name == 'FirebaseMessaging' }
  if already_linked
    puts "FirebaseMessaging already linked"
  else
    # Create the XCSwiftPackageProductDependency
    package_product_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    package_product_dep.product_name = 'FirebaseMessaging'
    package_product_dep.package = package_dep
    
    # Add to target
    target.package_product_dependencies << package_product_dep
    
    # Create BuildFile and link it in the Frameworks build phase
    build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
    build_file.product_ref = package_product_dep
    target.frameworks_build_phase.files << build_file
    
    project.save
    puts "Successfully linked FirebaseMessaging"
  end
else
  puts "Could not find Firebase SDK Package"
end
