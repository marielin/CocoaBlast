//
//  SpriteComponent.swift
//  CocoaBlast
//
//  Created by Marie Lin on 3/16/17.
//  Copyright © 2017 CocoaNuts. All rights reserved.
//

import SpriteKit
import GameplayKit

class SpriteComponent: GKComponent {
	/// A reference to the sprite node that the entity controls.
	weak var spriteNode: SKSpriteNode?
	
	var position: CGPoint {
		if let spriteNode = spriteNode {
			return spriteNode.position
		}
		else {
			return CGPoint(x: 0, y: 0)
		}
	}
	
	var size: CGSize {
		if let spriteNode = spriteNode {
			return spriteNode.size
		}
		else {
			return CGSize(width: 0, height: 0)
		}
	}
	
	init(spriteNode: SKSpriteNode) {
		self.spriteNode = spriteNode
		
		super.init()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	/// Move the sprite to a new location.
	func reposition(toPoint pos: CGPoint) {
		spriteNode?.position = pos
	}
	
	/// This plays a destructive animation and removes a node from the scene. If applicable it removes its particle emitter first.
	func destroySprite() {
		if let particleComponent = self.entity?.component(ofType: ParticleComponent.self) {
			particleComponent.stopEmitting()
		}
		
		if let spriteNode = spriteNode {
			spriteNode.run(SKAction.removeFromParent())
		}
	}
}
