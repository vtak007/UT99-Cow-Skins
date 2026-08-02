//=============================================================================
// bbCustomPlayer.
//
// Base class for Bonus Pack 1 custom player models under InstaGibPlus.
// Ported from UTPure 7H BP1Handler (TNSe et al.) to modern IG+:
//  - The old v400-era Tick/PostBeginPlay mesh hacks are replaced with
//    PostNetBeginPlay (available on 469, which IG+ requires).
//  - Never overrides Tick: IG+ bbPlayer has a real simulated Tick.
//  - SetMultiSkin stores SkinName/FaceName in bbPlayerReplicationInfo,
//    matching IG+ behavior (used by ForceModels/brightskin code).
//=============================================================================
class bbCustomPlayer extends bbTournamentMale
	abstract;

var() mesh FallBackMesh;
var() string Author;
var() string AuthorInfo;
var() string DefaultFace, TeamSkin, DefaultCustomPackage;

static function SetMyMultiSkin(Actor SkinActor, string SkinName, string FaceName, byte TeamNum)
{
	local string MeshName, FacePackage, SkinItem, FaceItem, SkinPackage;

	MeshName = SkinActor.GetItemName(string(SkinActor.Mesh));

	SkinItem = SkinActor.GetItemName(SkinName);
	FaceItem = SkinActor.GetItemName(FaceName);
	FacePackage = Left(FaceName, Len(FaceName) - Len(FaceItem));
	SkinPackage = Left(SkinName, Len(SkinName) - Len(SkinItem));

	if(SkinPackage == "")
	{
		SkinPackage=default.DefaultCustomPackage;
		SkinName=SkinPackage$SkinName;
	}
	if(FacePackage == "")
	{
		FacePackage=default.DefaultCustomPackage;
		FaceName=FacePackage$FaceName;
	}

	// Set the fixed skin element.  If it fails, go to default skin & no face.
	if(!SetSkinElement(SkinActor, default.FixedSkin, SkinName$string(default.FixedSkin+1), default.DefaultSkinName$string(default.FaceSkin+1)))
	{
		SkinName = default.DefaultSkinName;
		FaceName = "";
	}

	// Set the face - if it fails, set the default skin for that face element.
	SetSkinElement(SkinActor, default.FaceSkin, FacePackage$SkinItem$String(default.FaceSkin+1)$FaceItem, SkinName$String(default.FaceSkin+1));

	// Set the team elements
	if( TeamNum != 255 )
	{
		SetSkinElement(SkinActor, default.TeamSkin1, SkinName$string(default.TeamSkin1+1)$"T_"$String(TeamNum), SkinName$string(default.FaceSkin+1));
		SetSkinElement(SkinActor, default.TeamSkin2, SkinName$string(default.TeamSkin2+1)$"T_"$String(TeamNum), SkinName$string(default.FaceSkin+1));
	}
	else
	{
		SetSkinElement(SkinActor, default.TeamSkin1, SkinName$string(default.TeamSkin1+1), "");
		SetSkinElement(SkinActor, default.TeamSkin2, SkinName$string(default.TeamSkin2+1), "");
	}

	// Set the talktexture
	if(Pawn(SkinActor) != None && Pawn(SkinActor).PlayerReplicationInfo != None)
	{
		if(FaceItem != "" && SkinName != "")
			Pawn(SkinActor).PlayerReplicationInfo.TalkTexture = Texture(DynamicLoadObject(SkinName$"5"$FaceItem, class'Texture'));
	}
}

static function SetMultiSkin(Actor SkinActor, string SkinName, string FaceName, byte TeamNum)
{
	local string MeshName, SkinPackage;
	local Texture NewSkin;
	local PlayerPawn P;
	local bbPlayerReplicationInfo bbPRI;

	// Keep IG+ PRI skin bookkeeping in sync (ForceModels/brightskins).
	P = PlayerPawn(SkinActor);
	if (P != None)
	{
		bbPRI = bbPlayerReplicationInfo(P.PlayerReplicationInfo);
		if (P.Role == ROLE_Authority && bbPRI != None)
		{
			bbPRI.SkinName = SkinName;
			bbPRI.FaceName = FaceName;
		}
	}

	if ( SkinActor.Mesh == Default.FallBackMesh )
	{
		Super.SetMultiSkin(SkinActor, "CommandoSkins.cmdo", "Blake", TeamNum);
		return;
	}

	if ( SkinName == "" )
		SkinName = default.DefaultSkinName;

	if ( default.bisMultiSkinned )
	{
		if ( FaceName == "" )
			FaceName = default.DefaultFace;

		SetMyMultiSkin(SkinActor, SkinName, FaceName, TeamNum);
		return;
	}

	// only one skin for mesh

	MeshName = SkinActor.GetItemName(string(SkinActor.Mesh));
	if( TeamNum != 255 )
		SkinName = default.DefaultCustomPackage$default.TeamSkin$String(TeamNum);

	if( !SetSkinElement(SkinActor, 0, SkinName, default.DefaultSkinName) )
		SkinName = default.DefaultSkinName;

	NewSkin = Texture(DynamicLoadObject(SkinName, class'Texture'));
	if ( NewSkin != None )
		SkinActor.Skin = NewSkin;
	else
	{
		if(default.DefaultSkinName != "")
		{
			NewSkin = Texture(DynamicLoadObject(default.DefaultSkinName, class'Texture'));
			SkinActor.Skin = NewSkin;
		}
	}

	// Set the talktexture
	if( Pawn(SkinActor) != None )
	{
		if ( (SkinName != Default.DefaultSkinName) && (TeamNum == 255) )
		{
			Pawn(SkinActor).PlayerReplicationInfo.TalkTexture = Texture(DynamicLoadObject(SkinName$"-Face", class'Texture'));
			if ( Pawn(SkinActor).PlayerReplicationInfo.TalkTexture == None )
				Pawn(SkinActor).PlayerReplicationInfo.TalkTexture = Texture(DynamicLoadObject(default.DefaultFace, class'Texture'));
		}
		else
			Pawn(SkinActor).PlayerReplicationInfo.TalkTexture = Texture(DynamicLoadObject(default.DefaultFace, class'Texture'));
	}
}

