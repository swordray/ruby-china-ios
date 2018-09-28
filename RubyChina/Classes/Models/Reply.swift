//
//  Reply.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import Ladybug

class Reply: JSONCodable {

    var id: Int?
    var bodyHTML: String?
    var body: String?
    var topicId: Int?
    var createdAt: Date?
    var deleted: Bool?
    var user: User?
    var abilities: Ability?
    var index: Int?

    static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
        "bodyHTML": "body_html",
        "topicId": "topic_id",
        "createdAt": "created_at" <- format("yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"),
        "user": User.transformer,
    ]
}
