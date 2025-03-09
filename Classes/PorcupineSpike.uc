class PorcupineSpike extends GGKActor;

var PorcupineGoat myMut;

/** If true, then we have ragdolled a limb */
var bool mRagdolledLimb;

/** The velocity we give the mine when launched */
var float mLaunchSpeed;

var SoundCue mHitPawnSoundCue;
var SoundCue mHitNonPawnSoundCue;

var rotator mRotOffset;

simulated event PreBeginPlay()
{
	super.PreBeginPlay();

	Instigator = Pawn( Owner );

	SetCollision( false, false );
	CollisionComponent.SetActorCollision( false, false );
	StaticMeshComponent.SetBlockRigidBody( false );
}

function ShootSpike(optional PorcupineGoat mut = none)
{
	local float speed;

	myMut=mut;

	// Update collission
	SetCollision( true, true );
	CollisionComponent.SetActorCollision( true, false );
	StaticMeshComponent.SetBlockRigidBody( true );

	SetPhysics( PHYS_RigidBody );
	//No speed when attaching spikes to the goat
	speed = Instigator==none?mLaunchSpeed/100.f:mLaunchSpeed;

	// Fire the spike straight forward
	StaticMeshComponent.SetRBLinearVelocity(Owner.Velocity + (vector(rTurn(StaticMeshComponent.GetRotation(), rot(0, -16384, 0))) * speed));
}

function bool HandleCollission( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	local GGPawn pawn;
	local TraceHitInfo hitInfo;
	local vector dir;
	local float minMaxDist;

	pawn = GGPawn( Other );

	//WorldInfo.Game.Broadcast(self, "HandleCollission with " $ Other $ "/" $ OtherComp);
	// Direction the mine is flying
	if(Instigator != none)
		dir = normal( StaticMeshComponent.GetRBLinearVelocity() );
	else//Force right dir to attach to goat during init
		dir = normal(Other.Location - Location);
	if( pawn != None )
	{
		// Several collission might come the first frame
		if( mRagdolledLimb )
		{
			return true;
		}

		if(Instigator != none)//No sound during init
			PlaySound( mHitPawnSoundCue );
		//Make sure goat is detected during init
		minMaxDist = Instigator!=none?100:1000;
		// Find where we hit the mesh if we continue the same path
		if( TraceComponent( HitLocation, HitNormal, pawn.Mesh, Location - dir * minMaxDist, Location + dir * minMaxDist,, hitInfo ) && hitInfo.BoneName != '' )
		{
			mRagdolledLimb = true;
			SetPhysics( PHYS_None );

			SetCollision( false, false );
			StaticMeshComponent.SetNotifyRigidBodyCollision( false );
			StaticMeshComponent.SetActorCollision( false, false );
			StaticMeshComponent.SetBlockRigidBody( false );

			StaticMeshComponent.SetLightEnvironment(pawn.mLightEnvironment);

			if(HitLocation != vect(0, 0, 0))
				SetLocation(HitLocation - dir * 50);
;
			SetRotation(rot(0, 0, 0));
			SetBase( pawn,, pawn.mesh, hitInfo.BoneName );

			StaticMeshComponent.SetRotation(rTurn(rotator(dir), rot(0, 16384, 0)));

			if(Instigator != none)//do not ragdoll during init phase
				pawn.SetRagdoll(true);

			if(GGNpc(pawn) != none)
				myMut.NPCImplanted(GGNpc(pawn));
		}

		return true;
	}
	else if(!ShouldIgnoreActor(Other))
	{
		if( mRagdolledLimb )
		{
			return true;
		}

		mRagdolledLimb = true;

		if(Instigator == none)//do not stick to other stuff during init phase
		{
			SelfDestroy();
			return true;
		}

		PlaySound( mHitNonPawnSoundCue );

		SetPhysics( PHYS_None );

		SetCollision( false, false );
		StaticMeshComponent.SetNotifyRigidBodyCollision( false );
		StaticMeshComponent.SetActorCollision( false, false );
		StaticMeshComponent.SetBlockRigidBody( false );

		SetRotation(rot(0, 0, 0));
		if(GGKactor(Other) != none)
			mRotOffset = Rotation - GGKactor(Other).StaticMeshComponent.GetRotation();
		SetBase(Other);

		StaticMeshComponent.SetRotation(rTurn(rotator(dir), rot(0, 16384, 0)));
		//Make spike removable for later
		myMut.SpikeImplanted(self);

		return true;
	}

	return false;
}

function SelfDestroy()
{
	ShutDown();
	Destroy();
}

