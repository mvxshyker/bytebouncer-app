# ByteBouncer

ByteBouncer is a native iOS application built with Swift and SwiftUI that integrates with the NextDNS API to manage and monitor your network protection settings right from your device.

## Features
- **NextDNS Integration**: Connects directly to your NextDNS account.
- **Onboarding Flow**: Simple setup process to securely input and store your NextDNS credentials locally (Profile ID and API Key).
- **Dashboard**: View and manage your network protection status.
- **Network Management**: Built-in network layer (`NextDNSNetworkManager`) to reliably handle API communication with NextDNS.

## Requirements
- Xcode 15.0+
- iOS 17.0+ (or target set in Xcode)
- Swift 5.9+

## Getting Started

1. Open the project in Xcode.
2. Build and run the project in the simulator or on a physical iOS device.
3. You will be greeted by the Onboarding screen:
   - Provide your **NextDNS Profile ID** and **NextDNS API Key**.
4. Once completed, you will have access to the dashboard.

## Testing

The project employs a Test-Driven Development (TDD) approach. Unit tests are included to ensure operations function correctly:
- `NextDNSNetworkManagerTests.swift`: Validates the networking layer functionality, including edge cases like `401 Unauthorized` responses and API key header formatting.
- `DashboardViewModelTests.swift`: Tests the core UI logic operating the Dashboard.

To run the tests:
- Press `Command-U` in Xcode to run the entire test suite.

## Design Origin
The UI structure was initially inspired by a [Figma Data Protection App Design](https://www.figma.com/design/BRSBdF2BYzKnlLwgsDXeFf/Data-Protection-App-Design), before being fully rewritten natively.