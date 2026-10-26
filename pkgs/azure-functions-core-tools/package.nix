# Azure Functions Core Tools, pinned ahead of nixpkgs.
#
# nixpkgs currently ships 4.8.0, whose host process targets net8.0 and bundles
# Microsoft.Extensions.* 9.x. A .NET 10 isolated worker app resolves its WebJobs
# extension payload against Microsoft.Extensions.* 10.x, which that host cannot
# load, so `func start` dies with:
#
#   Could not load file or assembly 'Microsoft.Extensions.Options,
#   Version=10.0.0.0 ...'. The system cannot find the file specified.
#
# 4.15.1 targets net10.0, which resolves it. Drop this package once nixpkgs
# catches up past 4.15.1.
{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  buildDotnetModule,
  dotnetCorePackages,
  go,
}:
let
  version = "4.15.1";
  # eng/build/Templates.targets: TemplatesJsonVersion
  templatesVersion = "3.1.1648";

  src = fetchFromGitHub {
    owner = "Azure";
    repo = "azure-functions-core-tools";
    tag = version;
    hash = "sha256-qeTHGBEg4XJ2E2uLP4r5r05X+ECrujJdv9kW1MX2Dfo=";
  };

  templates = fetchurl {
    url = "https://cdn.functions.azure.com/public/TemplatesApi/${templatesVersion}.zip";
    hash = "sha256-YYKBwd69TIHQKF1r8BzlzIyDLJBcCqtAbK3FhNvA+5s=";
  };
in
buildDotnetModule {
  pname = "azure-functions-core-tools";
  inherit src version;
  projectFile = "src/Cli/func/Azure.Functions.Cli.csproj";
  executables = [ "func" ];

  nugetDeps = ./deps.json;
  dotnet-sdk = dotnetCorePackages.sdk_10_0 // {
    inherit
      (dotnetCorePackages.combinePackages [
        dotnetCorePackages.sdk_9_0
        dotnetCorePackages.sdk_8_0
      ])
      packages
      targetPackages
      ;
  };
  nativeBuildInputs = [ go ];

  # The 4.15.1 host is an ASP.NET Core 10 app. useDotnetFromEnv prefers whatever
  # `dotnet` is on PATH, but the fallback must also carry ASP.NET Core 10, or
  # `func start` dies with "framework 'Microsoft.AspNetCore.App', version
  # '10.0.0' was not found" on hosts that only install SDK 8/9 (e.g. `main`).
  dotnet-runtime = dotnetCorePackages.aspnetcore_10_0;

  linkNuGetPackagesAndSources = true;
  useDotnetFromEnv = true;

  # The build downloads templates.json from a CDN; pre-stage it so the sandbox
  # never needs network. Path tracks ArtifactsPath in Directory.Build.props
  # plus TemplatesStagingDir in eng/build/Templates.targets.
  postPatch = ''
    templates_path="./out/obj/Azure.Functions.Cli/templates-staging"
    mkdir -p "$templates_path"
    cp "${templates}" "$templates_path/templates.zip"

    substituteInPlace src/Cli/func/Common/CommandChecker.cs \
      --replace-fail "CheckExitCode(\"/bin/bash" "CheckExitCode(\"${stdenv.shell}"
  '';

  meta = {
    homepage = "https://github.com/Azure/azure-functions-core-tools";
    description = "Command line tools for Azure Functions";
    mainProgram = "func";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
