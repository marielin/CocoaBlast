//
//  BlastingComponent.swift
//  CocoaBlast
//
//  Created by Marie Lin on 3/16/17.
//  Copyright © 2017 CocoaNuts. All rights reserved.
//

import GameplayKit

class BlastingComponent: GKComponent {
	/// A convenience property for the entity's sprite component.
	var spriteComponent: SpriteComponent? {
		return entity?.component(ofType: SpriteComponent.self)
	}
	
	/// Define the size of projectiles.
	let projectileSize: CGFloat = 20
	
	/// Define the speed and direction of projectiles.
	let projectileVelocity: CGFloat = 800
	
	/// Define period of time between projectile spawns. 
	let projectilePeriod: TimeInterval = 0.3
	var timeUntilNextProjectile: TimeInterval = 0
	
	/// A flag that lets the GameScene know that a projectile needs to be made. 
	var blastFired: Bool = false
	
	/// Calculates the position that projectiles should be spawned at for this entity.
	var projectilePosition: CGPoint {
		guard let spriteComponent = spriteComponent else {
			return CGPoint(x: 0, y: 0) // We shouldn't be shooting projectiles without a sprite to originate from.
		}
		
		var position: CGPoint = CGPoint()
		position.x = spriteComponent.position.x
		position.y = spriteComponent.position.y + (spriteComponent.size.height / 2.0)
		return position
	}
	
	override func update(deltaTime seconds: TimeInterval) {
		// If it's been long enough since our last blast, send another blast. 
		if timeUntilNextProjectile <= 0 {
			blastFired = true
			timeUntilNextProjectile = projectilePeriod
		}
		else {
			timeUntilNextProjectile -= seconds
		}
	}
}
