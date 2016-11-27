//
//  GameScene.m
//  SpaceNeonWars
//
//  Created by Gajaharan Satkunanandan on 14/11/2016.
//  Copyright (c) 2016 Gajaharan Satkunanandan. All rights reserved.
//

#import "GameScene.h"
#import "GameMenu.h"
#import "GameBall.h"
#import <AVFoundation/AVFoundation.h>

static const CGFloat SHOOT_SPEED = 1000.0f;
static const CGFloat HALO_LOW_ANGLE = 200 * M_PI / 180.0;
static const CGFloat HALO_HIGH_ANGLE = 340 * M_PI / 180.0;
static const CGFloat HALO_SPEED = 200.0f;

static const uint32_t HALO_CATEGORY = 0x1 << 0;
static const uint32_t BALL_CATEGORY = 0x1 << 1;
static const uint32_t EDGE_CATEGORY = 0x1 << 2;
static const uint32_t SHIELD_CATEGORY = 0x1 << 3;
static const uint32_t LIFEBAR_CATEGORY = 0x1 << 4;
static const uint32_t SHIELD_POWER_CATEGORY = 0x1 << 5;
static const uint32_t MULTI_SHOT_CATEGORY = 0x1 << 6;

static NSString * const TOP_SCORE = @"TopScore";
static NSString * const MULTIPER  = @"Multiplier";

static NSString * const SPACE_BACKGROUND_IMAGE = @"Space";
static NSString * const CANNON_IMAGE = @"Cannon";
static NSString * const GREEN_CANNON_IMAGE = @"GreenCannon";
static NSString * const AMMO_DISPLAY_IMAGE = @"Ammo5";
static NSString * const SHIELD_BLOCK_IMAGE = @"Block";
static NSString * const PAUSE_BUTTON_IMAGE = @"PauseButton";
static NSString * const PLAY_BUTTON_IMAGE = @"PlayButton";
static NSString * const RESUME_BUTTON_IMAGE = @"ResumeButton";
static NSString * const LIFE_BAR_IMAGE = @"BlueBar";
static NSString * const BALL_IMAGE = @"Ball";
static NSString * const HALO_IMAGE = @"Halo";
static NSString * const HALOBOMB_IMAGE = @"HaloBomb";
static NSString * const HALOX_IMAGE = @"HaloX";
static NSString * const MULTISHOT_IMAGE = @"MultiShotPowerUp";

static NSString * const BALL_NAME = @"@Ball";
static NSString * const HALO_NAME = @"@Halo";
static NSString * const SHIELD_NAME = @"Shield";
static NSString * const MULTI_SHOT_NAME = @"MultiShot";
static NSString * const SHIELD_POWER_NAME = @"ShieldPower";
static NSString * const LIFEBAR_NAME = @"LifeBar";

static NSString * const SPAWN_HALO_KEY = @"SpawnHalo";
static NSString * const BOMB_KEY = @"Bomb";

@implementation GameScene {
    SKNode *_mainLayer;
    GameMenu *_gameMenu;
    SKSpriteNode *_cannon;
    SKSpriteNode *_ammoDisplay;
    SKLabelNode *_scoreLabel;
    SKLabelNode *_pointLabel;
    BOOL _didShoot;
    SKAction *_bounceSound;
    SKAction *_deepExplosionSound;
    SKAction *_explosionSound;
    SKAction *_laserSound;
    SKAction *_zapSound;
    SKAction *_soundShieldUp;
    BOOL _gameOver;
    NSUserDefaults *_userDefaults;
    NSMutableArray *_shieldPool;
    SKSpriteNode *pause;
    SKSpriteNode *resume;
    AVAudioPlayer *audioPlayer;
    int killCount;
}

static inline CGVector radiansToVector(CGFloat radians) {
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    return vector;
}

static inline CGFloat randomInRange(CGFloat low, CGFloat high) {
    CGFloat value = arc4random_uniform(UINT32_MAX) / (CGFloat)UINT32_MAX;
    return value * (high - low) + low;
}

-(void)didMoveToView:(SKView *)view {
    
    [self setupScene];
    
}

