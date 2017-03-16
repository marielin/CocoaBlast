Hello and welcome to the CocoaNuts iOS Game Development demo! Today we will be making a simple space shooting game using SpriteKit and GameplayKit. Be advised that this is a somewhat advanced demo with lots of code.

---

# Part 1: Getting Started
#### Our first task: draw a space ship on the screen and move it around with our finger! 

Start a new Xcode project and use the iOS Game template. 


Try running the template code: it's actually a pretty good start to learning your way around SpriteKit!

However to start making CocoaBlast, you'll need to get rid of a lot of the template code. You can delete code until it looks something like the code **below**, but you can also just copy-paste.

```
import SpriteKit
import GameplayKit

class GameScene: SKScene {
	
    var lastUpdateTime : TimeInterval = 0
    
    override func sceneDidLoad() {
        self.lastUpdateTime = 0
		
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
		
    }
    
    func touchMoved(toPoint pos : CGPoint) {
		
    }
    
    func touchUp(atPoint pos : CGPoint) {
		
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
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        self.lastUpdateTime = currentTime
    }
}
```

---

Now, before we can begin properly, we need to introduce the Entity-Component architecture. I highly recommend reading over [Apple's documentation](https://developer.apple.com/library/content/documentation/General/Conceptual/GameplayKit_Guide/EntityComponent.html) on Entity-Component, but I'll give a brief explanation here. Essentially the Entity-Component architecture is all about small modules ("components") that you can attach to more generalized objects ("entities"). This way, the functionality of one object in our game can be easily attached to other kinds of objects, unlike with a traditional, inheritence-based architecture. 

![Entity-Component Diagram](https://developer.apple.com/library/content/documentation/General/Conceptual/GameplayKit_Guide/Art/entity_component_4_2x.png)

We will be creating several components for use in our game, using the GameplayKit framework. 

-

Start by creating a new Cocoa Touch class called SpriteComponent. When attached to an entity, this component will help manage an entity's visual representation on the screen. 

Type this code into your new SpriteComponent class. 

```
import SpriteKit
import GameplayKit

class SpriteComponent: GKComponent {
	/// A reference to the sprite node that the entity controls.
	weak var spriteNode: SKSpriteNode?
	
	init(spriteNode: SKSpriteNode) {
		self.spriteNode = spriteNode
		
		super.init()
	}
	
	/// Move the sprite to a new location.
	func reposition(toPoint pos: CGPoint) {
		spriteNode?.position = pos
	}
}

```

This component will let your next component—the player control component—reposition the entity's sprite without needing to directly interface with SpriteKit. It's all encapsulated! 

You might notice that you're getting an error. That's because Swift requires you to add this second initializer:

```
required init?(coder aDecoder: NSCoder) {
	fatalError("init(coder:) has not been implemented")
}
```

Don't worry about it for now. 

-

Now create a new Cocoa Touch class called "PlayerControlComponent", and type in this code:

```
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
	
	/// Move the player to a new location.
	func move(toPoint pos: CGPoint) {
		spriteComponent?.reposition(toPoint: pos)
	}
	
	/// Update the player's position each frame.
	override func update(deltaTime seconds: TimeInterval) {
		move(toPoint: playerPosition)
	}
}
```

Again, insert the `init?(coder aDecoder: NSCoder)` initializer as Xcode tells you to. This component will be the interface between touch input to the screen and the on-screen representation of your ship. 

-

It's finally time to work on GameScene itself. There's a lot of code here, so buckle in!

First, add our local variables. under the lastUpdateTime variable. 

```
/// Keeps track of how much time has passed since the last update, for use in time-based updates.
var lastUpdateTime : TimeInterval = 0
	
/// Holds the game's entities so they won't be deallocated.
var entities = Set<GKEntity>()
	
/// Mananges components by type, allowing them to be accessed and updated by the scene. 
var playerControlComponentSystem = GKComponentSystem(componentClass: PlayerControlComponent.self)
var spriteComponentSystem = GKComponentSystem(componentClass: SpriteComponent.self)
	
/// Keeps track of whether the scene has been initialized, to prevent double scene setup.
var sceneWasInitialized = false
```

Next, let's add the scene "initialization" function. This code runs when the scene initially loads, so we use it to set up the scene. However, it *actually* runs this code twice, so we need to use a flag to make sure we only set up our entities once. 

```
override func sceneDidLoad() {
    self.lastUpdateTime = 0
	
	// Initialize the scene exactly once.
	if !sceneWasInitialized {
		setUpEntities()
		
		sceneWasInitialized = true
	}
}
```

-

This next part is the really juicy bit. Here we create the entity representing the ship, and the components the comprise it. All put together this will give us a ship that can be controlled with player input. 

```
/// Creates a ship entity from scratch.
func makeShip() -> GKEntity {
	// Initialize the GameplayKit entity.
	let entity = GKEntity()
	
	// Grab the node from the GameScene.sks file and name it "ship".
	let node = self.childNode(withName: "shipNode") as! SKSpriteNode
	node.name = "ship"

	// Create components for the ship entity.
	let spriteComponent = SpriteComponent(spriteNode: node)
	let playerControlComponent = PlayerControlComponent(initialPlayerPosition: node.position)
	
	// Add those components to the relevant component systems.
	playerControlComponentSystem.addComponent(playerControlComponent)
	spriteComponentSystem.addComponent(spriteComponent)
	
	// Add the components to the entity itself.
	entity.addComponent(GKSKNodeComponent(node: node)) // This component is necessary to access a node's entity from the node.
	entity.addComponent(spriteComponent)
	entity.addComponent(playerControlComponent)
	
	return entity
}

/// Sets up the initial entities for the scene, which in this scenario is just the ship.
func setUpEntities() {
	entities.insert(makeShip())
}
```

If that is confusing for you, please ask for help from another CocoaNuts member! We are all very friendly.

-

There are just a few more things left before we can see our ship moving around on the screen. We need to add this code to actually update the player's position in response to touch events. 

```
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
```

This code uses methods from the template code to update the player position. (The `touchesBegan`, `touchesMoved`, `touchesEnded`, and `touchesCancelled` methods are actually what handle touch events. The `touchDown`, `touchMoved`, and `touchUp` methods are there for convenience and code legibility.)

-

The very last thing we need to do to get our ship moving around on the screen is to add this little bit of code to our update function, after the for-loop where we update the entities: 

```
// Update the component systems.
for case let component as PlayerControlComponent in playerControlComponentSystem.components {
	component.update(deltaTime: dt)
}
```

Components that are a part of component systems won't update along with their entities—they need to be updated separately. That is why we need a new loop to update our player control component systems. 

-

All put together, your GameScene class should look like this:

```
import SpriteKit
import GameplayKit

class GameScene: SKScene {
	
	/// Keeps track of how much time has passed since the last update, for use in time-based updates.
    var lastUpdateTime : TimeInterval = 0
	
	/// Holds the game's entities so they won't be deallocated.
	var entities = Set<GKEntity>()
	
	/// Mananges components by type, allowing them to be accessed and updated by the scene. 
	var playerControlComponentSystem = GKComponentSystem(componentClass: PlayerControlComponent.self)
	var spriteComponentSystem = GKComponentSystem(componentClass: SpriteComponent.self)
	
	/// Keeps track of whether the scene has been initialized, to prevent double scene setup.
	var sceneWasInitialized = false
    
   override func sceneDidLoad() {
       self.lastUpdateTime = 0
		
		// Initialize the scene exactly once.
		if !sceneWasInitialized {
			setUpEntities()
			
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

		// Create components for the ship entity.
		let spriteComponent = SpriteComponent(spriteNode: node)
		let playerControlComponent = PlayerControlComponent(initialPlayerPosition: node.position)
		
		// Add those components to the relevant component systems.
		playerControlComponentSystem.addComponent(playerControlComponent)
		spriteComponentSystem.addComponent(spriteComponent)
		
		// Add the components to the entity itself.
		entity.addComponent(GKSKNodeComponent(node: node)) // This component is necessary to access a node's entity from the node.
		entity.addComponent(spriteComponent)
		entity.addComponent(playerControlComponent)
		
		return entity
	}

	/// Sets up the initial entities for the scene, which in this scenario is just the ship.
	func setUpEntities() {
		entities.insert(makeShip())
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
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
		
		// Update the component systems.
		for case let component as PlayerControlComponent in playerControlComponentSystem.components {
			component.update(deltaTime: dt)
		}
        
        self.lastUpdateTime = currentTime
    }
}
```

To actually get this code to run you'll need to make a minor tweak to the GameViewController. Since we're not using the given entity or graph arrays, we need to remove these lines of code from the GameViewController:

```             
// Copy gameplay related content over to the scene
sceneNode.entities = scene.entities
sceneNode.graphs = scene.graphs
```

Now when you run the game (press Command-R, or press the play button in the upper left), you should be able to move your spaceship around on the screen! Try to troubleshoot your code or ask a CocoaNuts member if it isn't working. 

You can also remove the "Hello World!" label from the SpriteKit scene. Simply click on GameScene.sks in the left sidebar, click on the label in the scene and press delete. 

---

# Part 2: Shooting and Particles
#### Our second task: have glowing projectiles shoot out from the ship! 

To accomplish this we will need two new components: a component for blasting, and a component for particle effects. We'll start with the BlastingComponent! As with the last two components, make a new Cocoa Touch class, import GameplayKit, and type in this code: 

```
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
```

All these variables define how and when a projectile is fired. However, to calculate where projectiles will be fired, we need to know the position of the entity's sprite. Since our sprite component deals with all of our SpriteKit needs, we can add this functionality to that component. Add this computed property to the SpriteComponent class: 

```
var position: CGPoint {
	if let spriteNode = spriteNode {
		return spriteNode.position
	}
	else {
		return CGPoint(x: 0, y: 0)
	}
}
```

This will allow us to access the sprite position from any component. While we're at it, let's add a property for size: 

```
var size: CGSize {
	if let spriteNode = spriteNode {
		return spriteNode.size
	}
	else {
		return CGSize(width: 0, height: 0)
	}
}
```

Now we can finally add the initial projectile position to our blasting component. 

```	
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
```

We also need to communicate to the scene when we want a projectile entity to be rendered in the game. For that purpose we will create a flag that the GameScene will monitor with every update cycle. 

```
/// A flag that lets the GameScene know that a projectile needs to be made. 
var blastFired: Bool = false
```

Now we just need to add our update function. 

```
override func update(deltaTime seconds: TimeInterval) {
	if timeUntilNextProjectileSpawn <= 0 {
		shotFired = true
		timeUntilNextProjectileSpawn = projectileFrequency
	}
	else {
		timeUntilNextProjectileSpawn -= seconds
	}
}
```

Hooray! Let's make our GameScene compatible with this component. Remember, it's our GameScene that actually creates and manages our entities, and our projectiles are indeed entities. 

-

We'll need to make a new component system for this component, since it communicates with the scene. Add this line of code under your other component system declarations: 

```
var blastingComponentSystem = GKComponentSystem(componentClass: blastingComponent.self)
```

We'll also need to actually create and add this component to the ship factory method we made earlier, `makeship()`. You can do so by adding these three lines of code to that function:

```
	let blastingComponent = BlastingComponent()
	blastingComponentSystem.addComponent(blastingComponent)
	entity.addComponent(blastingComponent)
```

Now for another big factory method, to create our projectile entities with. 

```
func makeProjectile(withVelocity velocity: CGFloat, atPosition position: CGPoint, withRadius radius: CGFloat) -> GKEntity {
	let entity = GKEntity()
	
	// Create and attach a sprite component to the new projectile entity.
	let node = SKSpriteNode(color: SKColor.white, size: CGSize(width: radius, height: radius))
	node.name = "projectile"
	node.position = position
	node.physicsBody = SKPhysicsBody(circleOfRadius: radius)
	node.physicsBody?.affectedByGravity = false
	node.physicsBody?.velocity = CGVector(dx: 0, dy: velocity)
	node.physicsBody?.allowsRotation = false	self.addChild(node)
	
	let projectileSpriteComponent = SpriteComponent(spriteNode: node)
	
	spriteComponentSystem.addComponent(projectileSpriteComponent)
	
	entity.addComponent(GKSKNodeComponent(node: node))
	entity.addComponent(projectileSpriteComponent)
	
	return entity
}
```

This factory method takes several arguments for the parameters of the projectile, because all of the parameters are managed in the blasting component. 

Finally, we add code to the update function to manage the blasting component. 

```
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
```

Now you should have a space ship blasting white pellets that you can move around the screen! Next, it's time to apply particle effects to the pellets. 

-

Let's create another Cocoa Touch class, this time called ParticleComponent. Import SpriteKit and GameplayKit, then type this into the class: 

```
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
```

-

Let's take a small break and do something more visual. It's time to create your actual particle effect! Create a new file, and instead of making a Cocoa Touch class, scroll down until you find the SpriteKit Particle File, under "Resource". You can use any starting template you want, but I use fire myself. Name it "Energy". 

Toy around with the values until you get something you like. If you'd like to know what my particle is, here are its settings:

// TODO: Add image

I recommend leaving your emitter birthrate low, for performance reasons. Also, for the particle velocity I've used in my code, a particle lifetime of around `0.2` seems to work best. You can modify this parameter, however. 

-

Now we have to make a few small changes to GameScene to get particles to work. Thankfully, this time the changes are very minimal. We only need to create and add the particle components to the particles, which you can do by adding these two lines of code to the `makeParticle()`:

```
let projectileParticleComponent = ParticleComponent(particleName: "Energy", scene: self)
entity.addComponent(projectileParticleComponent)
```

Now if you run the game you should be able to see your ship emitting energy beams! If you modify your `makeParticle()` factory method and change your projectiles' color from `SKColor.white` to `SKColor.clear`, it will look even better! You can move on the the next section if you'd like, but if you're tired you can poke around with the projectile parameters and see what looks good. 

---

# Part 3: Collisions and Damage
#### Our third task: add in some danger!

In this final segment we will be adding in obstacles for your ship to dodge and blast through. 

Let's start by making a health component for our entities, so we can destroy them. We'll give them a health value, a maximum health, and a few properties and methods so we can get rid of them when they've gone below zero health. Make a new Cocoa Touch class and type this in: 

```
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
	
	func reduceHealth(byAmount damage: Int) {
		currentHealth -= damage
	}
	
	override func update(deltaTime seconds: TimeInterval) {
		if !destroyed, currentHealth <= 0 {
			if let spriteComponent = spriteComponent {
				spriteComponent.destroySprite(withAction: destructAction) // Note that we have not written this function yet.
				destroyed = true
			}
		}
	}
}
```

The update function will let us destroy the sprite when health goes below zero, but first we need to add this functionality to the SpriteComponent. Go ahead and add this method to SpriteComponent: 

```
/// This plays a destructive animation and removes a node from the scene. If applicable it removes its particle emitter first. 
func destroySprite(withAction action: SKAction) {
	if let particleComponent = self.entity?.component(ofType: ParticleComponent.self) {
		particleComponent.stopEmitting()
	}
	
	if let spriteNode = spriteNode {
		spriteNode.run(SKAction.sequence([action, SKAction.removeFromParent()]))
	}
}
```

Now by adding just these two lines of code to our `makeShip()` and `makeProjectile()` functions, we have added health points to our ship! 

#### makeShip()

```
let healthComponent = HealthComponent(maxHealth: 1)
entity.addComponent(healthComponent)
```

#### makeProjectile() 

```
let projectileHealthComponent = HealthComponent(maxHealth: 1)
entity.addComponent(projectileHealthComponent)
```

-

Okay, so now we have a health system and a way to get rid of nodes, but how do we detect collisions so we can meaningfully use our new health system? We use SpriteKit's `SKPhysicsContactDelegate` protocol! To do this, we must make our GameScene conform to the `SKPhysicsContactDelegate` protocol, which you can do by adding it to the class declaration like this: 

```
class GameScene: SKScene, SKPhysicsContactDelegate { ... }
```

Now we have access to the methods `didBegin(_ contact: SKPhysicsContact)` and `didEnd(_ contact: SKPhysicsContact)` for detecting collisions. We will only be using `didBegin(_ contact: SKPhysicsContact)` for this tutorial, however. Implement this method in your `GameScene` like this: 

```
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
```

You'll have to add `self.physicsWorld.contactDelegate = self` to your `sceneDidLoad()` method to actually assign your `GameScene` as the physics contact delegate.

Now we have a way to handle collisions in the game! However, we have nothing for your ship to collide *with*. Let's add in some obstacles to the game. 

-

Adding these variables and functions to the game will allow you to make asteroids that you can shoot down. 

```
/// How many seconds between each enemy spawn.
var enemySpawnRate: TimeInterval = 5
var enemyBaseSpawnRate: TimeInterval = 0.5
var timeUntilNextEnemySpawn: TimeInterval = 5
var enemySpawnRateDecay = 0.9
	
/// The velocity at which enemies approach.
var enemyBaseVelocity: CGFloat = 200
var enemyVelocityVariability: CGFloat = 150

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
```

You may notice that `spawnEnemy()` uses another GameplayKit feature, GKRandomSource. Definitely look into this on your own time if it interests you!

To finish implementing asteroid rendering, add this chunk of code to the update method to spawn the enemies at an increasing rate. 

```
// Generate enemies
if timeUntilNextEnemySpawn <= 0 {
	spawnEnemy()
	enemySpawnRate *= enemySpawnRateDecay
	timeUntilNextEnemySpawn = enemySpawnRate + enemyBaseSpawnRate
}
else {
	timeUntilNextEnemySpawn -= dt
}
```

You should now see asteroids spawning from overhead!

You may notice that asteroids aren't colliding with your ship. That's because we never gave your ship a physics body! Let's do that now. Add these lines of code to your `makeShip()` function: 

```
node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
node.physicsBody?.affectedByGravity = false
node.physicsBody?.allowsRotation = false
node.physicsBody?.categoryBitMask = 0x1
node.physicsBody?.collisionBitMask = 0x2
node.physicsBody?.contactTestBitMask = 0x2
```

Now asteroids should bounce off your ship. 

-

You might be thinking: "but what happened to our health system?" If you set a breakpoint inside our collision detection method, you'll notice that it's not even being called! This is because we haven't set up our collision bitmasks yet. They're a bit complex to explain, so I would recommend looking at [Apple's Documentation](https://developer.apple.com/reference/spritekit/skphysicsbody/1519869-categorybitmask) for it. You can figure it out yourself, or just add the code below to their respective methods. 

#### makeShip()

```
node.physicsBody?.categoryBitMask = 0x1
node.physicsBody?.collisionBitMask = 0x2
node.physicsBody?.contactTestBitMask = 0x2
```

#### makeAsteroid()

```
node.physicsBody?.categoryBitMask = 0x2
node.physicsBody?.collisionBitMask = 0x3
node.physicsBody?.contactTestBitMask = 0x7
```

#### makeProjectile()

```
node.physicsBody?.categoryBitMask = 0x4
node.physicsBody?.collisionBitMask = 0x0
node.physicsBody?.contactTestBitMask = 0x2
```

Now ships should disappear when they take too much damage. 

-

The very last thing I've prepared is using SKActions to do explosion animations. We'll start with something simple. If you've gotten this far you can probably figure out how to use the animation editor. Open the Actions.sks file and use the + button in the lower left to make a new animation. Call it whatever you want: mine is called "Boom". Try anything you think would look like a nice booming animation! Then modify `destroySprite()` to take an SKAction as an argument and play an SKAction sequence, like such: 

```
func destroySprite(withAnimation destructAnimation: SKAction) { ...
	spriteNode.run(SKAction.sequence([destructAnimation, SKAction.removeFromParent()])
... }
```

You can then initialize your SpriteComponent to take a destruct animation as an initialization parameter, and then use that in the destroySprite to make a nice looking pseudo-explosion. 

---

# Congrats!

You've somehow finished this demo! It's a little buggy, but I hope you learned a lot about SpriteKit and GameplayKit. At least, enough to be confident learning more on your own. 

In case you're looking for more ways to work on this demo, you can try the following!

- Try separating the physics functionality out into a modular PhysicsComponent! 
- Try deallocating sprites when they go outside the play area!
- Try using GKStateMachine to add pause functionality!
- Try making a particle effect for when your ship explodes! 
- Try adding sound effects using SKActions!
- Try implementing a scoring system! 
- Try having enemies shoot back at you!