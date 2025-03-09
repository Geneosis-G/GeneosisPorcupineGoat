class PorcupineGoat extends GGMutator;

//global list of spikes to remove
var array<PorcupineSpike> mRemovableSpikes;
var int mMaxSpikesOnMap;

//list of spikes count per NPC
struct NpcSpikes
{
	var GGNpc npc;
	var int spikeCount;
};
var array<NpcSpikes> mNpcSpikes;
var float mSpikesToKillRatio;

function SpikeImplanted(PorcupineSpike spike)
{
	local PorcupineSpike spikeToRemove;

	mRemovableSpikes.AddItem(spike);

	while(mRemovableSpikes.Length > mMaxSpikesOnMap)
	{
		spikeToRemove=mRemovableSpikes[0];
		mRemovableSpikes.RemoveItem(spikeToRemove);
		spikeToRemove.SelfDestroy();
	}
}

function NPCImplanted(GGNPC npc)
{
	local NpcSpikes newNpcSpikes;
	local int index, count;

	index = mNpcSpikes.Find('npc', npc);
	if(index != INDEX_NONE)
	{
		mNpcSpikes[Index].spikeCount++;
		count=mNpcSpikes[Index].spikeCount;
	}
	else
	{
		newNpcSpikes.npc=npc;
		newNpcSpikes.spikeCount=1;
		mNpcSpikes.AddItem(newNpcSpikes);
		count=1;
	}
	//WorldInfo.Game.Broadcast(self, "GetMaxSpikesToKill(" $ npc $ ")=" $ GetMaxSpikesToKill(npc));
	if(count > GetMaxSpikesToKill(npc))
	{
		KillNpc(npc);
	}
}

function int GetMaxSpikesToKill(GGNpc npc)
{
	return (npc.GetCollisionHeight() + npc.GetCollisionRadius()) * mSpikesToKillRatio;
}

function KillNpc(GGNpc npc)
{
	local GGNpcMMOAbstract MMONpc;
	local GGNpcZombieGameModeAbstract zombieNpc;

	if(IsDead(npc))
		return;

	MMONpc = GGNpcMMOAbstract(npc);
	zombieNpc = GGNpcZombieGameModeAbstract(npc);
	//Kill NPCs
	if(npc != none)
	{
		npc.DisableStandUp( class'GGNpc'.const.SOURCE_EDITOR );
		npc.mTimesKnockedByGoat=0;
		npc.mTimesKnockedByGoatStayDownLimit=0;
		npc.SetRagdoll(true);
		if(MMONpc != none)
		{
			MMONpc.mHealth=1;
			MMONpc.TakeDamage(MMONpc.mHealth, none, MMONpc.Location, vect(0, 0, 0), class'GGDamageType',, none);
			if(MMONpc.mHealth > 0)
			{
				MMONpc.mHealth=0;
				MMONpc.TakeDamage(MMONpc.mHealth, none, MMONpc.Location, vect(0, 0, 0), class'GGDamageType');
			}
		}
		if(zombieNpc != none)
		{
			zombieNpc.TakeDamage(zombieNpc.mHealth, none, zombieNpc.Location, vect(0, 0, 0), class'GGDamageTypeZombieSurvivalMode');
		}
	}
}

function bool IsDead(GGNpc npc)
{
	return npc.mTimesKnockedByGoatStayDownLimit == 0 && !npc.CanStandUp();
}

DefaultProperties
{
	mMaxSpikesOnMap=4000
	mSpikesToKillRatio=0.1f

	mMutatorComponentClass=class'PorcupineGoatComponent'
}