-(void)setupScene {
    /* Setup your scene here */
    
    //Turn off gravity
    self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
    self.physicsWorld.contactDelegate = self;
    
    // add background
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:SPACE_BACKGROUND_IMAGE];
    background.position = CGPointMake(0.0f, 0.0f);
    background.size = self.size;
    background.anchorPoint = CGPointZero;
    background.zPosition = 1;
    background.blendMode = SKBlendModeReplace;
    [self addChild:background];
    
    //Add left and right edges
    SKNode *leftEdge = [[SKNode alloc]init];
    leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height + 100)];
    leftEdge.position = CGPointZero;
    leftEdge.physicsBody.categoryBitMask = EDGE_CATEGORY;
    leftEdge.zPosition = 2;
    [self addChild:leftEdge];
    
    SKNode *rightEdge = [[SKNode alloc]init];
    rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height + 100)];
    rightEdge.position = CGPointMake(self.size.width, 0.0);
    rightEdge.physicsBody.categoryBitMask = EDGE_CATEGORY;
    leftEdge.zPosition = 2;
    [self addChild:rightEdge];
    
    //Add main Layer
    _mainLayer = [[SKNode alloc]init];
    [self addChild:_mainLayer];
    
    //add cannon
    _cannon =[SKSpriteNode spriteNodeWithImageNamed:CANNON_IMAGE];
    _cannon.position = CGPointMake(self.size.width/2, 0.0);
    _cannon.zRotation = 0.6;
    _cannon.zPosition = 3;
    [self addChild:_cannon];
    
    //Create cannon rotation actions
    SKAction *rotateCannon = [SKAction sequence:@[[SKAction rotateByAngle:2.0 duration:1],
                                                  [SKAction rotateByAngle:-2.0 duration:1]]];
    [_cannon runAction:[SKAction repeatActionForever:rotateCannon]];
    
    //Create spawn halo actions
    SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:2 withRange:1],
                                               [SKAction performSelector:@selector(spawnHalo) onTarget: self]]];
    [self runAction:[SKAction repeatActionForever:spawnHalo] withKey:SPAWN_HALO_KEY];
    
    // Create shield power up
    SKAction *spawnShieldPower = [SKAction sequence:@[[SKAction waitForDuration:10 withRange:4],
                                                      [SKAction performSelector:@selector(spawnShieldPowerUp) onTarget:self]]];
    [self runAction: [SKAction repeatActionForever:spawnShieldPower]];
    
    //Setup ammo
    _ammoDisplay = [SKSpriteNode spriteNodeWithImageNamed:AMMO_DISPLAY_IMAGE];
    _ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0);
    _ammoDisplay.position = _cannon.position;
    _ammoDisplay.zPosition = 3;
    [self addChild:_ammoDisplay];
    
    
    SKAction *incrementAmmo = [SKAction sequence:@[[SKAction waitForDuration:1],
                                                   [SKAction runBlock:^{
        if(!self.multiMode) {
            self.ammo++;
        }
    }]]];
    [self runAction:[SKAction repeatActionForever:incrementAmmo]];
    
    // Shield pool
    _shieldPool =[[NSMutableArray alloc] init];
    
    int shieldNumber = self.size.width / 50;
    
    for (int i = 0; i < shieldNumber; i++) {
        SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:SHIELD_BLOCK_IMAGE];
        shield.position = CGPointMake(35 + (50 *i), 90);
        shield.name = SHIELD_NAME;
        shield.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
        shield.physicsBody.categoryBitMask = SHIELD_CATEGORY;
        shield.physicsBody.collisionBitMask = 0;
        shield.zPosition = 3;
        if (![_shieldPool containsObject:shield]) {
            [_shieldPool addObject:shield];
        }
    }
    
    // Set up pause and resume buttons
    pause = [SKSpriteNode spriteNodeWithImageNamed:PAUSE_BUTTON_IMAGE];
    //pause.xScale = 2.0;
    //pause.yScale = 2.0;
    pause.position = CGPointMake(self.size.width - 30, 20);
    pause.zPosition = 3;
    [self addChild:pause];
    
    resume = [SKSpriteNode spriteNodeWithImageNamed:RESUME_BUTTON_IMAGE];
    resume.position = CGPointMake(self.size.width/2, self.size.height/2);
    resume.zPosition = 3;
    [self addChild:resume];
    
    //Setup score display
    _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
    _scoreLabel.position = CGPointMake(15, 10);
    _scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _scoreLabel.fontSize = 15;
    _scoreLabel.zPosition = 2;
    [self addChild: _scoreLabel];
    
    // Point multiplier label
    _pointLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
    _pointLabel.position = CGPointMake(15 ,30);
    _pointLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _pointLabel.fontSize = 15;
    _pointLabel.zPosition = 2;
    [self addChild:_pointLabel];
    
    //Setup sounds
    _bounceSound = [SKAction playSoundFileNamed:@"Bounce.caf" waitForCompletion:NO];
    _deepExplosionSound = [SKAction playSoundFileNamed:@"DeepExplosion.caf" waitForCompletion:NO];
    _explosionSound = [SKAction playSoundFileNamed:@"Explosion.caf" waitForCompletion:NO];
    _laserSound = [SKAction playSoundFileNamed:@"Laser.caf" waitForCompletion:NO];
    _zapSound = [SKAction playSoundFileNamed:@"Zap.caf" waitForCompletion:NO];
    _soundShieldUp = [SKAction playSoundFileNamed:@"ShieldUp.caf" waitForCompletion:NO];
    
    //Setup Menu
    _gameMenu = [[GameMenu alloc] init];
    _gameMenu.position = CGPointMake(self.size.width/2, self.size.height/2);
    _gameMenu.zPosition = 6;
    
    [self addChild:_gameMenu];
    
    
    /* Loading music */
    NSURL *url = [[NSBundle  mainBundle] URLForResource:@"BlindShift" withExtension:@"mp3"];
    NSError *error = nil;
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (!audioPlayer) {
        NSLog(@"Error loading music: %@", error);
    } else {
        audioPlayer.numberOfLoops = -1;
        audioPlayer.volume = 0.8;
        [audioPlayer play];
        _gameMenu.musicPlaying = YES;
    }
    
    // Set inital values
    self.ammo = 5;
    self.score = 0;
    self.pointValue = 1;
    _gameOver = YES;
    _scoreLabel.hidden = YES;
    _pointLabel.hidden = YES;
    pause.hidden = YES;
    resume.hidden = YES;
    
    //Load Top Score
    _userDefaults = [NSUserDefaults standardUserDefaults];
    _gameMenu.topScore = [_userDefaults integerForKey:TOP_SCORE];
}

