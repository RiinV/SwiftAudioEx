//
//  File.swift
//  
//
//  Created by Kateryna Peikova on 16.02.2022.
//

import Foundation

public class Stream {
    var name: String
    var playlistURL: String
    
    public init(nm: String, playlist: String) {
        name = nm
        playlistURL = playlist
    }

}

extension Stream: Equatable {
    public static func ==(lhs: Stream, rhs: Stream) -> Bool {
        return (lhs.name == rhs.name) && (lhs.playlistURL == rhs.playlistURL)
    }
}
