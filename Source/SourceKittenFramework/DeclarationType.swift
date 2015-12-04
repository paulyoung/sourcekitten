//
//  DeclarationType.swift
//  SourceKitten
//
//  Created by Paul Young on 12/4/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

public protocol DeclarationType: Hashable, Comparable {
    var language: Language { get }
    var kind: DeclarationKindType? { get }
    var location: SourceLocation { get }
    var extent: Range<SourceLocation> { get } // FIXME: Type 'SourceLocation' does not conform to protocol 'ForwardIndexType'
    var name: String? { get }
    var typeName: String? { get }
    var usr: String? { get }
    var declaration: String? { get }
    var documentationComment: String? { get }
    var children: [AnyDeclarationType] { get }
}

// MARK: Hashable

extension DeclarationType  {
    public var hashValue: Int {
        return usr?.hashValue ?? 0
    }
}

public func ==(lhs: AnyDeclarationType, rhs: AnyDeclarationType) -> Bool {
    return lhs.usr == rhs.usr &&
        lhs.location == rhs.location
}

// MARK: Comparable

/// A [strict total order](http://en.wikipedia.org/wiki/Total_order#Strict_total_order)
/// over instances of `Self`.
public func <(lhs: AnyDeclarationType, rhs: AnyDeclarationType) -> Bool {
    return lhs.location < rhs.location
}

public struct AnyDeclarationType: DeclarationType {
    public let language: Language
    public let kind: DeclarationKindType?
    public let location: SourceLocation
    public let extent: Range<SourceLocation> // FIXME: Type 'SourceLocation' does not conform to protocol 'ForwardIndexType'
    public let name: String?
    public let typeName: String?
    public let usr: String?
    public let declaration: String?
    public let documentationComment: String?
    public let children: [AnyDeclarationType]
    
    init<T: DeclarationType>(_ declarationType: T) {
        language = declarationType.language
        kind = declarationType.kind
        location = declarationType.location
        extent = declarationType.extent
        name = declarationType.name
        typeName = declarationType.typeName
        usr = declarationType.usr
        declaration = declarationType.declaration
        documentationComment = declarationType.documentationComment
        children = declarationType.children
    }
}
