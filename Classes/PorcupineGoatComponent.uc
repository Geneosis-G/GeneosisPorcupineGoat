class PorcupineGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;

var bool mIsButtonPressed;
var int mSpikeWave;//Min number of spikes to throw in a wave
var float mSpikeSize;
//List of pawns recently stabed by collision
var array<GGPawn> mLastStabs;
var array<GGPawn> mOldStabs;
var float mMinStabTime;
var float mTotalTime;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;
		//Stick spikes to the goat
		MakePorkupine();
	}
}

function MakePorkupine()
{
	local int i;
	local vector spikeLoc;
	local rotator spikeRot;
	local PorcupineSpike newSpike;

	for(i=0 ; i<100 ; i++)
	{
		spikeRot.Pitch = -Rand(32768);
		spikeRot.Yaw = Rand(65536);
		//spikeRot.Roll = Rand(32768);

		spikeLoc = gMe.Location + (vector(spikeRot) * -(gMe.GetCollisionRadius() + mSpikeSize/4.f));

		newSpike=ThrowSpike(none, spikeLoc, spikeRot);
		newSpike.HandleCollission(gMe, gMe.mesh, gMe.Location, normal(newSpike.Location - gMe.Location));//Force collision with goat
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if(localInput.IsKeyIsPressed( "RightMouseButton", string( newKey ) ) || newKey == 'XboxTypeS_LeftTrigger')
		{
			mIsButtonPressed=true;
		}

		if(localInput.IsKeyIsPressed("LeftMouseButton", string( newKey )) || newKey == 'XboxTypeS_RightTrigger')
		{
			if(!gMe.mIsRagdoll && mIsButtonPressed)
			{
				ThrowSpikes();
			}
		}
		//Debug only
		//if(localInput.IsKeyIsPressed("RightMouseButton", string( newKey )))
		//{
		//	MakePorkupine();
		//}
	}
	else if( keyState == KS_Up )
	{
		if(localInput.IsKeyIsPressed( "RightMouseButton", string( newKey ) ) || newKey == 'XboxTypeS_LeftTrigger')
		{
			mIsButtonPressed=false;
		}
	}
}

function ThrowSpikes()
{
	local int i, spikeWaveCount;
	local vector spikeLoc;
	local rotator spikeRot;

	//myMut.WorldInfo.Game.Broadcast(myMut, "ThrowSpikes");
	spikeWaveCount = Rand(mSpikeWave) + mSpikeWave;
	spikeRot = gMe.Rotation;

	for(i=0 ; i<spikeWaveCount ; i++)
	{
		spikeLoc = gMe.Location + (vector(spikeRot) * (gMe.GetCollisionRadius() + mSpikeSize));
		//myMut.WorldInfo.Game.Broadcast(myMut, "Spike " $ i);
		ThrowSpike(gMe, spikeLoc, spikeRot);

		spikeRot = class'PorcupineSpike'.static.srTurn(gMe.Rotation, rot(0, 1, 0) * (i+1) * 65536 / spikeWaveCount);
		spikeRot = class'PorcupineSpike'.static.srTurn(spikeRot, rot(1, 0, 0) * (Rand(4096) - 2048));
		//spikeRot.Yaw += 65536 / spikeWaveCount;
		//spikeRot.Pitch = gMe.Rotation.Pitch + Rand(4096) - 2048;
	}
}

function PorcupineSpike ThrowSpike(Actor spikeOwner, vector spikeLoc, rotator spikeRot)
{
	local PorcupineSpike newSpike;

	newSpike = gMe.Spawn(class'PorcupineSpike', spikeOwner,, spikeLoc, spikeRot,, true);
	newSpike.ShootSpike(PorcupineGoat(myMut));
	//myMut.WorldInfo.Game.Broadcast(myMut, "newSpike=" $ newSpike);
	return newSpike;
}

function OnCollision( Actor actor0, Actor actor1 )
{
	local GGPawn pawn;

	if(actor0 == gMe)
		pawn=GGPawn(actor1);
	else if(actor1 == gMe)
		pawn=GGPawn(actor0);

	if(pawn != none && !pawn.mIsRagdoll && mLastStabs.Find(pawn) == INDEX_NONE && mOldStabs.Find(pawn) == INDEX_NONE)
	{
		ThrowSpike(gMe, gMe.Location, rotator(pawn.Location - gMe.Location));
		mLastStabs.AddItem(pawn);
	}
}

function TickMutatorComponent( float deltaTime )
{
	mTotalTime += deltaTime;

	if(mTotalTime >= mMinStabTime)
	{
		mOldStabs=mLastStabs;
		mLastStabs.Length=0;
		mTotalTime=0.f;
	}
}

defaultproperties
{
	mSpikeSize=100.f
	mSpikeWave=8
	mMinStabTime=0.1f
}