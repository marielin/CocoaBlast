//
//  HealthComponent.swift
//  CocoaBlast
//
//  Created by Marie Lin on 3/16/17.
//  Copyright © 2017 CocoaNuts. All rights reserved.
//

import GameplayKit

class HealthComponent: GKComponent {
	/// A convenience property for the entity's sprite component.
	var spriteComponent: SpriteComponent? {
		return entity?.component(ofType: SpriteComponent.self)
	}
	
	var currentHealth: Int
	var maxHealth: Int
	
	/// When we've destroyed this entity, flag it so we don't attempt to destroy the entity multiple times.
	var destroyed = false
	
	init(maxHealth: Int) {
		self.maxHealth = maxHealth
		self.currentHealth = maxHealth
		
		super.init()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func reduceHealth(byAmount damage: Int) {
		currentHealth -= damage
	}
	
	override func update(deltaTime seconds: TimeInterval) {
		// If the ship is below 0 health and we haven't already successfully destroyed the entity, attempt to destroy it.  
		if !destroyed, currentHealth <= 0 {
			if let spriteComponent = spriteComponent {
				spriteComponent.destroySprite()
				destroyed = true
			}
		}
	}
}