function bool ShouldIgnoreActor(Actor act)
{
	return (
	PorcupineSpike(act) != none
	|| Volume(act) != none
	|| GGApexDestructibleActor(act) != none
	|| act == self
	|| act == Owner);
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if( Other == Instigator )
	{
		return;
	}

	if( !HandleCollission( Other, OtherComp, HitLocation, HitNormal ) )
	{
		super.Touch( Other, OtherComp, HitLocation, HitNormal );
	}
}

event Bump( Actor Other, PrimitiveComponent OtherComp, Vector HitNormal )
{
	if( Other == Instigator )
	{
		return;
	}

	if( !HandleCollission( Other, OtherComp, Location, HitNormal ) )
	{
		super.Bump( Other, OtherComp, HitNormal );
	}
}

event RigidBodyCollision( PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent,
	const out CollisionImpactData RigidCollisionData, int ContactIndex )
{
	if( OtherComponent != none && OtherComponent.Owner == Instigator )
	{
		return;
	}

	// Don't call super if we attach to other, that will ragdoll the other pawn
	if( !HandleCollission( OtherComponent != none ? OtherComponent.Owner : None, OtherComponent, RigidCollisionData.ContactInfos[ContactIndex].ContactPosition, RigidCollisionData.ContactInfos[ContactIndex].ContactNormal ) )
	{
		super.RigidBodyCollision( HitComponent, OtherComponent, RigidCollisionData, ContactIndex );
	}
}

event Tick(float deltaTime)
{
	super.Tick(DeltaTime);
	// Fix glitchy rotation on kactors
	if(GGKactor(Base) != none)
	{
		SetRotation(rTurn(GGKactor(Base).StaticMeshComponent.GetRotation(), mRotOffset));
	}
}

function rotator rTurn(rotator rHeading,rotator rTurnAngle)
{
	return class'PorcupineSpike'.static.srTurn(rHeading, rTurnAngle);
}

static function rotator srTurn(rotator rHeading,rotator rTurnAngle)
{
    // Generate a turn in object coordinates
    //     this should handle any gymbal lock issues

    local vector vForward,vRight,vUpward;
    local vector vForward2,vRight2,vUpward2;
    local rotator T;
    local vector  V;

    GetAxes(rHeading,vForward,vRight,vUpward);
    //  rotate in plane that contains vForward&vRight
    T.Yaw=rTurnAngle.Yaw; V=vector(T);
    vForward2=V.X*vForward + V.Y*vRight;
    vRight2=V.X*vRight - V.Y*vForward;
    vUpward2=vUpward;

    // rotate in plane that contains vForward&vUpward
    T.Yaw=rTurnAngle.Pitch; V=vector(T);
    vForward=V.X*vForward2 + V.Y*vUpward2;
    vRight=vRight2;
    vUpward=V.X*vUpward2 - V.Y*vForward2;

    // rotate in plane that contains vUpward&vRight
    T.Yaw=rTurnAngle.Roll; V=vector(T);
    vForward2=vForward;
    vRight2=V.X*vRight + V.Y*vUpward;
    vUpward2=V.X*vUpward - V.Y*vRight;

    T=OrthoRotation(vForward2,vRight2,vUpward2);

   return(T);
}

DefaultProperties
{
	Physics=PHYS_Interpolating

	mLaunchSpeed=1750
	CustomGravityScaling=0.3

	Begin Object name=StaticMeshComponent0
		StaticMesh=StaticMesh'Space_Vendors.Meshes.Carrot'
		//Materials[0]=MaterialInstanceConstant'Space_3DPrinter.Materials.3DPrint_INST_08'
		Materials[0]=Material'Space_AreaSigns.Materials.SpaceAreaSign_Auto_MasterMat'
		//Materials[0]=MaterialInstanceConstant'Space_Characters.Materials.Service_Fem_01'
		Scale3D=(X=0.25f,Y=2.5f,Z=0.25f)
		Rotation=(Yaw=16384)
		bNotifyRigidBodyCollision=true
		ScriptRigidBodyCollisionThreshold=10.0f //if too big, we won't get any notifications from collisions between kactors
		BlockRigidBody=true
	End Object

	bCollideActors=true
	bBlockActors=true

	bCallRigidBodyWakeEvents=true

	mHitPawnSoundCue=SoundCue'Heist_Audio.Cue.SFX_Syringe_Impact_Terrain_Mono_01_Cue'
	mHitNonPawnSoundCue=SoundCue'Heist_Audio.Cue.SFX_Syringe_Impact_Terrain_Mono_01_Cue'

	bStatic=false
	bNoDelete=false
}