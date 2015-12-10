//
//  Declaration.swift
//  SourceKitten
//
//  Created by Paul Young on 12/10/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

import Foundation
import SwiftXPC

public struct Declaration {
    public let language: Language
    public let kind: DeclarationKindType?
    public let location: SourceLocation
    public let extent: (start: SourceLocation, end: SourceLocation)
    public let name: String?
    public let typeName: String?
    public let usr: String?
    public let declaration: String?
    public let documentationComment: String?
    public let children: [Declaration]
    public let accessibility: Accessibility?
}

// MARK: Hashable

extension Declaration: Hashable  {
    public var hashValue: Int {
        return usr?.hashValue ?? 0
    }
}

public func ==(lhs: Declaration, rhs: Declaration) -> Bool {
    return lhs.usr == rhs.usr &&
        lhs.location == rhs.location
}

// MARK: Comparable

/// A [strict total order](http://en.wikipedia.org/wiki/Total_order#Strict_total_order)
/// over instances of `Self`.
public func <(lhs: Declaration, rhs: Declaration) -> Bool {
    return lhs.location < rhs.location
}


// MARK: Objective-C Declaration

extension Declaration {
    public init?(cursor: CXCursor) {
        guard cursor.shouldDocument() else {
            return nil
        }
        language = .ObjC
        kind = cursor.objCKind()
        extent = cursor.extent()
        name = cursor.name()
        //typeName = cursor. // FIXME: no cursor.typeName()
        usr = cursor.usr()
        declaration = cursor.declaration()
        //documentationComment = cursor.parsedComment() // FIXME: Cannot assign value of type 'CXComment' to type 'String?'
        children = cursor.flatMap(Declaration.init).rejectPropertyMethods()
    }
    
    /// Returns the USR for the auto-generated getter for this property.
    ///
    /// - warning: can only be invoked if `type == .Property`.
    var getterUSR: String {
        return generateAccessorUSR(getter: true)
    }
    
    /// Returns the USR for the auto-generated setter for this property.
    ///
    /// - warning: can only be invoked if `type == .Property`.
    var setterUSR: String {
        return generateAccessorUSR(getter: false)
    }
    
    private func generateAccessorUSR(getter getter: Bool) -> String {
        assert(isProperty)
        guard let usr = usr else {
            fatalError("Couldn't extract USR")
        }
        guard let declaration = declaration else {
            fatalError("Couldn't extract declaration")
        }
        let pyStartIndex = usr.rangeOfString("(py)")!.startIndex
        let usrPrefix = usr.substringToIndex(pyStartIndex)
        let fullDeclarationRange = NSRange(location: 0, length: (declaration as NSString).length)
        let regex = try! NSRegularExpression(pattern: getter ? "getter\\s*=\\s*(\\w+)" : "setter\\s*=\\s*(\\w+:)", options: [])
        let matches = regex.matchesInString(declaration, options: [], range: fullDeclarationRange)
        if matches.count > 0 {
            let accessorName = (declaration as NSString).substringWithRange(matches[0].rangeAtIndex(1))
            return usrPrefix + "(im)\(accessorName)"
        } else if getter {
            return usr.stringByReplacingOccurrencesOfString("(py)", withString: "(im)")
        }
        // Setter
        let capitalFirstLetter = String(usr.characters[pyStartIndex.advancedBy(4)]).capitalizedString
        let restOfSetterName = usr.substringFromIndex(pyStartIndex.advancedBy(5))
        return "\(usrPrefix)(im)set\(capitalFirstLetter)\(restOfSetterName):"
    }
    
    var isProperty: Bool {
        guard let objCKind = kind as? ObjCDeclarationKind? where objCKind == .Property else {
            return false
        }
        return true
    }
}

extension SequenceType where Generator.Element == Declaration {
    /// Removes implicitly generated property getters & setters
    func rejectPropertyMethods() -> [Declaration] {
        let propertyGetterSetterUSRs = filter {
            $0.isProperty
        }.flatMap {
            [$0.getterUSR, $0.setterUSR]
        }
        return filter { !propertyGetterSetterUSRs.contains($0.usr!) }
    }
}


// MARK: - Swift Declaration

extension Declaration {
    public init(dictionary: XPCDictionary) {
        language = .Swift
        kind = SwiftDocKey.getKind(dictionary).flatMap { SwiftDeclarationKind(rawValue: $0) } // FIXME: why doesn't .flatMap(SwiftDeclarationKind.init) work here?
        
        if let file = SwiftDocKey.getDocFile(dictionary),
            line = SwiftDocKey.getDocLine(dictionary).map({ UInt32($0) }),
            column = SwiftDocKey.getDocColumn(dictionary).map({ UInt32($0) }) {
                
                if let offset = SwiftDocKey.getOffset(dictionary).map({ UInt32($0) }) {
                    location = SourceLocation(file: file, line: line, column: column, offset: offset)
                }
                
                if let parsedScopeStart = SwiftDocKey.getParsedScopeStart(dictionary).map({ UInt32($0) }),
                    parsedScopeEnd = SwiftDocKey.getParsedScopeEnd(dictionary).map({ UInt32($0) }) {
                        
                        let start = SourceLocation.init(file: file, line: line, column: column, offset: parsedScopeStart)
                        let end = SourceLocation.init(file: file, line: line, column: column, offset: parsedScopeEnd)
                        extent = (start: start, end: end)
                }
        }
        
        name = SwiftDocKey.getName(dictionary)
        typeName = SwiftDocKey.getTypeName(dictionary)
        usr = SwiftDocKey.getUSR(dictionary)
        declaration = SwiftDocKey.getParsedDeclaration(dictionary)
        //documentationComment = // FIXME
        //children = SwiftDocKey.getSubstructure(dictionary) // FIXME: Cannot assign value of type 'XPCArray?' to type '[DeclarationType]'
        //accessibility = // FIXME: Accessibility(rawValue: ...)
    }
}
