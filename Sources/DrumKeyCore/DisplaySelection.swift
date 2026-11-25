/// Available displays are ordered with the primary display first.
public enum DisplaySelection {
    public static func resolve(availableIDs: [String], preferredID: String?) -> String? {
        if let preferredID, availableIDs.contains(preferredID) {
            return preferredID
        }
        return availableIDs.dropFirst().first ?? availableIDs.first
    }
}