-(void)newGame {

    [_mainLayer removeAllChildren];
    
    /* "Unpack" the shieldpool */
    while (_shieldPool.count > 0) {
        //if(!((SKSpriteNode *)[shieldPool objectAtIndex:0]).parent) {
        [_mainLayer addChild:[_shieldPool objectAtIndex:0]];
        //}
        [_shieldPool removeObjectAtIndex:0];
    }
    
    //Setup lifebar
    SKSpriteNode *lifeBar = [SKSpriteNode spriteNodeWithImageNamed:LIFE_BAR_IMAGE];
    lifeBar.name = LIFEBAR_NAME;
    lifeBar.position = CGPointMake(self.size.width*0.5, 70);
    lifeBar.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(-lifeBar.size.width*0.5,0) toPoint:CGPointMake(lifeBar.size.width*0.5, 0)];
    lifeBar.physicsBody.categoryBitMask = LIFEBAR_CATEGORY;
    lifeBar.zPosition = 3;
    [_mainLayer addChild:lifeBar];
    
    //Set inital values
    killCount = 0;
    [self actionForKey:SPAWN_HALO_KEY].speed = 1.0;
    self.multiMode = NO;
    self.ammo = 5;
    self.score = 0;
    self.pointValue = 1;
    _scoreLabel.hidden = NO;
    _pointLabel.hidden = NO;
    pause.hidden = NO;
    _gameOver = NO;
    [_gameMenu hide];
}

-(void) setAmmo:(int)ammo {
    if(ammo >= 0 && ammo <= 5) {
        _ammo = ammo;
        _ammoDisplay.texture = [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"Ammo%d", ammo]];
    }
}

/* Set point value */
-(void)setPointValue:(int)pointValue {
    _pointValue = pointValue;
    _pointLabel.text = [NSString stringWithFormat:@"Points: x%d", pointValue];
}

