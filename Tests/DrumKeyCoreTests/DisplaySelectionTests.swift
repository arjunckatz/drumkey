import Testing
@testable import DrumKeyCore

struct DisplaySelectionTests {
    @Test func prefersSecondaryAndFallsBackToMain() {
        #expect(DisplaySelection.resolve(availableIDs: ["main", "side", "third"], preferredID: nil) == "side")
        #expect(DisplaySelection.resolve(availableIDs: ["main"], preferredID: nil) == "main")
        #expect(DisplaySelection.resolve(availableIDs: [], preferredID: nil) == nil)
    }

    @Test func returnsToPreferredDisplayAfterReconnection() {
        let preference = "third"
        #expect(DisplaySelection.resolve(availableIDs: ["main", "side", "third"], preferredID: preference) == "third")
        #expect(DisplaySelection.resolve(availableIDs: ["main", "side"], preferredID: preference) == "side")
        #expect(DisplaySelection.resolve(availableIDs: ["main"], preferredID: preference) == "main")
        #expect(DisplaySelection.resolve(availableIDs: ["main", "side", "third"], preferredID: preference) == "third")
    }
}
