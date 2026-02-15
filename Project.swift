import ProjectDescription

let project = Project(
    name: "LizaCalculator",
    packages: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", .exact("5.6.0"))
    ],
    settings: .settings(configurations: [
        .debug(
            name: "DebugBuild",
            settings: SettingsDictionary.default(
                .debug, devTeam: "", build: "1.0.0", version: "1")
        )
    ]),
    targets: [
        .target(
            name: "LizaCalculator",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.LizaCalculator",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchStoryboardName": "LaunchScreen.storyboard",
                    "UIApplicationSceneManifest": .dictionary([
                        "UIApplicationSupportsMultipleScenes": .boolean(false),
                        "UISceneConfigurations": .dictionary([
                            "UIWindowSceneSessionRoleApplication": .array(
                                [
                                    .dictionary([
                                        "UISceneConfigurationName": .string(
                                            "Default Configuration"),
                                        "UISceneDelegateClassName": .string(
                                            "$(PRODUCT_MODULE_NAME).SceneDelegate"),
                                    ])
                                ]
                            )
                        ]),
                    ]),
                ]
            ),
            sources: ["LizaCalculator/Sources/**"],
            resources: ["LizaCalculator/Resources/**"],
            dependencies: [
                .package(product: "SnapKit")
            ]
        ),
        .target(
            name: "LizaCalculatorTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.LizaCalculatorTests",
            infoPlist: .default,
            sources: ["LizaCalculator/Tests/**"],
            resources: [],
            dependencies: [
                .target(name: "LizaCalculator"),
                .package(product: "SnapKit"),
            ]
        ),
    ],
    resourceSynthesizers: [.strings(), .assets()]
)

extension SettingsDictionary {
    public static func `default`(
        _ config: Configuration, devTeam: String, build: String, version: String
    ) -> SettingsDictionary {
        var settings: SettingsDictionary = [
            "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
            "CODE_SIGN_STYLE": "Automatic",
            "CURRENT_PROJECT_VERSION": "\(build)",
            "MARKETING_VERSION": "\(version)",
            "GENERATE_INFOPLIST_FILE": "YES",
            "SWIFT_EMIT_LOC_STRINGS": "YES",
            "OTHER_SWIFT_FLAGS": "-Xfrontend -enable-actor-data-race-checks",
            "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
            "INFOPLIST_KEY_UILaunchStoryboardName": "LaunchScreen.storyboard",
            "INFOPLIST_KEY_UISupportedInterfaceOrientations": "UIInterfaceOrientationPortrait",
        ]

        settings =
            settings
            .automaticCodeSigning(devTeam: devTeam)
            .otherLinkerFlags(["-ObjC"])

        settings["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "DEBUG"

        return settings
    }
}

public enum Configuration: String {
    case release = "Release"
    case debug = "Debug"
    case unitTest = "UnitTests"
    case uiTest = "XCUI"

    public var name: ConfigurationName {
        ConfigurationName(stringLiteral: rawValue)
    }
}
