//
//  User.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import Ladybug

struct User: JSONCodable {

    var id: Int?
    var login: String?
    var name: String?
    var largeAvatarURL: URL?

    static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
        "largeAvatarURL": "avatar_url",
    ]

    static var current: User? {
        get {
            guard let json = UserDefaults.standard.value(forKey: "CurrentUser") as? [String: Any] else { return nil }
            return try? User(json: json)
        }

        set {
            let json = (try? newValue?.toJSON()) ?? nil
            UserDefaults.standard.set(json, forKey: "CurrentUser")
        }
    }

    var avatarURL: URL? {
        let lastPathComponent = "!large$".r?.replaceAll(in: largeAvatarURL?.lastPathComponent ?? "", with: "!md") ?? ""
        return largeAvatarURL?.deletingLastPathComponent().appendingPathComponent(lastPathComponent)
    }
}