static function GetMultiSkin( Actor SkinActor, out string SkinName, out string FaceName )
{
	local string FullSkinName, ShortSkinName;

	if ( default.bisMultiSkinned
		|| (SkinActor.Mesh == Default.FallBackMesh) )
	{
		Super.GetMultiSkin(SkinActor,SkinName,FaceName);
		return;
	}

	// only one skin
	FaceName = "";

	FullSkinName  = String(SkinActor.Skin);
	ShortSkinName = SkinActor.GetItemName(FullSkinName);
	SkinName = Left(FullSkinName, Len(FullSkinName) - Len(ShortSkinName)) $ Left(ShortSkinName, 4);
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	SetMyMesh();
}

// Runs on net clients after initial replication; replaces the old
// v400-era Tick/Timer polling hack from UTPure's BP1Handler.
simulated event PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	if ( Role == ROLE_SimulatedProxy )
	{
		if ( (PlayerReplicationInfo == None) || !PlayerReplicationInfo.bIsSpectator )
			SetMyMesh();
		SetTimer(1.0, true);
	}
}

simulated function Timer()
{
	// Mesh retry only applies to remote proxies; everything else is
	// IG+ server/owner logic that must be preserved untouched.
	if ( Role == ROLE_SimulatedProxy )
	{
		if ( Mesh == None )
			SetMyMesh();
		return;
	}
	Super.Timer();
}

simulated function SetMyMesh()
{
	local Mesh NewMesh;

	DrawType = DT_Mesh;

	if ( class'MultiMeshMenu'.default.bForceDefaultMesh
		|| ((Mesh == None) && (Default.Mesh == None)) )
	{
		bIsMultiSkinned = true;
		Mesh = FallBackMesh;
		Super.SetMultiSkin(self, "CommandoSkins.cmdo", "Blake", PlayerReplicationInfo.Team);
		return;
	}
	if ( Default.Mesh != none )
		Mesh = Default.Mesh;

	if ( bIsMultiSkinned )
	{
		if ( MultiSkins[0] == None )
		{
			if ( bIsPlayer && (PlayerReplicationInfo != None) )
				SetMultiSkin(self, "","", PlayerReplicationInfo.team);
			else
				SetMultiSkin(self, "","", 0);
		}
	}
	else if ( Skin == None )
		Skin = Default.Skin;
}

// don't make assumptions deaths will also work as certain type of hit anim
function PlayGutHit(float tweentime)
{
	if ( AnimSequence == 'GutHit' )
	{
		if (FRand() < 0.5)
			TweenAnim('LeftHit', tweentime);
		else
			TweenAnim('RightHit', tweentime);
	}
	else
		TweenAnim('GutHit', tweentime);
}

function PlayHeadHit(float tweentime)
{
	if ( AnimSequence == 'HeadHit' )
		TweenAnim('GutHit', tweentime);
	else
		TweenAnim('HeadHit', tweentime);
}

function PlayLeftHit(float tweentime)
{
	if ( AnimSequence == 'LeftHit' )
		TweenAnim('GutHit', tweentime);
	else
		TweenAnim('LeftHit', tweentime);
}

function PlayRightHit(float tweentime)
{
	if ( AnimSequence == 'RightHit' )
		TweenAnim('GutHit', tweentime);
	else
		TweenAnim('RightHit', tweentime);
}

state PlayerWalking
{
ignores SeePlayer, HearNoise, Bump;

	function BeginState()
	{
		if ( Mesh == None )
			SetMyMesh();
		Super.BeginState();
	}
}

state PlayerWaiting
{
ignores SeePlayer, HearNoise, Bump, TakeDamage, Died, ZoneChange, FootZoneChange;

	function EndState()
	{
		Super.EndState();
		SetMyMesh();
	}
}

state PlayerSpectating
{
ignores SeePlayer, HearNoise, Bump, TakeDamage, Died, ZoneChange, FootZoneChange;

	function EndState()
	{
		Super.EndState();
		SetMyMesh();
	}
}

defaultproperties
{
    FallBackMesh=LodMesh'Botpack.Commando'
    FaceSkin=1
    TeamSkin1=2
    TeamSkin2=3
    DefaultSkinName="CommandoSkins.cmdo"
    DefaultPackage="CommandoSkins."
    LandGrunt=Sound'UnrealShare.MLand3'
    JumpSound=Sound'Botpack.TMJump3'
    SelectionMesh="Botpack.SelectionMale1"
    SpecialMesh="Botpack.TrophyMale1"
    MenuName="Custom Player"
    Mesh=LodMesh'Botpack.Commando'
}
