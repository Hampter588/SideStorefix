//
//  OperationError.swift
//  SideStore
//
//  Created by Magesh K on 3/9/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import Foundation

public enum OperationError: LocalizedError, CustomNSError, Sendable, Equatable {
    // General
    case unknown(failureReason: String? = nil, file: String = #fileID, line: UInt = #line)
    case unknownResult
    case timedOut
    case notAuthenticated
    case appNotFound(name: String? = nil)
    case unknownUDID
    case invalidApp(reason: String? = nil)
    case invalidParameters(String? = nil)
    case invalidOperationContext(String? = nil)
    case maximumAppIDLimitReached(appName: String, requiredAppIDs: Int, availableAppIDs: Int, expirationDate: Date)
    case noSources
    case noInstalledApps
    case openAppFailed(name: String? = nil)
    case missingAppGroup
    case forbidden(failureReason: String? = nil, file: String = #fileID, line: UInt = #line)
    case sourceNotAdded(name: String)
    case serverNotFound
    case connectionFailed
    case pledgeInactive(appName: String)

    // SideStore & Connectivity
    case unableToConnectSideJIT
    case unableToRespondSideJITDevice
    case SideJITIssue(error: String?)
    case provisioningError(result: String, message: String? = nil)
    case certificateRevoked(appName: String)
    case customCertificateRevoked(appName: String, activeTeam: String)
    case customCertificateExpired(appName: String, activeTeam: String)
    case certificateExpired(appName: String)
    case certificateChanged(appName: String)
    case cacheClearError(errors: [String])

    // Minimuxer & Device Connection
    case noConnection(reason: String? = nil)
    case noVPN(reason: String? = nil)
    case invalidVPN(reason: String? = nil)
    case noDevice(reason: String? = nil)
    case notReachable(reason: String)
    case invalidPairingFile(reason: String? = nil)
    case minimuxerNotStarted(reason: String? = nil)
    case pairingNotComplete(reason: String? = nil)

    // Packaging / Signing
    case missingAppBundle
    case missingInfoPlist
    case missingProvisioningProfile

    public static var cancelled: CancellationError { CancellationError() }
    public static var invalidApp: OperationError { .invalidApp() }

    public static func sourceNotAdded(_ source: Source, file: String = #fileID, line: UInt = #line) -> OperationError {
        .sourceNotAdded(name: source.name)
    }

    public var rawDescription: String {
        switch self {
        case .unknown(let failureReason, let file, let line):
            let base = failureReason ?? "An unknown error occurred."
            return "\(base) (\(file) line \(line))"
        case .unknownResult:
            return "The operation returned an unknown result."
        case .timedOut:
            return "The operation timed out."
        case .notAuthenticated:
            return "You are not signed in."
        case .unknownUDID:
            return "SideStore could not determine this device's UDID. Please replace your pairing using iloader."
        case .invalidApp(let reason):
            if let reason, !reason.isEmpty {
                return "The app is in an invalid format: \(reason)"
            }
            return "The app is in an invalid format."
        case .invalidParameters(let msg):
            let suffix = msg.map { ": \n\($0)" } ?? "."
            return "Invalid parameters\(suffix)"
        case .invalidOperationContext(let msg):
            let suffix = msg.map { ": \n\($0)" } ?? "."
            return "Invalid Operation Context\(suffix)"
        case .maximumAppIDLimitReached:
            return "Cannot register more than 10 App IDs within a 7 day period."
        case .noSources:
            return "There are no SideStore sources."
        case .noInstalledApps:
            return "There are no active sideloaded apps to refresh."
        case .openAppFailed(let name):
            let app = name ?? "The app"
            return "SideStore was denied permission to launch \(app)."
        case .missingAppGroup:
            return "SideStore's shared app group could not be accessed."
        case .forbidden(let reason, _, _):
            return reason ?? "The operation is forbidden."
        case .sourceNotAdded(let name):
            return "The source “\(name)” is not added to SideStore."
        case .appNotFound(let name):
            let app = name ?? "The app"
            return "\(app) could not be found."
        case .serverNotFound:
            return "AltServer could not be found."
        case .connectionFailed:
            return "A connection to AltServer could not be established."
        case .pledgeInactive(let appName):
            return "Your pledge is no longer active. Please renew it to continue using \(appName) normally."
        case .unableToConnectSideJIT:
            return "Unable to connect to SideJITServer. Please check that you are on the same Wi-Fi of and your Firewall has been set correctly on your server."
        case .unableToRespondSideJITDevice:
            return "SideJITServer is unable to connect to your iDevice. Please make sure you have paired your iDevice by running 'SideJITServer -y', or try refreshing SideJITServer from Settings."
        case .SideJITIssue(let error):
            return "An error occurred while using SideJIT: \(error ?? "")"
        case .provisioningError(let result, let message):
            let combined = (message?.isEmpty ?? true) ? result : "\(result) \(message!)"
            let trimmed = combined.trimmingCharacters(in: CharacterSet(charactersIn: " ."))
            return "An error occurred while provisioning: \(trimmed). Please try again. If the issue persists, report it on GitHub Issues!"
        case .certificateRevoked(let appName):
            return "The signing certificate used to install “\(appName)” was revoked on the Apple Developer portal. Please re-sign or reinstall the app."
        case .customCertificateRevoked(_, let activeTeam):
            return "Your active custom/third-party signing certificate (Team: \(activeTeam)) was revoked on the Developer Portal.\n\nIf you did not intend to use a custom certificate, please reset it in Settings -> Advanced -> Certificates."
        case .customCertificateExpired(_, let activeTeam):
            return "Your active custom/third-party signing certificate (Team: \(activeTeam)) has expired.\n\nIf you did not intend to use a custom certificate, please reset it in Settings -> Advanced -> Certificates."
        case .certificateExpired(let appName):
            return "The signing certificate used to install “\(appName)” has expired. Please re-sign or reinstall the app."
        case .certificateChanged(let appName):
            return "The signing certificate used to install “\(appName)” differs from your active signing certificate. Please re-sign or reinstall the app."
        case .cacheClearError(let errors):
            return "An error occurred while clearing the cache: \(errors.joined(separator: "\n"))"
        case .noConnection(let reason):
            if let reason, !reason.isEmpty {
                return "Network Connection Error:\n\(reason)\n\nPlease connect to Wi-Fi before attempting further operations."
            }
            return "You do not appear to be connected to Wi-Fi!\n\nPlease connect to a Wi-Fi before attempting futher operations"
        case .noVPN(let reason), .invalidVPN(let reason):
            if let reason, !reason.isEmpty {
                return "VPN Connection Error:\n\(reason)\n\nPlease make sure LocalDevVPN is connected and running properly."
            }
            return "You do not appear to be connected to VPN.\n\nPlease make sure LocalDevVPN is connected and running! If the issue persists, replace your pairing with iloader or try restarting the device."
        case .noDevice(let reason):
            if let reason, !reason.isEmpty {
                return "SideStore is unable to reach the device endpoint:\n\(reason)\n\nPlease check your Connection Configuration in Settings."
            }
            return "SideStore is unable to reach the device endpoint.\n\nPlease check your Connection Configuration in Settings to ensure the IP and endpoint are correct."
        case .notReachable(let reason):
            return reason.isEmpty ? "Device is not reachable at the specified IP or Endpoint." : reason
        case .invalidPairingFile(let reason):
            if let reason, !reason.isEmpty {
                return "The current pairing file is invalid or missing. Reason: \(reason)\n\nPlease make sure to input a valid pairing file! If the issue persists, replace your pairing with iloader."
            }
            return "The current pairing file is invalid or missing.\n\nPlease make sure to input a valid pairing file! If the issue persists, replace your pairing with iloader."
        case .minimuxerNotStarted:
            return "Minimuxer has not been started yet.\n\nPlease complete pairing or start minimuxer before performing operations."
        case .pairingNotComplete:
            return "Pairing Required:\nWithout a valid pairing file, SideStore operations cannot connect to your device. Please pair your device or import a valid pairing file."
        case .missingAppBundle:
            return "The app bundle could not be found."
        case .missingInfoPlist:
            return "The app's Info.plist could not be found."
        case .missingProvisioningProfile:
            return "A provisioning profile for the app could not be found."
        }
    }

    public var errorDescription: String? {
        return self.failureReason
    }

    public var failureReason: String? {
        return NSLocalizedString(self.rawDescription, comment: "")
    }

    public var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return NSLocalizedString("Connect to a Wi-Fi network, Bridge or a Wired network connection!", comment: "")
        case .noVPN, .invalidVPN:
            return NSLocalizedString("Make sure LocalDevVPN is connected and running!", comment: "")
        case .invalidPairingFile:
            return NSLocalizedString("Import a valid mobiledevicepairing file.", comment: "")
        case .serverNotFound:
            return NSLocalizedString("Make sure you're on the same Wi-Fi network as a computer running AltServer, or try connecting this device to your computer via USB.", comment: "")
        case .maximumAppIDLimitReached(let appName, let requiredAppIDs, let availableAppIDs, let expirationDate):
            let baseMessage = NSLocalizedString("Delete sideloaded apps to free up App ID slots.", comment: "")
            let availableText: String
            switch availableAppIDs {
            case 0: availableText = NSLocalizedString("none are available", comment: "")
            case 1: availableText = NSLocalizedString("only 1 is available", comment: "")
            default: availableText = String(format: NSLocalizedString("only %@ are available", comment: ""), NSNumber(value: availableAppIDs))
            }

            var message = ""
            if requiredAppIDs > 1 {
                let prefixMessage = String(format: NSLocalizedString("%@ requires %@ App IDs, but %@.", comment: ""), appName, NSNumber(value: requiredAppIDs), availableText)
                message = prefixMessage + " " + baseMessage + "\n\n"
            } else {
                message = baseMessage + " "
            }

            let dateComponents = Calendar.current.dateComponents([.day, .hour, .minute], from: Date(), to: expirationDate)
            let dateFormatter = DateComponentsFormatter()
            dateFormatter.maximumUnitCount = 1
            dateFormatter.unitsStyle = .full

            if let remainingTime = dateFormatter.string(from: dateComponents) {
                message += String(format: NSLocalizedString("You can register another App ID in %@.", comment: ""), remainingTime)
            }
            return message
        default:
            return nil
        }
    }
}
