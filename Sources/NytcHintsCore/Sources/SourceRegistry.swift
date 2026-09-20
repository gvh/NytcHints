/// The selectable hint sources. The raw value is the command-line name.
/// To add a source, create a type conforming to `HintSource` and add a case here.
public enum SourceName: String, CaseIterable, Sendable {
    case cnet
    case mash

    public var source: any HintSource {
        switch self {
        case .cnet: CNETSource()
        case .mash: MashableSource()
        }
    }
}
