//
//  GameScene.swift
//  CocoaBlast
//
//  Created by Marie Lin on 3/16/17.
//  Copyright © 2017 CocoaNuts. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
	
	/// Keeps track of how much time has passed since the last update, for use in time-based updates.
    var lastUpdateTime : TimeInterval = 0
	
	/// Holds the game's entities so they won't be deallocated.
	var entities = Set<GKEntity>()
	
	/// Mananges components by type, allowing them to be accessed and updated by the scene. 
	var playerControlComponentSystem = GKComponentSystem(componentClass: PlayerControlComponent.self)
	var spriteComponentSystem = GKComponentSystem(componentClass: SpriteComponent.self)
	var blastingComponentSystem = GKComponentSystem(componentClass: BlastingComponent.self)
	
	/// Keeps track of whether the scene has been initialized, to prevent double scene setup.
	var sceneWasInitialized = false
	
	/// How many seconds between each enemy spawn.
	var enemySpawnRate: TimeInterval = 5
	var enemyBaseSpawnRate: TimeInterval = 0.5
	var timeUntilNextEnemySpawn: TimeInterval = 5
	var enemySpawnRateDecay = 0.9
	
	/// The velocity at which enemies approach.
	var enemyBaseVelocity: CGFloat = 200
	var enemyVelocityVariability: CGFloat = 150
    
    override func sceneDidLoad() {
        self.lastUpdateTime = 0
		
		// Initialize the scene exactly once.
		if !sceneWasInitialized {
			setUpEntities()
			self.physicsWorld.contactDelegate = self
			
			sceneWasInitialized = true
		}
    }
	
	/// Creates a ship entity from scratch.
	func makeShip() -> GKEntity {
		// Initialize the GameplayKit entity.
		let entity = GKEntity()
		
		// Grab the node from the GameScene.sks file and name it "ship".
		let node = self.childNode(withName: "shipNode") as! SKSpriteNode
		node.name = "ship"
		node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
		node.physicsBody?.affectedByGravity = false
		node.physicsBody?.allowsRotation = false
		node.physicsBody?.categoryBitMask = 0x1
		node.physicsBody?.collisionBitMask = 0x2
		node.physicsBody?.contactTestBitMask = 0x2

		// Create components for the ship entity.
		let spriteComponent = SpriteComponent(spriteNode: node)
		let playerControlComponent = PlayerControlComponent(initialPlayerPosition: node.position)
		let blastingComponent = BlastingComponent()
		let healthComponent = HealthComponent(maxHealth: 1)
		
		// Add those components to the relevant component systems.
		playerControlComponentSystem.addComponent(playerControlComponent)
		spriteComponentSystem.addComponent(spriteComponent)
		blastingComponentSystem.addComponent(blastingComponent)
		
		// Add the components to the entity itself.
		entity.addComponent(GKSKNodeComponent(node: node)) // This component is necessary to access a node's entity from the node.
		entity.addComponent(spriteComponent)
		entity.addComponent(playerControlComponent)
		entity.addComponent(blastingComponent)
		entity.addComponent(healthComponent)
		
		return entity
	}
	
	func makeAsteroid(atPosition pos: CGPoint, withVelocity velocity: CGFloat) -> GKEntity {
		let entity = GKEntity()
		
		let node = SKSpriteNode(imageNamed: "bokeh")
		node.name = "asteroid"
		self.addChild(node)
		node.position = pos
		node.xScale = 1.5
		node.yScale = 1.5
		node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
		node.physicsBody?.affectedByGravity = false
		node.physicsBody?.velocity = CGVector(dx: 0, dy: velocity)
		node.physicsBody?.allowsRotation = true
		node.physicsBody?.categoryBitMask = 0x2
		node.physicsBody?.collisionBitMask = 0x3
		node.physicsBody?.contactTestBitMask = 0x7
		
		let spriteComponent = SpriteComponent(spriteNode: node)
		let healthComponent = HealthComponent(maxHealth: 3)
		
		spriteComponentSystem.addComponent(spriteComponent)
		
		entity.addComponent(GKSKNodeComponent(node: node))
		entity.addComponent(spriteComponent)
		entity.addComponent(healthComponent)
		
		return entity
	}
	
	func makeProjectile(withVelocity velocity: CGFloat, atPosition position: CGPoint, withRadius radius: CGFloat) -> GKEntity {
		let entity = GKEntity()
		
		// Create and attach a sprite component to the new projectile entity.
		let node = SKSpriteNode(color: SKColor.white, size: CGSize(width: radius, height: radius))
		node.name = "projectile"
		node.position = position
		node.physicsBody = SKPhysicsBody(circleOfRadius: radius)
		node.physicsBody?.affectedByGravity = false
		node.physicsBody?.velocity = CGVector(dx: 0, dy: velocity)
		node.physicsBody?.allowsRotation = false
		node.physicsBody?.categoryBitMask = 0x4
		node.physicsBody?.collisionBitMask = 0x0
		node.physicsBody?.contactTestBitMask = 0x2
		self.addChild(node)
		
		let projectileSpriteComponent = SpriteComponent(spriteNode: node)
		let projectileParticleComponent = ParticleComponent(particleName: "Energy", scene: self)
		let projectileHealthComponent = HealthComponent(maxHealth: 1)
		
		spriteComponentSystem.addComponent(projectileSpriteComponent)
		
		entity.addComponent(GKSKNodeComponent(node: node))
		entity.addComponent(projectileSpriteComponent)
		entity.addComponent(projectileParticleComponent)
		entity.addComponent(projectileHealthComponent)
		
		return entity
	}

	/// Sets up the initial entities for the scene, which in this scenario is just the ship.
	func setUpEntities() {
		entities.insert(makeShip())
	}
	
	/// Handle collisions based on the identity of the objects the collided.
	func didBegin(_ contact: SKPhysicsContact) {
		// Determine the entities that own each node in the collision.
		guard let entityA = contact.bodyA.node?.entity else {
			return // We cannot find the corresponding entity for body A.
		}
		guard let entityB = contact.bodyB.node?.entity else {
			return // We cannot find the corresponding entity for body A.
		}
		
		// Reduce the health of each entity involved in the collision.
		entityA.component(ofType: HealthComponent.self)?.reduceHealth(byAmount: 1)
		entityB.component(ofType: HealthComponent.self)?.reduceHealth(byAmount: 1)
	}
	
	func spawnEnemy() {
		// Generate a random number betwen 0.0 and 1.0 using GameplayKit. Use it to create a position for the enemy to spawn from.
		var random = GKRandomSource.sharedRandom().nextUniform()
		let xPosition: CGFloat = CGFloat(0.5 - random * 0.8) * self.size.width
		let yPosition: CGFloat = 700
		
		// Also generate a random velocity.
		random = GKRandomSource.sharedRandom().nextUniform()
		let velocity = CGFloat(random) * enemyVelocityVariability + enemyBaseVelocity
		
		let entity = makeAsteroid(atPosition: CGPoint(x: xPosition, y: yPosition), withVelocity: -velocity)
		entities.insert(entity)
	}

	func removeEntity(_ entity: GKEntity) {
		removeAllComponents(fromEntity: entity)
		entities.remove(entity)
	}
	
	func removeAllComponents(fromEntity entity: GKEntity) {
		entity.removeComponent(ofType: PlayerControlComponent.self)
		entity.removeComponent(ofType: BlastingComponent.self)
		entity.removeComponent(ofType: SpriteComponent.self)
	}
	
	/// Update the player position by updating the player control component.
	func updatePlayerPosition(toPoint pos: CGPoint) {
		for case let component as PlayerControlComponent in playerControlComponentSystem.components {
			component.playerPosition.x = pos.x
			component.playerPosition.y = pos.y + 50 // +10 to avoid finger obstruction
		}
	}
    
    func touchDown(atPoint pos : CGPoint) {
		updatePlayerPosition(toPoint: pos)
    }
    
    func touchMoved(toPoint pos : CGPoint) {
		updatePlayerPosition(toPoint: pos)
    }
    
    func touchUp(atPoint pos : CGPoint) {
		updatePlayerPosition(toPoint: pos)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
		
		// Generate enemies
		if timeUntilNextEnemySpawn <= 0 {
			spawnEnemy()
			enemySpawnRate *= enemySpawnRateDecay
			timeUntilNextEnemySpawn = enemySpawnRate + enemyBaseSpawnRate
		}
		else {
			timeUntilNextEnemySpawn -= dt
		}
		
		// Update entities
		for entity in self.entities {
			entity.update(deltaTime: dt)
		}
		
		// Update the component systems.
		for case let component as PlayerControlComponent in playerControlComponentSystem.components {
			component.update(deltaTime: dt)
		}
		
		for case let component as BlastingComponent in blastingComponentSystem.components {
			component.update(deltaTime: dt)
			
			// If the blasting component need a blast to be created, create one and add it to the set of entities.
			if component.blastFired {
				let projectileEntity = makeProjectile(withVelocity: component.projectileVelocity, atPosition: component.projectilePosition, withRadius: component.projectileSize)
				spriteComponentSystem.addComponent(foundIn: projectileEntity)
				entities.insert(projectileEntity)
				
				component.blastFired = false
			}
		}
        
        self.lastUpdateTime = currentTime
    }
}
