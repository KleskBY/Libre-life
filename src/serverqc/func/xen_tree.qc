
#define XEN_TREE_MODEL		"models/tree.iqm"
#define XEN_TREE_FRAME_MAX	255
#define XEN_TREE_ATTACK_DELAY	0.35
#define XEN_TREE_ATTACK_TIME	0.9
#define XEN_TREE_DAMAGE		25

#define XEN_TREE_IDLE		0
#define XEN_TREE_ATTACK		1

#define XEN_TREE_HIT_SOUND1	"zombie/claw_strike1.wav"
#define XEN_TREE_HIT_SOUND2	"zombie/claw_strike2.wav"
#define XEN_TREE_HIT_SOUND3	"zombie/claw_strike3.wav"
#define XEN_TREE_MISS_SOUND1	"zombie/claw_miss1.wav"
#define XEN_TREE_MISS_SOUND2	"zombie/claw_miss2.wav"

.entity xenTreeTrigger;
.float xenTreeState;
.float xenTreeHitTime;
.float xenTreeDoneTime;
.float xenTreeDidHit;

void XenTree_PlayHitSound()
{
	float r = floor(random() * 3);

	if (r == 0)
		Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, XEN_TREE_HIT_SOUND1);
	else if (r == 1)
		Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, XEN_TREE_HIT_SOUND2);
	else
		Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, XEN_TREE_HIT_SOUND3);
}

void XenTree_PlayMissSound()
{
	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, 100, XEN_TREE_MISS_SOUND1, XEN_TREE_MISS_SOUND2);
}

float XenTree_BoxesOverlap(entity check, entity box)
{
	if (check.absmin_x > box.absmax_x || check.absmax_x < box.absmin_x)
		return FALSE;
	if (check.absmin_y > box.absmax_y || check.absmax_y < box.absmin_y)
		return FALSE;
	if (check.absmin_z > box.absmax_z || check.absmax_z < box.absmin_z)
		return FALSE;
	return TRUE;
}

void XenTree_DoAttackHit()
{
	entity scan = nextent(world);
	float hit = FALSE;

	if (!self.xenTreeTrigger)
		return;

	makevectors(self.angles);

	while (scan != world)
	{
		if (scan != self && scan.owner != self)
		if (scan.flags & (FL_MONSTER | FL_CLIENT))
		if (scan.takedamage)
		if (XenTree_BoxesOverlap(scan, self.xenTreeTrigger))
		{
			hit = TRUE;
			T_Damage(scan, self, self, XEN_TREE_DAMAGE, DMG_CRUSH | DMG_SLASH);
			scan.punchangle_x = 15;
			scan.velocity = scan.velocity + v_forward * 100;
		}

		scan = nextent(scan);
	}

	if (hit)
		XenTree_PlayHitSound();
}

void XenTree_Attack()
{
	if (self.xenTreeState != XEN_TREE_IDLE)
		return;

	self.xenTreeState = XEN_TREE_ATTACK;
	self.xenTreeHitTime = time + XEN_TREE_ATTACK_DELAY;
	self.xenTreeDoneTime = time + XEN_TREE_ATTACK_TIME;
	self.xenTreeDidHit = FALSE;
	self.framerate = random(1, 1.4);
	XenTree_PlayMissSound();
}

float XenTree_TakeDamage(entity inflictor, entity attacker, float damage, float dmgType)
{
	XenTree_Attack();
	return 0;
}

void XenTree_Touch()
{
	if (other.classname == "monster_bigmomma")
		return;

	XenTree_Attack();
}

void XenTree_Think()
{
	if (self.xenTreeState == XEN_TREE_ATTACK)
	{
		if (!self.xenTreeDidHit && time >= self.xenTreeHitTime)
		{
			self.xenTreeDidHit = TRUE;
			XenTree_DoAttackHit();
		}

		if (time >= self.xenTreeDoneTime)
		{
			self.xenTreeState = XEN_TREE_IDLE;
			self.framerate = random(0.6, 1.4);
		}
	}

	self.frame = self.frame + self.framerate * 2.4;
	while (self.frame > XEN_TREE_FRAME_MAX)
		self.frame = self.frame - XEN_TREE_FRAME_MAX;

	self.nextthink = time + 0.1;
}

void XenTreeTrigger_Touch()
{
	entity trigger = self;
	entity tree = self.owner;

	if (!tree)
		return;

	self = tree;
	XenTree_Touch();
	self = trigger;
}

entity XenTreeTrigger_Create(entity treeOwner, vector position)
{
	entity trigger = spawn();

	trigger.classname = "xen_ttrigger";
	trigger.solid = SOLID_TRIGGER;
	trigger.movetype = MOVETYPE_NONE;
	trigger.owner = treeOwner;
	trigger.touch = XenTreeTrigger_Touch;
	setorigin(trigger, position);
	setsize(trigger, '-24 -24 0', '24 24 128');

	return trigger;
}

void xen_ttrigger()
{
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
	self.touch = XenTreeTrigger_Touch;

	if (self.mins == '0 0 0' && self.maxs == '0 0 0')
		setsize(self, '-24 -24 0', '24 24 128');
}

void XenTree_Precache()
{
	precache_model(XEN_TREE_MODEL);
	precache_model(XEN_PLANT_GLOW_SPRITE);
	precache_sound(XEN_TREE_HIT_SOUND1);
	precache_sound(XEN_TREE_HIT_SOUND2);
	precache_sound(XEN_TREE_HIT_SOUND3);
	precache_sound(XEN_TREE_MISS_SOUND1);
	precache_sound(XEN_TREE_MISS_SOUND2);
}

void xen_tree()
{
	vector triggerPosition;

	XenTree_Precache();

	setmodel(self, XEN_TREE_MODEL);
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_BBOX;
	self.takedamage = DAMAGE_YES;
	self.takeDmgFn = XenTree_TakeDamage;
	self.touch = XenTree_Touch;
	setsize(self, '-30 -30 0', '30 30 188');

	self.xenTreeState = XEN_TREE_IDLE;
	self.frame = random(0, XEN_TREE_FRAME_MAX);
	self.framerate = random(0.7, 1.4);
	self.think = XenTree_Think;
	self.nextthink = time + 0.1;

	makevectors(self.angles);
	triggerPosition = self.origin + v_forward * 64;
	self.xenTreeTrigger = XenTreeTrigger_Create(self, triggerPosition);
}