/* Set multi mode */
-(void)setMultiMode:(BOOL)multiMode {
    _multiMode = multiMode;
    if (multiMode) {
        _cannon.texture = [SKTexture textureWithImageNamed:GREEN_CANNON_IMAGE];
    } else {
        _cannon.texture = [SKTexture textureWithImageNamed:CANNON_IMAGE];
    }
}

-(void) setScore:(int)score {
    _score = score;
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %d", score];
}



-(void) shoot {

    GameBall *ball = [GameBall spriteNodeWithImageNamed:BALL_IMAGE];
    ball.name=BALL_NAME;
    
    CGVector rotationVector = radiansToVector(_cannon.zRotation);
    ball.position = CGPointMake(_cannon.position.x + (_cannon.size.width * 0.5 * rotationVector.dx),
                                _cannon.position.y + (_cannon.size.width * 0.5 * rotationVector.dy));
    [_mainLayer addChild:ball];
    
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:6.0];
    ball.physicsBody.velocity = CGVectorMake(rotationVector.dx * SHOOT_SPEED, rotationVector.dy * SHOOT_SPEED);
    ball.zPosition = 4;
    // bouncness of the object in terms of momentmum
    ball.physicsBody.restitution = 1.0;
    // angle friction
    ball.physicsBody.friction = 0.0;
    // air friction
    ball.physicsBody.linearDamping = 0.0;
    ball.physicsBody.categoryBitMask = BALL_CATEGORY;
    ball.physicsBody.collisionBitMask = EDGE_CATEGORY;
    ball.physicsBody.contactTestBitMask = EDGE_CATEGORY | SHIELD_POWER_CATEGORY | MULTI_SHOT_CATEGORY;
    [self runAction:_laserSound];
    
    //Create trail
    NSString *ballTrailPath = [[NSBundle mainBundle] pathForResource:@"BallTrail" ofType:@"sks"];
    SKEmitterNode *ballTrail = [NSKeyedUnarchiver unarchiveObjectWithFile:ballTrailPath];
    ballTrail.zPosition = 4;
    ballTrail.targetNode = _mainLayer;
    [_mainLayer addChild:ballTrail];
    ball.trail = ballTrail;
    [ball updateTrail];
    
}


-(void) spawnHalo {
    
    //increase Spawn speed
    SKAction *spawnHaloAction = [self actionForKey:SPAWN_HALO_KEY];
    if(spawnHaloAction.speed < 1.5) {
        spawnHaloAction.speed += 0.01;
    }
    
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:HALO_IMAGE];
    halo.position = CGPointMake(randomInRange(halo.size.width * 0.5, self.size.width - (halo.size.width * 0.5)),
                                self.size.height + (halo.size.height * 0.5));
    
    
    halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius: halo.size.width/2];
    CGVector direction = radiansToVector(randomInRange(HALO_LOW_ANGLE, HALO_HIGH_ANGLE));
    
    //GLKVector2 velocity = GLKVector2Make(direction.dx * HALO_SPEED, direction.dy * HALO_SPEED);
    //GLKVector2 direction2 = GLKVector2Normalize(velocity);
    //GLKVector2 newVelocity = GLKVector2MultiplyScalar(direction2, HALO_SPEED);
    //halo.physicsBody.velocity = CGVectorMake(newVelocity.x, newVelocity.y);
    
    halo.physicsBody.velocity = CGVectorMake(direction.dx * HALO_SPEED, direction.dy * HALO_SPEED);
    halo.name = HALO_NAME;
    halo.physicsBody.restitution = 1.0;
    halo.physicsBody.linearDamping = 0.0;
    halo.physicsBody.friction = 0.0;
    halo.physicsBody.angularDamping = 0.0;
    halo.physicsBody.categoryBitMask = HALO_CATEGORY;
    halo.physicsBody.collisionBitMask =  EDGE_CATEGORY;
    halo.physicsBody.contactTestBitMask = BALL_CATEGORY | SHIELD_CATEGORY | LIFEBAR_CATEGORY | EDGE_CATEGORY;
    halo.zPosition = 4;
    
    /* Count the number of haloes on the frame */
    int halosCounter = 0;
    for(SKNode *node in _mainLayer.children) {
        if([node.name isEqualToString:HALO_NAME]) {
            halosCounter++;
        }
    }
    
    if (halosCounter == 1) {
        halo.texture = [SKTexture textureWithImageNamed:HALOBOMB_IMAGE];
        halo.userData = [[NSMutableDictionary alloc] init];
        [halo.userData setObject:@YES forKey:BOMB_KEY];
        
    } else if(!_gameOver && arc4random_uniform(6) == 0) {
        //Random point multipler
        halo.texture = [SKTexture textureWithImageNamed:HALOX_IMAGE];
        halo.userData = [[NSMutableDictionary alloc] init];
        [halo.userData setObject:@YES forKey:MULTIPER];
    }
    
    [_mainLayer addChild:halo];
}

