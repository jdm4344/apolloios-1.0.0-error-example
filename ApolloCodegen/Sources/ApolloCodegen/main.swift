import Foundation
import ApolloCodegenLib
import ArgumentParser

//# Go to the build root and search up the chain to find the Derived Data Path where the source packages are checked out.
//DERIVED_DATA_CANDIDATE="${BUILD_ROOT}"
//
//while ! [ -d "${DERIVED_DATA_CANDIDATE}/SourcePackages" ]; do
//  if [ "${DERIVED_DATA_CANDIDATE}" = / ]; then
//    echo >&2 "error: Unable to locate SourcePackages directory from BUILD_ROOT: '${BUILD_ROOT}'"
//    exit 1
//  fi
//
//  DERIVED_DATA_CANDIDATE="$(dirname "${DERIVED_DATA_CANDIDATE}")"
//done
//
//# Grab a reference to the directory where scripts are checked out
//SCRIPT_PATH="${DERIVED_DATA_CANDIDATE}/SourcePackages/checkouts/apollo-ios/scripts"
//
//if [ -z "${SCRIPT_PATH}" ]; then
//    echo >&2 "error: Couldn't find the CLI script in your checked out SPM packages; make sure to add the framework to your project."
//    exit 1
//fi
//
//cd "${SRCROOT}/${TARGET_NAME}"
//"${SCRIPT_PATH}"/run-bundled-codegen.sh codegen:generate --target=swift --includes=./**/*.graphql --localSchemaFile="schema.json" API.swift
//#"${SCRIPT_PATH}"/run-bundled-codegen.sh schema:download --endpoint="https://apollo-fullstack-tutorial.herokuapp.com/graphql"




// An outer structure to hold all commands and sub-commands handled by this script.
struct SwiftScript: ParsableCommand {

  static var configuration = CommandConfiguration(
    abstract: """
        A swift-based utility for performing Apollo-related tasks.
        
        NOTE: If running from a compiled binary, prefix subcommands with `swift-script`. Otherwise use `swift run ApolloCodegen [subcommand]`.
        """,
    subcommands: [DownloadSchema.self, GenerateCode.self, DownloadSchemaAndGenerateCode.self])

  /// The URL to the source root for your main project.
  /// Defaults to the folder containing the `ApolloCodgen` Package folder.
  ///
  /// NOTE: - You may need to change this if your project has a different structure
  /// than the suggested structure.
  static let SourceRootURL: URL = {
    let parentFolderOfScriptFile = FileFinder.findParentFolder()
    let sourceRootURL = parentFolderOfScriptFile
      .apollo.parentFolderURL() // Result: Sources folder
      .apollo.parentFolderURL() // Result: ApolloCodegen folder
      .apollo.parentFolderURL() // Result: Project source root folder

    CodegenLogger.log("Source Root URL: \(sourceRootURL)")
    return sourceRootURL
  }()

  // The URL where the downloaded schema will be written to.
  // The default writes the schema to your project's root.
  static let SchemaOutputURL: URL = {
    SourceRootURL.appendingPathComponent("RocketReserver/schema.graphqls")
  }()

  /// The sub-command to download a schema from a provided endpoint.
  struct DownloadSchema: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "downloadSchema",
      abstract: "Downloads the schema with the settings you've set up in the `DownloadSchema` command in `main.swift`.")

    func run() throws {
      // Set up the URL you want to use to download the project
      let endpoint = URL(string: "https://apollo-fullstack-tutorial.herokuapp.com/graphql")!

      // Make sure the folder is created before trying to download something to it.
      let folderForDownloadedSchema = SchemaOutputURL.deletingLastPathComponent()
      try FileManager.default.apollo.createDirectoryIfNeeded(atPath: folderForDownloadedSchema.path)

      // Create a configuration object for downloading the schema.
      // Provided code will download the schema via an introspection query to the provided URL as
      // SDL (GraphQL Schema Definition Language).
      // For all configuration parameters see:
      // https://www.apollographql.com/docs/ios/api/ApolloCodegenLib/structs/ApolloSchemaDownloadConfiguration/
//      let schemaDownloadOptions = ApolloSchemaDownloadConfiguration(
//        using: .introspection(endpointURL: endpoint),
//        outputPath: SchemaOutputURL.path
//      )

      // Actually attempt to download the schema.
//      try ApolloSchemaDownloader.fetch(configuration: schemaDownloadOptions)
    }
  }

  /// The sub-command to actually generate code.
  struct GenerateCode: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "generate",
      abstract: "Generates swift code from your schema + your operations based on information set up in the `GenerateCode` command.")

    func run() throws {
      // TODO: Replace the placeholder here with the name of the folder containing your project's code files.
      /// The root of the target for which you want to generate code.
      let targetRootURL = SourceRootURL
        .apollo.childFolderURL(folderName: "RocketReserver")

      // TODO: Replace the placeholder here with the name you would like to give your schema.
      /// The name of the module that will contain your generated schema objects.
      let generatedSchemaModuleName: String = "API"

      /// The URL where the generated schema files will be written to.
      let schemaModuleURL = SourceRootURL
        .apollo.childFolderURL(folderName: generatedSchemaModuleName)

      // Make sure the folders exists before trying to generate code.
      try FileManager.default.apollo.createDirectoryIfNeeded(atPath: targetRootURL.path)
      try FileManager.default.apollo.createDirectoryIfNeeded(atPath: schemaModuleURL.path)

      // Create the Codegen configuration object. For all configuration parameters see: https://www.apollographql.com/docs/ios/api/ApolloCodegenLib/structs/ApolloCodegenConfiguration/
      let codegenConfiguration = ApolloCodegenConfiguration(
        schemaName: generatedSchemaModuleName,
        input: ApolloCodegenConfiguration.FileInput(schemaPath: SchemaOutputURL.path),
        output: ApolloCodegenConfiguration.FileOutput(
          schemaTypes: ApolloCodegenConfiguration.SchemaTypesFileOutput(
            path: schemaModuleURL.path,
            moduleType: .embeddedInTarget(name: generatedSchemaModuleName))
        )
      )

      // Actually attempt to generate code.
      try ApolloCodegen.build(with: codegenConfiguration)
    }
  }

  /// A sub-command which lets you download the schema then generate swift code.
  ///
  /// NOTE: This will both take significantly longer than code generation alone and fail when you're offline, so this is not recommended for use in a Run Phase Build script that runs with every build of your project.
  struct DownloadSchemaAndGenerateCode: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "all",
      abstract: "Downloads the schema and generates swift code. NOTE: Not recommended for use as part of a Run Phase Build Script.")

    func run() throws {
      try DownloadSchema().run()
      try GenerateCode().run()
    }
  }
}

// This will set up the command and parse the arguments when this executable is run.
SwiftScript.main()
