#import "Enemy.h"
#import "Player.h"
#import "EnemyBullet.h"

@implementation Enemy

static NSString * ImgBot = @"bot.png";
//static NSString * ImgJet = @"jet.png";
static NSString * SndExplode = @"asplode.caf";
static NSString * SndHit = @"hit.caf";
//static NSString * SndJet = @"jet.caf";

static int bulletIndex;


//We use this number to figure out how fast the ship is flying
CGFloat _thrust;

//A special effect - little poofs shoot out the back of the ship
//protected var _jets:FlxEmitter;

//These are "timers" - numbers that count down until we want something interesting to happen.
CGFloat _timer;		//Helps us decide when to fly and when to stop flying.
CGFloat _shotClock;	//Helps us decide when to shoot.


+ (id) Enemy
{
	return [[[self alloc] init] autorelease];
}

- (id) initWithOrigin:(CGPoint)Origin Bullets:(FlxGroup *)bullets Gibs:(FlxEmitter *)gibs ThePlayer:(Player *)player {
	if ((self = [super initWithX:Origin.x y:Origin.y graphic:nil])) {
        [self loadGraphicWithParam1:ImgBot param2:YES param3:NO param4:16 param5:16];
        
        _player = player;
        _bullets = bullets;
        _gibs = gibs;
        
        bulletIndex=0;
        
        angle = [self angleTowardPlayer];
        health = 2;	//Enemies take 2 shots to kill
        _timer = 0;
        _shotClock = 0;
        
        //We want the enemy's "hit box" or actual size to be
        //smaller than the enemy graphic itself, just by a few pixels.
        self.width = 12;
        self.height = 12;
        self.offset = CGPointMake(2, 2);
        //        
        //        //Here we are setting up the jet particles
        //        // that shoot out the back of the ship.
        //        _jets = new FlxEmitter();
        //        _jets.setRotation();
        //        _jets.makeParticles(ImgJet,15,0,false,0);
        
        //These parameters help control the ship's
        //speed and direction during the update() loop.
        maxAngular = 120;
        angularDrag = 400;
        //drag.x = 35;
        _thrust = 0;
        //_playerMidpoint = new FlxPoint();
        
	}
	
	return self;	
    
}


- (void) resetSwarm:(int)type xPos:(int)xpos yPos:(int)ypos Bullets:(FlxGroup *)bullets Gibs:(FlxEmitter *)gibs ThePlayer:(Player *)player
{
    //_player = player;
    //_bullets = bullets;
    //_gibs = gibs;
    self.dead = NO;
    self.x = xpos - self.width/2;
    self.y = ypos - self.height/2;
    angle = 90 + [self angleTowardPlayer];
    health = 2;	//Enemies take 2 shots to kill
    _timer = 0;
    _shotClock = 0;
    [self flicker:-1];
    
}




- (id) initWithOrigin:(CGPoint)Origin
{
	if ((self = [super initWithX:Origin.x y:Origin.y graphic:nil])) {
        [self loadGraphicWithParam1:ImgBot param2:YES param3:NO param4:16 param5:16];
        
	}
	
	return self;	
}


- (void) dealloc
{
	
	[super dealloc];
}

- (CGFloat) angleTowardPlayer
{
    return [FlxU getAngleWithParam1:self.x-_player.x param2:self.y-_player.y];
    
    
}


- (void) hurt:(float)Damage
{
    health -= Damage;
    [self flicker:0.2];
    FlxG.score += 10;
    
    if (health <= 0 && self.dead == NO) {
        [FlxG play:SndExplode];
        [self flicker:0];
        //_jets.kill();
        _gibs.x = self.x;
        _gibs.y = self.y;
        [_gibs startWithParam1:YES param2:3 param3:0];
        FlxG.score += 200;
        
        dead = YES;
        visible = NO;
        x = -100;
        y = -100;
    }
    else {
        [FlxG play:SndHit];
        
    }
}




- (void) update
{       
    if (!self.dead) {
        //Then, rotate toward that angle.
        //We could rotate instantly toward the player by simply calling:
        //angle = angleTowardPlayer();
        //However, we want some less predictable, more wobbly behavior.
        CGFloat da = 90 + [self angleTowardPlayer];    //90 +
        if(da < angle)
            angularAcceleration = -angularDrag;
        else if(da > angle)
            angularAcceleration = angularDrag;
        else
            angularAcceleration = 0;
        
        //Figure out if we want the jets on or not.
        _timer += FlxG.elapsed;
        if(_timer > 8)
            _timer = 0;
        jetsOn = _timer < 6;
        
        
        //Set the bot's movement speed and direction
        //based on angle and whether the jets are on.
        _thrust = [FlxU computeVelocityWithParam1:_thrust param2:(jetsOn?90:0) param3:self.drag.x param4:60];
        self.velocity = [FlxU rotatePointWithParam1:0 param2:_thrust param3:0 param4:0 param5:angle];
        
    }
    
    //Shooting - three shots every few seconds
    if(abs(self.x -_player.x )  < 150 &&  abs(self.y -_player.y) < 150 && !_player.dead)
    {
        BOOL shoot = NO;
        CGFloat os = _shotClock;
        _shotClock += FlxG.elapsed;
        if((os < 4.0) && (_shotClock >= 4.0))
        {
            _shotClock = 0;
            shoot = true;
        }
        else if((os < 3.5) && (_shotClock >= 3.5))
            shoot = true;
        else if((os < 3.0) && (_shotClock >= 3.0))
            shoot = true;
        
        //If we rolled over one of those time thresholds,
        //shoot a bullet out along the angle we're currently facing.
        if(shoot)
        {
            //First, recycle a bullet from the bullet pile.
            //If there are none, recycle will automatically create one for us.
            EnemyBullet * eb1 = [_bullets.members objectAtIndex:bulletIndex];
            
            bulletIndex++;
            if (bulletIndex>=_bullets.members.length) {
                bulletIndex = 0;	
            }
            
            
            //Then, shoot it from our midpoint out along our angle.
            angle = 90 + [self angleTowardPlayer];
            
            CGPoint here = CGPointMake(self.x+self.width/2, self.y+self.height/2);
            [eb1 shootAtLocation:here Aim:angle];
            
        }
    }
    
    
 	[super update];
	
}





@end