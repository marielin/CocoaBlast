//
//  ParticleComponent.swift
//  CocoaBlast
//
//  Created by Marie Lin on 3/16/17.
//  Copyright © 2017 CocoaNuts. All rights reserved.
//

import GameplayKit
import SpriteKit

class ParticleComponent: GKComponent {
	/// A convenience property for the entity's sprite component.
	var spriteComponent: SpriteComponent? {
		return entity?.component(ofType: SpriteComponent.self)
	}
	
	/// The node that generates the particles in the particle effect. 
	let particleEmitter : SKEmitterNode
	
	/// Keeps track of whether the entity's sprite has the particle effect attached or not. 
	var hasEmitter = false
	
	/// A reference to the game scene, so that the particles can be applied to the scene's cordinate space instead of the projectile's.
	var scene: SKScene
	
	init(particleName: String, scene: SKScene) {
		self.scene = scene
		
		// Create the particle emitter.
		self.particleEmitter = SKEmitterNode(fileNamed: particleName)!
		
		super.init()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	/// Remove the emitter node from the entity's sprite.
	func stopEmitting() {
		particleEmitter.particleBirthRate = 0
		particleEmitter.removeFromParent()
	}
	
	override func update(deltaTime seconds: TimeInterval) {
		if !hasEmitter, let spriteComponent = spriteComponent {
			// If no target node was set, the spawned particles would follow the projectile. By assigning the target node as the scene the particles will spawn directly into the scene, creating a more realistic effect.
			particleEmitter.targetNode = scene
			spriteComponent.spriteNode?.addChild(particleEmitter)
		}
		
		hasEmitter = (spriteComponent != nil)
	}
}
