//
//  PlayerControlComponent.swift
//  CocoaBlast
//
//  Created by Marie Lin on 3/16/17.
//  Copyright © 2017 CocoaNuts. All rights reserved.
//

import GameplayKit

class PlayerControlComponent: GKComponent {
	/// A convenience property for the entity's sprite component.
	var spriteComponent: SpriteComponent? {
		return entity?.component(ofType: SpriteComponent.self)
	}
	
	/// The location of the player-controlled entity. 
	var playerPosition: CGPoint
	
	init(initialPlayerPosition: CGPoint) {
		self.playerPosition = initialPlayerPosition
		
		super.init()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	/// Move the player to a new location.
	func move(toPoint pos: CGPoint) {
		spriteComponent?.reposition(toPoint: pos)
	}
	
	/// Update the player's position each frame.
	override func update(deltaTime seconds: TimeInterval) {
		move(toPoint: playerPosition)
	}
	
	
}
