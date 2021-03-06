// This is the license from the Flash version.
// 
// Copyright (c) 2009 Adam 'Atomic' Saltsman
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// NOTE FROM THE AUTHOR: As far as I know, you only have to include
// this license if you are redistributing source code that includes
// the Flixel library.  There is no need (or way, afaik) to include
// it in your compiled flash games and apps!
// 
// NOTE FROM THE iOS PORT CODER: I have only ported this game to iOS.
// I do not claim to own any copyright over this game. All ownership
// stays with the original author.

#import "Spawner.h"
#import "Enemy.h"
#import "Player.h"
#import "Notch.h"

@implementation Spawner

static NSString * ImgSpawner = @"spawner.png";
static NSString * SndExplode = @"asplode.caf";
static NSString * SndExplode2 = @"menu_hit_2.caf";
static NSString * SndHit = @"hit.caf";



+ (id) spawnerWithOrigin:(CGPoint)Origin Gibs:(FlxEmitter *)gibs Bots:(FlxGroup *)bots BotBullets:(FlxGroup*)botBullets BotGibs:(FlxEmitter *)botGibs ThePlayer:(Player *)player Notches:(FlxGroup *)notches Index:(int)index;{
	return [[[self alloc] initWithOrigin:(CGPoint)Origin  Gibs:(FlxEmitter *)gibs Bots:(FlxGroup *)bots BotBullets:(FlxGroup*)botBullets BotGibs:(FlxEmitter *)botGibs ThePlayer:(Player *)player Notches:(FlxGroup *)notches Index:(int)index] autorelease];
}

- (id) initWithOrigin:(CGPoint)Origin Gibs:(FlxEmitter *)gibs Bots:(FlxGroup *)bots BotBullets:(FlxGroup*)botBullets BotGibs:(FlxEmitter *)botGibs ThePlayer:(Player *)player Notches:(FlxGroup *)notches Index:(int)index
{
    if ((self = [super initWithX:Origin.x y:Origin.y graphic:nil])) {
        [self loadGraphicWithParam1:ImgSpawner param2:YES param3:NO param4:24 param5:24];
        _gibs = gibs;
        _bots = bots;
        _botBullets = botBullets;
        _botGibs = botGibs;
        _player = player;
        _notches = notches;
        _timer = [FlxU random]*20;
        _open = NO;
        health = 8;
        _index = index;
        
        [self addAnimationWithParam1:@"open" param2:[NSMutableArray intArrayWithSize:5 ints:1,2,3,4,5] param3:40 param4:NO];
        [self addAnimationWithParam1:@"close" param2:[NSMutableArray intArrayWithSize:5 ints:5,4,3,2,1] param3:40 param4:NO];
        [self addAnimationWithParam1:@"dead" param2:[NSMutableArray intArrayWithSize:1 ints:6] param3:0 param4:NO];        
        
	}
	
	return self;	
    
}

- (id) initWithOrigin:(CGPoint)Origin
{
	if ((self = [super initWithX:Origin.x y:Origin.y graphic:nil])) {
        [self loadGraphicWithParam1:ImgSpawner param2:YES param3:NO param4:24 param5:24];
        
	}
	
	return self;	
}


- (void) dealloc
{
	
	[super dealloc];
}



- (void) update
{   
    if (!self.dead) {
        _timer += FlxG.elapsed;
        CGFloat limit = 20;
        //if( FlxG.abs(self.x - _player.x ) < 100  ) //onScreen
        if ( abs(self.x -_player.x )  < 150 &&  abs(self.y -_player.y) < 150   )    {
            limit = 4;
        }
        if(_timer > limit)
        {
            _timer = 0;
            [self makeBot];
            
            
        }
        else if(_timer > limit - 0.35)
        {
            if(!_open)
            {
                _open = YES;
                [self play:@"open"];
            }
        }
        else if(_timer > 1)
        {
            if(_open)
            {
                [self play:@"close"];
                _open = NO;
            }
        }
        //NSLog(@"%f", _timer);
    }
    
    
	[super update];
	
}

- (void) hurt:(float)Damage
{
    health -= Damage;
    [self flicker:0.2];
    FlxG.score += 50;
    
    //kill
    if (health <= 0 && self.dead == NO) {
        
        Notch * ntc = [_notches.members objectAtIndex:_index];
        [ntc play:@"off"];
        
        
        
        [self flicker:0];
        //_jets.kill();
        _gibs.x = self.x;
        _gibs.y = self.y;
        [_gibs startWithParam1:YES param2:3 param3:0];
        FlxG.score += 1000;
        [self flicker:-1];
        dead = YES;
        [self play:@"dead"];
        [self makeBot];
        [[FlxG quake] startWithIntensity:0.005 duration:1];
        [[FlxG flash] startWithParam1:0xffffffff param2:0.5];
        [FlxG play:SndExplode];
        [FlxG play:SndExplode2];
        
        
    }
    else {
        [FlxG play:SndHit];
    }
}





- (void) makeBot
{
    FlxObject * n = [_bots getFirstDead];
    if (n.dead) {
        [n resetSwarm:0 xPos: self.x + self.width/2 yPos:self.y + self.height/2 Bullets:_botBullets Gibs:_botGibs ThePlayer:_player];
        n.dead = NO;
        n.x = self.x;
        n.y = self.y;
        
        
    }
}

- (void) kill
{
    if(self.dead)
        return;
    [FlxG play:SndExplode];
    [FlxG play:SndExplode2];
    [super kill];
    active = false;
    exists = true;
    solid = false;
    [self flicker:0];
    [self play:@"dead"];
    [[FlxG quake] startWithIntensity:0.007 duration:0.25];
    [[FlxG flash] startWithParam1:0xffd8eba2 param2:0.65];   
    
    [self makeBot];
    FlxG.score += 1000;
}



@end