/* Add shield power up */
-(void)spawnShieldPowerUp {
    if (_shieldPool.count > 0) {
        SKSpriteNode *shieldPower = [SKSpriteNode spriteNodeWithImageNamed:SHIELD_BLOCK_IMAGE];
        shieldPower.position = CGPointMake(self.size.width + shieldPower.size.width, randomInRange(150, self.size.height - 100));
        shieldPower.name = SHIELD_POWER_NAME;
        shieldPower.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
        shieldPower.physicsBody.categoryBitMask = SHIELD_POWER_CATEGORY;
        shieldPower.physicsBody.collisionBitMask = 0;
        shieldPower.physicsBody.velocity = CGVectorMake(-100, randomInRange(-40, 40));
        shieldPower.physicsBody.angularVelocity = M_PI;
        shieldPower.physicsBody.linearDamping = 0.0;
        shieldPower.physicsBody.angularDamping = 0.0;
        shieldPower.zPosition = 3;
        [_mainLayer addChild:shieldPower];
    }
}

/* Add multi shot power up */
-(void)spawnedMultiShotPowerUp {
    SKSpriteNode *multiShot = [SKSpriteNode spriteNodeWithImageNamed:MULTISHOT_IMAGE];
    multiShot.name = MULTI_SHOT_NAME;
    multiShot.position = CGPointMake(-multiShot.size.width, randomInRange(150, self.size.height - 100));
    multiShot.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:12.0];
    multiShot.physicsBody.categoryBitMask = MULTI_SHOT_CATEGORY;
    multiShot.physicsBody.collisionBitMask = 0.0;
    multiShot.physicsBody.velocity = CGVectorMake(100, randomInRange(-40, 40));
    multiShot.physicsBody.angularVelocity = M_PI;
    multiShot.physicsBody.linearDamping = 0.0;
    multiShot.physicsBody.angularDamping = 0.0;
    multiShot.zPosition = 3;
    [_mainLayer addChild:multiShot];
}

