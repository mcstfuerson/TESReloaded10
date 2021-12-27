#pragma once

static const char** MessageBoxServeSentenceText = (const char**)kMessageBoxServeSentenceText;
static const char** MessageBoxButtonYes = (const char**)kMessageBoxButtonYes;
static const char** MessageBoxButtonNo = (const char**)kMessageBoxButtonNo;
static bool Served = false;

static void (__cdecl * ShowSleepWaitMenu)(bool) = (void (__cdecl *)(bool))Hooks::ShowSleepWaitMenu;
static void __cdecl ShowSleepWaitMenuHook(bool IsSleeping) {
	
	bool Rest = false;
	UInt8 SitSleepState = Player->GetSitSleepState();
	UInt8 Mode = TheSettingManager->SettingsMain.SleepingMode.Mode;

	if (SitSleepState == 0 && Mode == 0)
		Rest = true;
	else if (SitSleepState == 4 && (Mode == 0 || Mode == 2 || Mode == 3))
		Rest = true;
	else if (SitSleepState == 9 && (Mode == 0 || Mode == 1 || Mode == 3))
		Rest = true;
	if (Rest)
		ShowSleepWaitMenu(SitSleepState == SleepingState);
	else
		InterfaceManager->ShowMessage("You cannot rest now.");

}