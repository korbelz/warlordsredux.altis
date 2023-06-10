#include "..\warlords_constants.inc"

private _previousSeizingInfo = [];
private _visitedSector = objNull;

while {!BIS_WL_missionEnd} do {
	_sectorsToCheck = +(BIS_WL_sectorsArray # 3);
	_visitedSectorID = _sectorsToCheck findIf {player inArea (_x getVariable "objectAreaComplete")};
	
	if (_visitedSectorID != -1) then {
		_visitedSector = _sectorsToCheck # _visitedSectorID;
		private _info = (_visitedSector getVariable ["BIS_WL_seizingInfo", []]);
		if !(_previousSeizingInfo isEqualTo _info) then {
			if (count _info > 1) then {
				["seizing", [_visitedSector, _info # 0, _info # 1, _info # 2]] spawn BIS_fnc_WL2_setOSDEvent;
				waitUntil {sleep 0.1; (count (_visitedSector getVariable ["BIS_WL_seizingInfo", []])) == 0};
				_previousSeizingInfo = [];
			} else {
				["seizing", []] spawn BIS_fnc_WL2_setOSDEvent;
				_previousSeizingInfo = _info;
			};
		} else {
			if ((_visitedSector getVariable "BIS_WL_owner") != BIS_WL_playerSide && {count _info == 0 && {(_visitedSector in (BIS_WL_sectorsArray # 7)) && {_visitedSector != WL_TARGET_FRIENDLY}}}) then {
				["seizingDisabled", [_visitedSector getVariable "BIS_WL_owner"]] spawn BIS_fnc_WL2_setOSDEvent;
				_previousSeizingInfo = ["seizingDisabled"];
			};
		};
	} else {
		if (count _previousSeizingInfo > 0) then {
			["seizing", []] spawn BIS_fnc_WL2_setOSDEvent;
			["seizingDisabled", []] spawn BIS_fnc_WL2_setOSDEvent;
			_previousSeizingInfo = [];
		};
	};
	sleep (if (_visitedSectorID == -1) then {1} else {0.5});
};