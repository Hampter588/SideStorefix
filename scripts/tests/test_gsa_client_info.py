"""Offline Swift regression for SideStore's GSA client identity.

Run with Python 3 and Swift installed, after checking out the pinned AnisetteKit:
  python3 scripts/tests/test_gsa_client_info.py --anisette-kit /path/to/AnisetteKit

Compiles the actual header-construction method and SideSign request-construction
code with Foundation-only dependency sources. Does not run authentication, access
user settings, or send requests. This is not a full app integration test.
"""

import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
SIDESIGN = ROOT / "Dependencies/SideSign/Sources"


def read(path):
    return path.read_text(encoding="utf-8").replace("import AnisetteKit\n", "")


def between(source, start, end):
    begin = source.index(start)
    return source[begin:source.index(end, begin)]


def swift_fixture(anisette_kit):
    config = read(ROOT / "SideStore/Core/Anisette/AnisetteConfigManager.swift")
    auth = read(SIDESIGN / "DeveloperPortal/Authentication.swift")
    config_type = between(config, "public struct AnisetteConfig:", "public actor AnisetteConfigManager")
    make_headers = between(config, "    public func makeRequestHeaders()", "    public func resolvedXcodeVersion()")
    make_request = between(auth, "        let requestURL = Constants.URLs.grandSlamAuth", "        if let allHeaders = request.allHTTPHeaderFields")

    sources = [anisette_kit / "Sources" / name for name in (
        "Constants.swift", "AnisetteRequestHeaders.swift", "AnisetteHeadersDTO.swift"
    )] + [SIDESIGN / name for name in (
        "Constants.swift", "SideSignHeaders.swift", "Models/AnisetteData.swift"
    )]
    return "\n".join(read(path) for path in sources) + "\n" + config_type + "\n" + r'''
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
typealias AppConstants = Constants
struct ConfigurationFixture {
    let config: AnisetteConfig
    func loadConfig() -> AnisetteConfig { config }
''' + make_headers + r'''
}
func grandSlamRequest(_ anisetteData: AnisetteData) throws -> URLRequest {
    let customHeaders = SideSignHeaders()
    let requestParameters: [String: any Sendable] = ["o": "init"]
''' + make_request + r'''
    return request
}

let prefix = "<MacBookPro18,3> <macOS;26.6;25F84> <com.apple.AuthKit/1 "
let compatible = prefix + "(com.apple.akd/1.0)>"
let cases: [(String, String)] = [
    (prefix + "(com.apple.dt.Xcode/25183.54.10)>", compatible),
    (prefix + "(com.apple.dt.Xcode/26.0)>", compatible),
    (compatible, compatible),
    ("", AnisetteConstants.defaultClientInfo),
    ("<模型> <macOS;15.7;24G> <com.apple.AuthKit/1 (com.apple.dt.Xcode/16A)> <extra>",
     "<模型> <macOS;15.7;24G> <com.apple.AuthKit/1 (com.apple.akd/1.0)> <extra>"),
    (prefix + "(com.example.client/2.0)>", prefix + "(com.example.client/2.0)>")
]
for (index, pair) in cases.enumerated() {
    let (input, expected) = pair
    let config = AnisetteConfig(
        clientInfo: input, userAgent: "fixture-agent",
        customDeviceID: "fixture-device", customLocalUserID: "fixture-user",
        customLocale: "en_GB", customTimeZone: "UTC",
        customSerialNumber: "fixture-serial", customRoutingInfo: "1234"
    )
    let headers = ConfigurationFixture(config: config).makeRequestHeaders()
    precondition(config.clientInfo == input, "Saved configuration was changed")
    precondition(headers.clientInfo == expected, "Client info mismatch: case \(index)")
    precondition(headers.userAgent == config.userAgent)
    precondition(headers.deviceID == config.customDeviceID)
    precondition(headers.localUserID == config.customLocalUserID)
    precondition(headers.locale == config.customLocale)
    precondition(headers.timeZone == config.customTimeZone)
    precondition(headers.serialNumber == config.customSerialNumber)
    precondition(headers.routingInfo == config.customRoutingInfo)

    let anisetteData = AnisetteData(
        machineID: "fixture-machine", oneTimePassword: "fixture-otp",
        localUserID: headers.localUserID!, routingInfo: headers.routingInfo!,
        deviceID: headers.deviceID!, serialNumber: headers.serialNumber!,
        clientInfo: headers.clientInfo!, userAgent: headers.userAgent!,
        clientTime: "2026-09-11T00:00:00Z", locale: headers.locale!, timeZone: headers.timeZone!
    )
    let request = try grandSlamRequest(anisetteData)
    let value = request.value(forHTTPHeaderField: "X-Mme-Client-Info")!
    precondition(request.url == Constants.URLs.grandSlamAuth)
    precondition(request.httpMethod == "POST")
    precondition(value == expected)
    precondition(!value.contains("com.apple.dt.Xcode"))
    if index != cases.count - 1 { precondition(value.contains("com.apple.akd")) }
    let again = ConfigurationFixture(config: AnisetteConfig(clientInfo: value, userAgent: "fixture-agent"))
        .makeRequestHeaders()
    precondition(again.clientInfo == value, "Sanitizer must be idempotent")
}
print("PASS: \(cases.count) GSA request/header cases; no network requests sent")
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--anisette-kit", type=Path, required=True)
    parser.add_argument("--emit", type=Path, help="Write the Swift fixture without running tests")
    args = parser.parse_args()
    fixture = swift_fixture(args.anisette_kit)
    if args.emit:
        args.emit.write_text(fixture, encoding="utf-8")
        print(f"Generated {args.emit}; Swift tests have NOT run")
        return
    swift = shutil.which("swift")
    if not swift:
        parser.exit(2, "Swift is required; no regression tests were run.\n")
    with tempfile.TemporaryDirectory(prefix="sidestore-gsa-test-") as directory:
        path = Path(directory) / "main.swift"
        path.write_text(fixture, encoding="utf-8")
        subprocess.run([swift, str(path)], check=True)


if __name__ == "__main__":
    main()