-(void)didBeginContact:(SKPhysicsContact *)contact {
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    
    if(contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
        
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if(firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == BALL_CATEGORY) {
        //collision between halo and ball;
        self.score += self.pointValue;
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [self runAction:_explosionSound];
        
        /* Increment the pointValue var when this is a HaloX */
        if ([[firstBody.node.userData valueForKey:MULTIPER] boolValue]) {
            self.pointValue++;
        } else if ([[firstBody.node.userData valueForKey:BOMB_KEY] boolValue]) {
            /* Make the halos explode and remove them */
            //first.node.name = nil;
            [_mainLayer enumerateChildNodesWithName:HALO_NAME usingBlock:^(SKNode *node, BOOL *stop) {
                firstBody.node.name = nil;
                [self addExplosion:node.position withName:@"HaloExplosion"];
                [node removeFromParent];
            }];
        }
        
        /* Increment the killCount, when it hits 3
         we will create the multi show power up */
        killCount++;
        if (killCount % 5 == 0) {
            [self spawnedMultiShotPowerUp];
        }
        
        firstBody.categoryBitMask = 0;
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
        
    }
    
    if(firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == SHIELD_CATEGORY) {
        //collision between halo and shield;
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [self runAction:_explosionSound];
        
        /* The shield got hit by the bomb halo, destroyed all of them */
        if ([[firstBody.node.userData valueForKey:BOMB_KEY] boolValue]) {
            [_mainLayer enumerateChildNodesWithName:SHIELD_NAME usingBlock:^(SKNode *node, BOOL *stop) {
                //[self addExplosion:first.node.position withName:@"ShieldExplosion"];
                //i//f (![shieldPool containsObject:second.node]) {
                
                //}
                [node removeFromParent];
                //[shieldPool addObject:second.node];
            }];
        }
        firstBody.categoryBitMask = 0;
        [firstBody.node removeFromParent];
        if (![_shieldPool containsObject:secondBody.node]) {
            [_shieldPool addObject:secondBody.node];
        }
        [secondBody.node removeFromParent];
        
    }
    
    if(firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == LIFEBAR_CATEGORY) {
        //collision between halo and life bar;
        //[self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [self addExplosion:secondBody.node.position withName:@"LifeBarExplosion"];
        [self runAction:_deepExplosionSound];
        firstBody.categoryBitMask = 0;
        //[firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
        [self gameOver];
        
    }
    
    if(firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == EDGE_CATEGORY) {
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        
        /* Check to make sure that is of class Ball
         if bounces more than 4, remove it from frame */
        if ([firstBody.node isKindOfClass:[GameBall class]]) {
            ((GameBall *)firstBody.node).numBounces++;
            if (((GameBall *)firstBody.node).numBounces > 4) {
                [firstBody.node removeFromParent];
                self.pointValue = 1;
            }
        }
        
        //CGVector direction = radiansToVector(randomInRange(HALO_LOW_ANGLE, HALO_HIGH_ANGLE));
        //firstBody.velocity = CGVectorMake(-direction.dx * HALO_SPEED, direction.dy * HALO_SPEED);
        if(!_gameOver) [self runAction:_bounceSound];
        
    }
    
    if(firstBody.categoryBitMask == BALL_CATEGORY && secondBody.categoryBitMask == EDGE_CATEGORY) {
        
        [self addExplosion:firstBody.node.position withName:@"EdgeBounce"];
        [self runAction:_bounceSound];
        
    }
    
    /* Colision between the ball and the shield power up */
    if (firstBody.categoryBitMask == BALL_CATEGORY && secondBody.categoryBitMask == SHIELD_POWER_CATEGORY) {
        if(_shieldPool.count > 0) {
            int randomIndex = arc4random_uniform((int)_shieldPool.count);
            [_mainLayer addChild:[_shieldPool objectAtIndex:randomIndex]];
            [_shieldPool removeObjectAtIndex:randomIndex];
            [self runAction:_soundShieldUp];
        }
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    
    /* Colision between the ball and the multi shot power up */
    if (firstBody.categoryBitMask == BALL_CATEGORY && secondBody.categoryBitMask == MULTI_SHOT_CATEGORY) {
        self.multiMode = YES;
        [self runAction:_soundShieldUp];
        self.ammo = 5;
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
}

-(void)gameOver {
    [_mainLayer enumerateChildNodesWithName:HALO_NAME usingBlock:^(SKNode * _Nonnull node, BOOL * _Nonnull stop) {
        [self addExplosion:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
    }];
    
    [_mainLayer enumerateChildNodesWithName:BALL_NAME usingBlock:^(SKNode * _Nonnull node, BOOL * _Nonnull stop) {
        [node removeFromParent];
    }];
    
    [_mainLayer enumerateChildNodesWithName:SHIELD_NAME usingBlock:^(SKNode * _Nonnull node, BOOL * _Nonnull stop) {
        if (![_shieldPool containsObject:node]) {
            [_shieldPool addObject:node];
        }
        [node removeFromParent];
    }];
    
    /* Remove shield power up */
    [_mainLayer enumerateChildNodesWithName:SHIELD_POWER_NAME usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    /* Remove multi-shot power up */
    [_mainLayer enumerateChildNodesWithName:MULTI_SHOT_NAME usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    _gameMenu.score = self.score;
    if(self.score > _gameMenu.topScore) {
        _gameMenu.topScore = self.score;
        [_userDefaults setInteger:self.score forKey:TOP_SCORE];
        [_userDefaults synchronize];
    }
    
    //[self performSelector:@selector(newGame) withObject:nil afterDelay:1.5];
    [self runAction:[SKAction waitForDuration:1.0] completion:^{
        [_gameMenu show];
    }];
    _gameOver = YES;
    _scoreLabel.hidden = YES;
    _pointLabel.hidden = YES;
    pause.hidden = YES;
}

-(void) addExplosion: (CGPoint) position withName:(NSString*)name {
    NSString *explosionPath = [[NSBundle mainBundle] pathForResource:name ofType:@"sks"];
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath];
    
    //SKEmitterNode *explosion = [SKEmitterNode node];
    //explosion.particleTexture = [SKTexture textureWithImageNamed:@"spark"];
    //explosion.particleLifetime = 1;
    //explosion.particleBirthRate =2000;
    //explosion.particleScale = 0.2;
    //explosion.particleScaleSpeed = -0.2;
    //explosion.particleSpeed = 200;
    //explosion.numParticlesToEmit = 100;
    //explosion.emissionAngleRange = 360l;
    
    explosion.position = position;
    explosion.zPosition = 4;
    
    [_mainLayer addChild: explosion];
    
    SKAction *removeExplosion = [SKAction sequence:@[[SKAction waitForDuration:1.5],
                                                     [SKAction removeFromParent]]];
    [explosion runAction:removeExplosion];
}

/* Set game paused */
-(void)setGamePause:(BOOL)gamePause {
    if(!_gameOver) {
        _gamePause = gamePause;
        pause.hidden = gamePause;
        resume.hidden = !gamePause;
        self.paused = gamePause;
        
    }
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        if (!_gameOver && !self.gamePause) {
            if (![pause containsPoint:[touch locationInNode:pause.parent]]) {
                _didShoot = YES;
            }
        }
    }
}

-(void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for(UITouch *touch in touches) {
        if(_gameOver && _gameMenu.touchable) {
            SKNode *n = [_gameMenu nodeAtPoint:[touch locationInNode:_gameMenu]];
            if([n.name isEqualToString:@"Play"]) {
                [self newGame];
            }
            if ([n.name isEqualToString:@"Music"]) {
                _gameMenu.musicPlaying = !_gameMenu.musicPlaying;
                if(_gameMenu.musicPlaying) {
                    [audioPlayer play];
                } else {
                    [audioPlayer stop];
                }
            }
        } else if (!_gameOver) {
            if(self.gamePause) {
                if ([resume containsPoint:[touch locationInNode:resume.parent]]) {
                    self.gamePause = NO;
                }
            } else {
                if ([pause containsPoint:[touch locationInNode:pause.parent]]) {
                    self.gamePause = YES;
                }
            }
        }
    }
}

-(void)didSimulatePhysics {
    
    if(_didShoot) {
        if (self.ammo > 0) {
            self.ammo--;
            [self shoot];
            if (self.multiMode) {
                for (int i = 1; i < 5; i++) {
                    [self performSelector:@selector(shoot) withObject:nil afterDelay:0.1*i];
                }
                
                if (self.ammo == 0) {
                    self.multiMode = NO;
                    self.ammo = 5;
                }
            }
        }
        _didShoot = NO;
    }
    
    [_mainLayer enumerateChildNodesWithName:BALL_NAME usingBlock:^(SKNode *node, BOOL *stop) {
        if ([node respondsToSelector:@selector(updateTrail)]) {
            [node performSelector:@selector(updateTrail) withObject:nil afterDelay:0.0];
        }
        
        /* Remove if needed (out of frame) */
        if (!CGRectContainsPoint(self.frame, node.position)) {
            [node removeFromParent];
            self.pointValue = 1;
        }
    }];
    
    [_mainLayer enumerateChildNodesWithName:HALO_NAME usingBlock:^(SKNode *node, BOOL *stop) {
        if(node.position.y + node.frame.size.height < 0) {
            [node removeFromParent];
        }
    }];
    
    /* Remove shield power up */
    [_mainLayer enumerateChildNodesWithName:SHIELD_POWER_NAME usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.x + node.frame.size.width < 0) {
            [node removeFromParent];
        }
    }];
    
    /* Remove multi-shot power up */
    [_mainLayer enumerateChildNodesWithName:MULTI_SHOT_NAME usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.x - node.frame.size.width > self.size.width) {
            [node removeFromParent];
        }
    }];
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
