import LiveNotchExtensionKit

@main
struct LiveNotchXcodeSample {
    static func main() {
        print("LiveNotchExtensionKit version: \(LiveNotchExtensionKitVersion)")
        let descriptor = LiveNotchLiveActivityDescriptor(
            id: "sample-activity",
            title: "Sample Activity",
            subtitle: "Demo",
            leadingIcon: .symbol(name: "star.fill", size: 16)
        )
        print("Descriptor valid: \(descriptor.isValid)")
        _ = LiveNotchClient.shared
        print("LiveNotchClient shared instance ready")
    }
}
