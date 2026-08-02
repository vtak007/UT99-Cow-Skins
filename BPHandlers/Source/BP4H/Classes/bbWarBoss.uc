// ====================================================================
//  Class:  BP4H.bbWarBoss
//  Parent: BP4H.bbSkeletal
//
//  War Boss (Bonus Pack 4) player class for InstaGibPlus.
//  Ported from UTPure 7H BP4Handler by TNSe et al.
// ====================================================================

class bbWarBoss extends bbSkeletal;

static function SetMultiSkin(Actor SkinActor, string SkinName, string FaceName, byte TeamNum)
{
	local texture Face;
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

	if ( TeamNum == 0 )
	{
		SkinActor.Skin =  texture(DynamicLoadObject("SkeletalChars.WarRed",class'Texture'));
		Face =  texture(DynamicLoadObject("SkeletalChars.WarRedFace",class'Texture'));
	}
	else if ( TeamNum == 3 )
	{
		SkinActor.Skin =  texture(DynamicLoadObject("SkeletalChars.WarGold",class'Texture'));
		Face =  texture(DynamicLoadObject("SkeletalChars.WarGoldFace",class'Texture'));
	}
	else if ( TeamNum == 2 )
	{
		SkinActor.Skin =  texture(DynamicLoadObject("SkeletalChars.WarGreen",class'Texture'));
		Face =  texture(DynamicLoadObject("SkeletalChars.WarGreenFace",class'Texture'));
	}
	else
	{
		SkinActor.Skin =  texture(DynamicLoadObject("SkeletalChars.WarBlue",class'Texture'));
		Face =  texture(DynamicLoadObject("SkeletalChars.WarBlueFace",class'Texture'));
	}
	if( Pawn(SkinActor) != None )
		Pawn(SkinActor).PlayerReplicationInfo.TalkTexture =Face;
}

defaultproperties
{
    Deaths(0)=Sound'Botpack.BDeath1'
    Deaths(1)=Sound'Botpack.BDeath1'
    Deaths(2)=Sound'Botpack.BDeath3'
    Deaths(3)=Sound'Botpack.BDeath4'
    Deaths(4)=Sound'Botpack.BDeath3'
    Deaths(5)=Sound'Botpack.BDeath4'
    HitSound3=Sound'Botpack.BInjur3'
    HitSound4=Sound'Botpack.BInjur4'
    LandGrunt=Sound'Botpack.Bland01'
    StatusDoll=Texture'Botpack.Icons.BossDoll'
    StatusBelt=Texture'Botpack.Icons.BossBelt'
    VoicePackMetaClass="BotPack.VoiceBoss"
    CarcassType=Class'Botpack.TBossCarcass'
    JumpSound=Sound'Botpack.BJump1'
    SelectionMesh="SkeletalChars.WarMachineBoss"
    SpecialMesh="Botpack.TrophyMale1"
    HitSound1=Sound'Botpack.BInjur1'
    HitSound2=Sound'Botpack.BInjur2'
    Die=Sound'Botpack.BDeath1'
    MenuName="War Boss"
    VoiceType="BotPack.VoiceBoss"
    Mesh=SkeletalMesh'SkeletalChars.WarMachineBoss'
    FakeClass="SkeletalChars.WarBoss"
}
