//
//  Topic.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import Ladybug

struct Topic: JSONCodable {

    var id: Int?
    var title: String?
    var createdAt: Date?
    var repliesCount: Int?
    var repliedAt: Date?
    var nodeId: Int?
    var nodeName: String?
    var body: String?
    var bodyHTML: String?
    var hits: Int?
    var abilities: Ability?
    var user: User?

    static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
        "createdAt": "created_at" <- format("yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"),
        "repliesCount": "replies_count",
        "repliedAt": "replied_at" <- format("yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"),
        "nodeId": "node_id",
        "nodeName": "node_name",
        "bodyHTML": "body_html",
        "user": User.transformer,
    ]
}
