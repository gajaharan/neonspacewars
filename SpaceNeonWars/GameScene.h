//
//  GameScene.h
//  SpaceNeonWars
//

//  Copyright (c) 2016 Gajaharan Satkunanandan. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <GLKit/GLKVector2.h>

@interface GameScene : SKScene <SKPhysicsContactDelegate>

@property (nonatomic) int ammo;
@property (nonatomic) int score;
@property (nonatomic) int pointValue;
@property (nonatomic) BOOL multiMode;
@property (nonatomic) BOOL gamePause;

@end
