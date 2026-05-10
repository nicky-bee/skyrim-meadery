Scriptname MEADFermentingScript extends ObjectReference  

; =========================
; BREWING STATES
; =========================

Int Property STATE_IDLE = 0 AutoReadOnly
Int Property STATE_FERMENTING = 1 AutoReadOnly
Int Property STATE_FINISHED = 2 AutoReadOnly

Int Property BrewState = 0 Auto

; =========================
; BATCH VARIABLES
; =========================

Float Property BrewStartTime = 0.0 Auto
Float Property BrewFinishTime = 0.0 Auto
Int Property BrewQuality = 0 Auto
String Property BrewName = "Mead" Auto

Bool Property IngredientAdded = False Auto
Bool Property InfusionLocked = False Auto

Bool InfusionMenuOpen = False

; =========================
; BASE INGREDIENTS
; =========================

Potion Property Honey Auto
Ingredient Property Yeast Auto

; =========================
; INGREDIENT REFERENCES
; =========================

Ingredient Property JuniperBerries Auto
Ingredient Property Snowberries Auto
Ingredient Property Lavender Auto
Ingredient Property FireSalts Auto
Ingredient Property JazbayGrapes Auto

; =========================
; OUTPUTS
; =========================

Potion Property HomemadeMead Auto
Potion Property CurrentOutputMead Auto

; =========================
; REGISTRIES
; =========================

FormList Property IngredientList Auto
FormList Property OutputList Auto

; =========================
; MENU
; =========================

Message Property InfusionMenu Auto

; =========================
; ENTRY POINT
; =========================

Event OnActivate(ObjectReference akActionRef)

	If akActionRef != Game.GetPlayer()
		Return
	EndIf

	If BrewState == STATE_IDLE
		StartBrew()
	ElseIf BrewState == STATE_FERMENTING
		UpdateFermenting()
	ElseIf BrewState == STATE_FINISHED
		CollectBrew()
	EndIf

EndEvent

; =========================================================
; 1. START BREW
; =========================================================

Function StartBrew()

	If Game.GetPlayer().GetItemCount(Honey) < 1
		Debug.Notification("You need more honey.")
		Return
	EndIf

	If Game.GetPlayer().GetItemCount(Yeast) < 1
		Debug.Notification("You need more yeast.")
		Return
	EndIf

	Game.GetPlayer().RemoveItem(Honey, 3)
	Game.GetPlayer().RemoveItem(Yeast, 1)

	BrewName = "Homemade Mead"
	BrewQuality = Utility.RandomInt(30, 70)

	CurrentOutputMead = HomemadeMead

	If BrewQuality > 100
		BrewQuality = 100
	EndIf

	IngredientAdded = False
	InfusionLocked = False

	BrewStartTime = Utility.GetCurrentGameTime()
	BrewFinishTime = BrewStartTime + 1.0

	BrewState = STATE_FERMENTING

	SetDisplayName("Fermenting " + BrewName)

	Debug.Notification("The " + BrewName + " begins fermenting.")

EndFunction

; =========================================================
; 2. FERMENTING STATE
; =========================================================

Function UpdateFermenting()

	Float CurrentTime = Utility.GetCurrentGameTime()
	Float ElapsedTime = CurrentTime - BrewStartTime
	Float FermentDuration = BrewFinishTime - BrewStartTime

	If CurrentTime >= BrewFinishTime

		BrewState = STATE_FINISHED
		SetDisplayName("Finished " + BrewName)

		Debug.Notification("The " + BrewName + " has finished fermenting.")
		Return

	EndIf

	If ElapsedTime >= (FermentDuration / 2)
		InfusionLocked = True
	EndIf

	If !IngredientAdded

		If InfusionLocked
			Debug.Notification("The fermentation is too far along to add ingredients.")
			Return
		EndIf

		If InfusionMenuOpen
			Return
		EndIf

		InfusionMenuOpen = True
		Int choice = InfusionMenu.Show()
		InfusionMenuOpen = False

		ApplyIngredient(choice)

	Else

		Debug.Notification("Additional ingredients have already been added.")

	EndIf

EndFunction

; =========================================================
; 3. INGREDIENT HANDLER
; =========================================================

Function ApplyIngredient(Int choice)

	If choice < 0
		Return
	EndIf

	Ingredient selectedIngredient = IngredientList.GetAt(choice) as Ingredient
	Potion selectedOutput = OutputList.GetAt(choice) as Potion

	If selectedIngredient == None
		Return
	EndIf

	If selectedOutput == None
		Return
	EndIf

	Bool success = False

	; =========================
	; QUALITY / NAME LOGIC
	; =========================

	If selectedIngredient == JuniperBerries
		success = TryApply(selectedIngredient, selectedOutput, 15, "Juniper Mead")
	ElseIf selectedIngredient == Snowberries
		success = TryApply(selectedIngredient, selectedOutput, 10, "Snowberry Mead")
	ElseIf selectedIngredient == Lavender
		success = TryApply(selectedIngredient, selectedOutput, 8, "Lavender Mead")
	ElseIf selectedIngredient == FireSalts
		success = TryApply(selectedIngredient, selectedOutput, 20, "Spiced Mead")
	ElseIf selectedIngredient == JazbayGrapes
		success = TryApply(selectedIngredient, selectedOutput, 12, "Jazbay Mead")
	EndIf

	If success

		If BrewQuality > 100
			BrewQuality = 100
		EndIf

		IngredientAdded = True

		SetDisplayName("Fermenting " + BrewName)

	EndIf

EndFunction

; =========================================================
; 4. APPLY INGREDIENT
; =========================================================

Bool Function TryApply(Ingredient ing, Potion outputPotion, Int qualityBonus, String newName)

	If Game.GetPlayer().GetItemCount(ing) <= 0
		Debug.Notification("You do not have that ingredient.")
		Return False
	EndIf

	Game.GetPlayer().RemoveItem(ing, 1)

	BrewQuality += qualityBonus
	BrewName = newName

	CurrentOutputMead = outputPotion

	Debug.Notification("You add ingredients to the brew.")

	Return True

EndFunction

; =========================================================
; 5. COLLECTION
; =========================================================

Function CollectBrew()

	Int outputAmount = 4

	If BrewQuality >= 75
		outputAmount = 7
		Debug.Notification("This " + BrewName + " is exceptional.")
	ElseIf BrewQuality >= 50
		outputAmount = 5
		Debug.Notification("The " + BrewName + " has a rich aroma.")
	Else
		outputAmount = 3
		Debug.Notification("The " + BrewName + " smells weak and sour.")
	EndIf

	Game.GetPlayer().AddItem(CurrentOutputMead, outputAmount)

	Debug.Notification("You collect the finished " + BrewName + ".")

	ResetBrew()

EndFunction

; =========================================================
; 6. RESET
; =========================================================

Function ResetBrew()

	BrewState = STATE_IDLE

	BrewStartTime = 0.0
	BrewFinishTime = 0.0

	BrewQuality = 0

	BrewName = "Mead"

	IngredientAdded = False
	InfusionLocked = False

	CurrentOutputMead = HomemadeMead

	SetDisplayName("Mead Barrel")

EndFunction