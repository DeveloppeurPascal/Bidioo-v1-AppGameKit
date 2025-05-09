rem Bidioo
rem
rem (c) Patrick Premartin / Olf Software / Gamolf 2013-2014

rem version 1.0 - octobre 2013: refusée sur App Store Apple suite à problème d'ajustement de taille d'écran, de taille de texte et de bogue sur l'orientation de l'écran
rem version 1.1 - janvier 2014
rem     - forçage de la taille de l'écran à 1024x768 (pour soumission "iPad" sur AppStore)
rem		- adaptation des sources à AGK 2 et correction des écrans pour soumission sur les différentes plateformes de téléchargement

remstart
do
    print(getAppName()) // "title" de setup.agc
    print(getDeviceLanguage()) // fr
    print(GetDeviceBaseName()) // "windows", "ios", "android", "mac", or "blackberry"
    print(getRawGeoLatitude())
    print(getRawGeoLongitude())
    print(getRawGeoPostalCode())
    print(getRawGeoCity())
    print(getRawGeoState())
    print(getRawGeoCountry())
    sync()
loop
remend

SetResolutionMode(1)

rem definition des constantes et variables de l'application
//  true et false servent pour les boolean (en tant qu'entier car inexistants dans AGK)
#constant true 1
#constant false 0

rem définition des variable spermettant les calculs liés à la taille de l'écran de jeu
//  ecran_largeur : largeur de l'aire de jeu, taille de l'écran ou de l'image de fond
global ecran_largeur as integer = 0
//  ecran_hauteur : hauteur de l'aire de jeu, taille de l'écran ou de l'image de fond
global ecran_hauteur as integer = 0

rem choix de la taille d'affichage et paramétrage de la rotation de l'écran
//      on prend la taille totale du device comme écran de jeu
//      on adapte la taille de l'image de fond à la taille de l'écran
//      on conserve les 100 pixels de gauche dans l'écran de jeu pour les boutons
//      on utilise le reste pour la grille avec 8x7 cases par défaut (modifiable dans les réglages)
global imgFond as integer = 0
imgFondTemp = loadImage("fond-papier-or.jpg")
iw# = getImageWidth(imgFondTemp)
ih# = getImageHeight(imgFondTemp)
if (getDeviceWidth() > getDeviceHeight())
    dw# = getDeviceWidth()
    dh# = getDeviceHeight()
else
    dw# = getDeviceHeight()
    dh# = getDeviceWidth()
endif
if (dw# <= iw#) && (dh# <= ih#)
    // la taille de l'écran est inférieure à la taille de l'image de fond
    imgFond = copyImage(imgFondTemp,0,0,dw#,dh#)
    deleteImage(imgFondTemp)
else
    // la taille de l'écran dépasse la taille de l'image de fond
    imgFond = imgFondTemp
endif
// on travaille avec la taille de l'écran complet, qu'il soit plus grand ou plus petit que l'image de fond, le reste devra s'adapter
ecran_largeur = dw#
ecran_hauteur = dh#
ecran_largeur = 1024
ecran_hauteur = 768
/*
do
    print(ecran_largeur)
    print(ecran_hauteur)
    sync()
    if (getPointerState() = 1) then exit
loop
*/
// on définit la taille de l'écran de jeu et on passe en paysage pour la suite
SetVirtualResolution(ecran_largeur,ecran_hauteur)
SetOrientationAllowed(0,0,1,1)
sync()
// affichage du titre du jeu en attendant le chargement du reste de l'application
global sprTitreJeu as integer = 0
sprTitreJeu = createSprite(loadimage("bidioo-titre.png"))
setSpriteSize(sprTitreJeu,(ecran_largeur*2)/3,-1)
setSpritePosition(sprTitreJeu,(ecran_largeur-getSpriteWidth(sprTitreJeu))/2,(ecran_hauteur-getSpriteHeight(sprTitreJeu))/2)
setSpriteVisible(sprTitreJeu, false)
setSpriteActive(sprTitreJeu, false)
setSpriteDepth(sprTitreJeu,9500)
// définition des couleurs de texte (noir) et de fond par défaut (blanc)
setPrintColor(0,0,0)
setClearColor(255,255,255)
clearScreen()
setSpriteVisible(sprTitreJeu, true)
sync()

// connexion à Game Center si on est sur un appareil compatible
global gamecenter_onoff as integer = false
if (getGameCenterExists())
    gameCenterSetup()
    gameCenterLogin()
    gamecenter_onoff = true
endif

// chargement de la fonte utilisée pour les affichages de chiffres sur le tableau de jeu
global imgFontDorsa as integer = 0
imgFontDorsa = loadImage("dorsa.png")
//settextdefaultfontimage(imgFontDorsa)

rem déclaration des variables utilisées en cours de jeu
//  sens_x : permet de savoir dans quel sens horizontal le mouvement se fait
global sens_x as integer = 0
//  sens_y : permet de savoir dans quel sens vertical le mouvement se fait
global sens_y as integer = 0
//  score : donne le score actuel du joueur
global score as integer = 0
//  score_mult : multiplicateur du nombre de points à ajouter au score
global score_mult as integer = 1
//  nb_points : variable utilisée pour calculer le nombre de points ajoutés au score à chaque explosion de cases
global nb_points as integer = 0
//  nb_cases : utilisé en même temps que nb_points, nb_cases compte les cases supprimées et permet ensuite d'offrir d'éventuels bonus au joueur
global nb_cases as integer = 0
//  niveau_de_jeu : permet de déterminer le niveau de la partie en cours (impliquant le nombre de motifs/couleurs possibles)
global niveau_de_jeu as integer = 1
//  mode_de_jeu : indique quel mode de jeu est sélectionné (1 : classique = swap entre deux cases contigues, 2 : mixte = les deux, 3 : master = deplacement de lignes)
global mode_de_jeu as integer = 2
//  nb_vies : donne le nombre maximum de coups restants sans explosion de billes
global nb_vies as integer = 0
//  nb_bombes : bonus permettant d'exploser une bille et celles qui l'entourent
global nb_bombes as integer = 0
//  nb_melanges : bonus déclenchant un mélange des motifs dans la grille
global nb_melanges as integer = 0
//  nb_swap : bonus permettant d'inverser deux couleurs dans la grille
global nb_swap as integer = 0
//  nb_suppr : bonus permettant de supprimer toutes les billes de la même couleur que la bille choisie
global nb_suppr as integer = 0
//  nb_bouees : bonus affichant une suggestion de mouvement à faire, à défaut de mouvement possible, supprime la couleur la plus représentée de la grille
global nb_bouees as integer = 0

// chargement des images liées aux différents logos/boutons de l'application
global imgPause as integer = 0
imgPause = loadImage("pause.png")
global imgAide as integer = 0
imgAide = loadImage("question.png")
global aide_onoff as integer = true
global imgVies as integer = 0
imgVies = loadImage("coeur.png")
global imgBombes as integer = 0
imgBombes = loadImage("boutonrouge2.png")
global imgMelanges as integer = 0
imgMelanges = loadImage("ventilo.png")
global imgSwap as integer = 0
imgSwap = loadImage("pinceaurouleau.png")
global imgSuppr as integer = 0
imgSuppr = loadImage("poubelle.png")
global imgScoreMult as integer = 0
imgScoreMult = loadImage("calculatrice.png")
global imgBouee as integer = 0
imgBouee = loadImage("bouee.png")
global imgScore as integer = 0
imgScore = loadImage("podium.png")
global imgCredits as integer = 0
imgCredits = loadImage("info.png")
global imgOptions as integer = 0
imgOptions = loadImage("engrenage.png")
global imgStart as integer = 0
imgStart = loadImage("drapeaustart.png")
global imgEteindre as integer = 0
if (left(getDeviceName(),7) = "windows") or (left(getDeviceName(),3) = "mac")
    imgEteindre = loadImage("eteindre.png")
endif
global imgGCScore as integer = 0
global imgReussites as integer = 0
global imgUp as integer = 0
global imgAGK as integer = 0
global imgGAMOLF as integer = 0
global imgSon as integer = 0
global imgMusic as integer = 0
global dim imgModeDejeu[3] as integer
for i = 0 to 2
    imgModeDejeu[i] = 0
next i

// variables utilisées pour l'animation du bonus "bouee"
global animation_bouee_onoff as integer = false
global animation_bouee_sens as integer = -1
global x1 as integer = 0
global y1 as integer = 0
global x2 as integer = 0
global y2 as integer = 0
global x3 as integer = 0
global y3 as integer = 0

rem chargement de la musique de fond et des bruitages
global sonMusique as integer = 0
sonMusique = loadMusic("ExcessiveReasoning-2min.mp3")

rem définition des sprites utilisés sur l'écran de jeu et des textes associés
global dim sprJeu[10] as integer
global dim txtJeu[10] as integer
for i = 0 to 9
    select i
        case 0:
            global jeuScoreID as integer = 0
            jeuScoreID = i
            sprJeu[i] = createSprite(imgScore)
            txtJeu[i] = createText(str(score))
        endcase
        case 1:
            global jeuScoreMultID as integer = 0
            jeuScoreMultID = i
            sprJeu[i] = createSprite(imgScoreMult)
            txtJeu[i] = createText(str(score_mult)+":"+str(niveau_de_jeu))
        endcase
        case 2:
            global jeuViesID as integer = 0
            jeuViesID = i
            sprJeu[i] = createSprite(imgVies)
            txtJeu[i] = createText(str(nb_vies))
        endcase
        case 3:
            global jeuBombesID as integer = 0
            jeuBombesID = i
            sprJeu[i] = createSprite(imgBombes)
            txtJeu[i] = createText(str(nb_bombes))
        endcase
        case 4:
            global jeuMelangesID as integer = 0
            jeuMelangesID = i
            sprJeu[i] = createSprite(imgMelanges)
            txtJeu[i] = createText(str(nb_melanges))
        endcase
        case 5:
            global jeuSwapID as integer = 0
            jeuSwapID = i
            sprJeu[i] = createSprite(imgSwap)
            txtJeu[i] = createText(str(nb_swap))
        endcase
        case 6:
            global jeuSupprID as integer = 0
            jeuSupprID = i
            sprJeu[i] = createSprite(imgSuppr)
            txtJeu[i] = createText(str(nb_suppr))
        endcase
        case 7:
            global jeuBoueesID as integer = 0
            jeuBoueesID = i
            sprJeu[i] = createSprite(imgBouee)
            txtJeu[i] = createText(str(nb_bouees))
        endcase
        case 8:
            global jeuAideID as integer = 0
            jeuAideID = i
            sprJeu[i] = createSprite(imgAide)
            txtJeu[i] = 0
        endcase
        case 9:
            global jeuPauseID as integer = 0
            jeuPauseID = i
            sprJeu[i] = createSprite(imgPause)
            txtJeu[i] = 0
        endcase
    endselect
    setSpriteVisible(sprJeu[i],false)
    setSpriteActive(sprJeu[i],false)
    if (txtJeu[i] <> 0)
        setTextVisible(txtJeu[i],false)
        setTextColor(txtJeu[i],0,0,0,200)
    endif
next i

rem initialisation des paramètres utilisés pour le tableau des scores
type tscore
    pseudo$ as string
    niveau as integer
    score as integer
    transmis$ as string
endtype
global nbMeilleursScoresMax as integer = 20
global dim meilleursScores[nbMeilleursScoresMax] as tscore
for i = 0 to nbMeilleursScoresMax-1
    meilleursScores[i].pseudo$  = ""
    meilleursScores[i].niveau = 0
    meilleursScores[i].score = 0
    meilleursScores[i].transmis$ = "N"
next i
global pseudo$ as string = ""

// tableau de textes utilisés pour les affichages de score et autres
dim textes[50] as integer

rem declaration des variables liées aux thèmes / motifs / couleurs
// nb_couleurs_max : nombre de motifs utilisés dans la grille (billes de couleur par exemple)
global nb_couleurs_max = 0
// nb_couleurs_min : nombre minimum de couleurs/motifs (ne pas trop descendre car c'est trop facile voire injouable)
global nb_couleurs_min = 5
// couleurs : stocke la liste des ID des images des billes du jeu (maximum de 50 couleurs)
global dim couleurs[50] as integer
for i = 0 to 49
    couleurs[i] = 0
next i
//  nb_couleurs : nombre de couleurs différentes dans la partie en cours
global nb_couleurs as integer = 0

rem la cellule est la zone de la grille qui permet de jouer
type cellule
    x as integer
    y as integer
    couleur as integer
    sprite as integer
endtype

rem définition des variables liées au thème choisi
//  grille_largeur : nombre de cases en largeur dans la grille
global grille_largeur as integer = 1
//  grille_hauteur : nombre de cases en hauteur dans la grille
global grille_hauteur as integer = 1
// grille_marge_gauche : espace libre à laisser à gauche les premiers motifs
global grille_marge_gauche as integer = 0
// grille_marge_haut : espace libre à laisser au dessus les premiers motifs
global grille_marge_haut as integer = 0
// grille servant à stocker les infos du jeu (maximum de 30 x 30 cases)
global dim grille[30*30] as cellule
global dim grillebis[30*30] as integer
for x = 0 to grille_largeur-1
    for y = 0 to grille_hauteur-1
        i = grille_indice(x,y)
        grille[i].x = x
        grille[i].y = y
        grille[i].couleur = -1
        grille[i].sprite = 0
    next y
next x
global sprFondGrille as integer = 0

// déclaration des variables utilisées pour la sonorisation du jeu
global music_onoff as integer = true
global son_onoff as integer = true

// paramétrage en dur des thèmes actuellement disponibles
global theme_choisi$ as string = ""
global theme_en_cours$ as string = ""
global theme_nb as integer = 4
global dim theme_images[theme_nb] as integer
for i = 0 to theme_nb-1
    theme_images[i] = 0
next i
global dim theme_liste$[theme_nb] as string
theme_liste$[0] = "kolopach"
theme_liste$[1] = "davidGervais-0"
theme_liste$[2] = "davidGervais-1"
theme_liste$[3] = "bille"

// liste des réussites liées aux badges
global dim reussite_n1[3] as integer
global dim reussite_n3[3] as integer
global dim reussite_n5[3] as integer
global dim reussite_n8[3] as integer
global dim reussite_n15[3] as integer
for i = 0 to 2
    reussite_n1[i] = false
    reussite_n3[i] = false
    reussite_n5[i] = false
    reussite_n8[i] = false
    reussite_n15[i] = false
next i
global dim imgBadge[5*3] as integer
for i = 0 to 5*3-1
    imgBadge[i] = 0
next i

// chargement des paramètres de jeu
global nb_lancements as integer = 0
_param_load()
lancer_musique(music_onoff)

// on crée le sprite permettant d'afficher l'image de fond pendant toute la durée du jeu, puis on l'affiche
global sprImgFond as integer = 0
sprImgFond = createSprite(imgFond)
setSpriteSize(sprImgFond,ecran_largeur,ecran_hauteur)
setSpritePosition(sprImgFond,0,0)
setSpriteVisible(sprImgFond,false)
setSpriteActive(sprImgFond,false)
setSpriteDepth(sprImgFond,10000)

// initialisation des achats inApp lorsqu'ils sont gérés
global iap_onoff as integer = false
global iapVies as integer = -1
global iapBombes as integer = -1
global iapMelanges as integer = -1
global iapSwap as integer = -1
global iapSuppr as integer = -1
global iepBouees as integer = -1
if (GetDeviceBaseName() = "ios")
    iap_onoff = true
    inAppPurchaseSetTitle(getAppName())
    iapVies = 0
    inAppPurchaseAddProductID("bidioojoker",1)
    iapBombes = 1
    inAppPurchaseAddProductID("bidioobombes",1)
    iapMelanges = 2
    inAppPurchaseAddProductID("bidioomelanges",1)
    iapSwap = 3
    inAppPurchaseAddProductID("bidiooswap",1)
    iapSuppr = 4
    inAppPurchaseAddProductID("bidioosuppr",1)
    iepBouees = 5
    inAppPurchaseAddProductID("bidioohelp",1)
    inAppPurchaseSetup()
endif

// éléments liés à l'affichage des fenêtres (achats, saisie du pseudo en fin de partie, ...)
//      id de l'image de fond de la fenêtre
global imgFenetre as integer = 0
//      id du sprite de la fenêtre
global sprFenetre as integer = 0
//      id de l'image de validation
global imgOk as integer = 0
//      id du sprite de validation
global sprOk as integer = 0
//      id de l'image d'annulation
global imgCancel as integer = 0
//      id du sprite d'annulation
global sprCancel as integer = 0
//      id de l'image fleche gauche
global imgPrevious as integer = 0
//      id du sprite fleche gauche
global sprPrevious as integer = 0
//      id de l'image fleche droite
global imgNext as integer = 0
//      id du sprite fleche droite
global sprNext as integer = 0
//      ratio d'affichage si l'écran est pluspetit que la taille du visuel de la fenêtre
global fenetreRatio# as float = 0
//      coordonnées de l'angle haut/gauche de début de la zone de texte
global fenText_x1 as integer = 0
global fenText_y1 as integer = 0
//      coordonnées de l'angle bas/droite de fin de la zone de texte
global fenText_x2 as integer = 0
global fenText_y2 as integer = 0
//      coordonnées de l'angle haut/gauche de début de la zone de bouton
global fenBtn_x1 as integer = 0
global fenBtn_y1 as integer = 0
//      coordonnées de l'angle bas/droite de fin de la zone de bouton
global fenBtn_x2 as integer = 0
global fenBtn_y2 as integer = 0
//      coordonnées de l'angle haut/gauche de début de la zone de fermeture
global fenStop_x1 as integer = 0
global fenStop_y1 as integer = 0
//      coordonnées de l'angle bas/droite de fin de la zone de fermeture
global fenStop_x2 as integer = 0
global fenStop_y2 as integer = 0

// chargement des son utilisés dans le jeu
global sndClicOption as integer = 0
sndClicOption = loadSound("BoxComplete.wav")
global sndClicBonus0 as integer = 0
sndClicBonus0 = loadSound("SystemError.wav")
global sndBonusEnPlus as integer = 0
sndBonusEnPlus = loadSound("MagicStars.wav")
global sndBonusBombes as integer = 0
sndBonusBombes = loadSound("ExploMixLong.wav")
global sndBonusMelanges as integer = 0
sndBonusMelanges = loadSound("LoopAngryFlies.wav")
global sndBonusSwap as integer = 0
sndBonusSwap = loadSound("LoopInSpace.wav")
global sndBonusSuppr as integer = 0
sndBonusSuppr = loadSound("LaserShot.wav")
global sndBonusBouees as integer = 0
sndBonusBouees = loadSound("SparkleCave.wav")
global sndBonusVies as integer = 0
sndBonusVies = loadSound("Moan.wav")
global sndFinDePartie as integer = 0
sndFinDePartie = loadSound("GameOverRobot.wav")
global sndClic as integer = 0
sndClic = loadSound("16GUNDRY.WAV")
global sndCaseEnMoins as integer = 0
sndCaseEnMoins = loadSound("IceCubeExploding.wav")

rem appel de la page d'accueil du jeu
global premier_menu as integer
premier_menu = true
ecran_menu()
end

function ecran_menu()
    if (imgUp = 0) then imgUp = loadImage("up.png")
    do
        titre_largeur = 3*ecran_largeur/4
        titre_hauteur = ecran_hauteur/4
        titre_x = (ecran_largeur-getSpriteWidth(sprTitreJeu))/2
        titre_y = (ecran_hauteur/4)/3
        if (premier_menu = true)
            premier_menu = false
            setSpriteColorAlpha(sprImgFond,0)
            setSpriteVisible(sprImgFond,true)
            nb = 0
            repeat
                sortie = 0
                inc nb
                if (getSpriteColorAlpha(sprImgFond) < 255)
                    setSpriteColorAlpha(sprImgFond,getSpriteColorAlpha(sprImgFond)+1)
                else
                    inc sortie
                endif
/*                if (getSpriteX(sprTitreJeu) < titre_x)
                    setSpriteX(sprTitreJeu,getSpriteX(sprTitreJeu)+1)
                else */ if (getSpriteX(sprTitreJeu) > titre_x)
                    setSpriteX(sprTitreJeu,getSpriteX(sprTitreJeu)-1)
                else
                    inc sortie
                endif
/*                if (getSpriteY(sprTitreJeu) < titre_y)
                    setSpriteY(sprTitreJeu,getSpriteY(sprTitreJeu)+1)
                else */ if (getSpriteY(sprTitreJeu) > titre_y)
                    setSpriteY(sprTitreJeu,getSpriteY(sprTitreJeu)-1)
                else
                    inc sortie
                endif
                if (getSpriteWidth(sprTitreJeu) < titre_largeur)
                    setSpriteSize(sprTitreJeu,getSpriteWidth(sprTitreJeu)+1,getSpriteHeight(sprTitreJeu))
/*                elseif (getSpriteWidth(sprTitreJeu) > titre_largeur)
                    setSpriteSize(sprTitreJeu,getSpriteWidth(sprTitreJeu)-1,getSpriteHeight(sprTitreJeu)) */
                else
                    inc sortie
                endif
/*                if (getSpriteHeight(sprTitreJeu) < titre_hauteur)
                    setSpriteSize(sprTitreJeu,getSpriteWidth(sprTitreJeu),getSpriteHeight(sprTitreJeu)+1)
                else */ if (getSpriteHeight(sprTitreJeu) > titre_hauteur)
                    setSpriteSize(sprTitreJeu,getSpriteWidth(sprTitreJeu),getSpriteHeight(sprTitreJeu)-1)
                else
                    inc sortie
                endif
                if (getPointerPressed() = 1) then sortie = 5
                sync()
            until (sortie >= 5) or (nb > 1000)
            setSpriteColorAlpha(sprImgFond,255)
        endif
        setSpriteSize(sprTitreJeu,titre_largeur,titre_hauteur)
        setSpritePosition(sprTitreJeu,titre_x,titre_y)
        setSpriteVisible(sprTitreJeu,true)
        if (ecran_hauteur/4 > 100)
            taille_bouton = 100
        else
            taille_bouton = 8*ecran_hauteur/40
        endif
        addVirtualButton(4,ecran_largeur/3,2*ecran_hauteur/4,taille_bouton)
        setVirtualButtonImageUp(4,imgStart)
        setVirtualButtonAlpha(4,255)
        addVirtualButton(1,2*ecran_largeur/3,2*ecran_hauteur/4,taille_bouton)
        setVirtualButtonImageUp(1,imgScore)
        setVirtualButtonAlpha(1,255)
        if (left(getDeviceName(),7) = "windows") or (left(getDeviceName(),3) = "mac")
            nbbouton = 3
        else
            nbbouton = 2
        endif
        addVirtualButton(3,ecran_largeur/(nbbouton+1),3*ecran_hauteur/4,taille_bouton)
        setVirtualButtonImageUp(3,imgOptions)
        setVirtualButtonAlpha(3,255)
        addVirtualButton(2,2*ecran_largeur/(nbbouton+1),3*ecran_hauteur/4,taille_bouton)
        setVirtualButtonImageUp(2,imgCredits)
        setVirtualButtonAlpha(2,255)
        if (left(getDeviceName(),7) = "windows") or (left(getDeviceName(),3) = "mac")
            addVirtualButton(5,3*ecran_largeur/(nbbouton+1),3*ecran_hauteur/4,taille_bouton)
            setVirtualButtonImageUp(5,imgEteindre)
            setVirtualButtonAlpha(5,255)
        endif
        if (GetDeviceBaseName() = "ios") and (mod(nb_lancements, 30) = 0)
            rateApp("725209479","Bidioo","Merci de laisser une note et un commentaire sur le store.")
            nb_lancements = -1
        endif
        destination = 0
        repeat
            for i = 1 to 4
                if (getVirtualButtonPressed(i) = 1)
                    if (son_onoff = true) then playSound(sndClic,80,0)
                    destination = i
                endif
            next i
            if (left(getDeviceName(),7) = "windows") or (left(getDeviceName(),3) = "mac")
                if (getVirtualButtonPressed(5) = 1)
                    if (son_onoff = true) then playSound(sndClic,80,0)
                    destination = 5
                endif
            endif
            if (getRawKeyState(27) = 1) then exit
            sync()
        until (destination > 0)
        for i = 1 to 4
            deleteVirtualButton(i)
        next i
        if (left(getDeviceName(),7) = "windows") or (left(getDeviceName(),3) = "mac")
            deleteVirtualButton(5)
        endif
        setSpriteVisible(sprTitreJeu,false)
        if (getRawKeyState(27) = 1) then exit
        sync()
        select destination
            case 1:
                // clic sur bouton pour afficher les scores
                ecran_scores()
            endcase
            case 2:
                // clic sur bouton pour afficher les infos légales et remerciements
                ecran_credits()
            endcase
            case 3:
                // clic sur bouton pour afficher les réglages
                ecran_options()
            endcase
            case 4:
                // clic sur bouton pour lancer le jeu en solo
                ecran_jeu_solo()
            endcase
            case 5:
                // clic sur bouton pour quitter le programme
                exit
            endcase
        endselect
    loop
endfunction

function choix_theme(nom_image$)
    if ((nom_image$ <> theme_choisi$) or (nom_image$ <> theme_en_cours$))
        // suppression des données du thème précédent
        for i = 0 to nb_couleurs_max-1
            if (couleurs[i] > 0)
                deleteImage(couleurs[i])
                couleurs[i] = 0
            endif
        next i
        for x = 0 to grille_largeur-1
            for y = 0 to grille_hauteur-1
                i = grille_indice(x,y)
                if (grille[i].sprite > 0)
                    deleteSprite(grille[i].sprite)
                    grille[i].sprite = 0
                endif
            next y
        next x
        if (sprFondGrille > 0)
            img = getSpriteImageID(sprFondGrille)
            deleteSprite(sprFondGrille)
            sprFondGrille = 0
            deleteImage(img)
        endif
        // création de la liste des motifs du thème
        i = -1
        sortie = false
        repeat
            inc i
            j = random(0,49)
            repeat
                if (couleurs[j] <> 0)
                    inc j
                    if (j >= 49)
                        j = 0
                    endif
                endif
            until (couleurs[j] = 0)
            if (getFileExists(nom_image$+"-"+str(i)+".png") = 1)
                couleurs[j] = loadImage(nom_image$+"-"+str(i)+".png")
            elseif (getFileExists(nom_image$+"-"+str(i)+".jpg") = 1)
                couleurs[j] = loadImage(nom_image$+"-"+str(i)+".jpg")
            else
                sortie = true
            endif
        until (sortie = true)
        nb_couleurs_max = i
        for i = 0 to 48
            if (couleurs[i] = 0)
                j = i+1
                repeat
                    couleurs[i] = couleurs[j]
                    couleurs[j] = 0
                    inc j
                until (j > 49) or (couleurs[i] <> 0)
            endif
        next i
        // calcul des paramètres du nouveau thème
        case_largeur = getImageWidth(couleurs[0])
        case_hauteur = getImageHeight(couleurs[0])
        if (case_hauteur > case_largeur)
			case_largeur = case_largeur * 100 / case_hauteur
			case_hauteur = 100
		else
			case_hauteur = case_hauteur * 100/case_largeur
			case_largeur = 100
		endif
        larg = ecran_largeur - 100-3*10
        haut = ecran_hauteur - 2*10
        grille_largeur = larg / case_largeur
        if (grille_largeur > 8)
            grille_largeur = 8
        elseif (grille_largeur < 8)
            ratio# = grille_largeur / 8.0
            case_largeur = case_largeur * ratio#
            case_hauteur = case_hauteur * ratio#
            grille_largeur = 8
            if (case_largeur < 20) || (case_hauteur < 20)
                ratio# = grille_largeur / 7.0
                case_largeur = case_largeur * ratio#
                case_hauteur = case_hauteur * ratio#
                grille_largeur = 7
                if (case_largeur < 20) || (case_hauteur < 20)
                    ratio# = grille_largeur / 6.0
                    case_largeur = case_largeur * ratio#
                    case_hauteur = case_hauteur * ratio#
                    grille_largeur = 6
                endif
            endif
        endif
        grille_hauteur = haut / case_hauteur
        if (grille_hauteur > 8)
            grille_hauteur = 8
        endif
        rem grille_marge_gauche = 100+2*10 + (larg - (grille_largeur * case_largeur)) / 2
        grille_marge_gauche = ecran_largeur - 10 - grille_largeur * case_largeur
        grille_marge_haut = 10 + (haut - (grille_hauteur*case_hauteur)) / 2
        // création de la nouvelle grille de jeu
        for x = 0 to grille_largeur-1
            for y = 0 to grille_hauteur-1
                i = grille_indice(x,y)
                grille[i].x = x
                grille[i].y = y
                grille[i].couleur = -1
                grille[i].sprite = createSprite(0)
                setSpritePosition(grille[i].sprite,x*case_largeur+grille_marge_gauche,(grille_hauteur-y-1)*case_hauteur+grille_marge_haut)
                setSpriteSize(grille[i].sprite,case_largeur,case_hauteur)
                setSpriteGroup(grille[i].sprite,1)
                setSpriteDepth(grille[i].sprite,8000+i)
                case_desactive(x,y)
            next y
        next x
        // création du sprite de fond de la grille de jeu
        if (getFileExists(nom_image$+"-fond.jpg"))
            sprFondGrille = createSprite(loadImage(nom_image$+"-fond.jpg"))
            setSpritePosition(sprFondGrille,grille_marge_gauche,grille_marge_haut)
            setSpriteSize(sprFondGrille,case_largeur*grille_largeur,case_hauteur*grille_hauteur)
            setSpriteDepth(sprFondGrille,9000)
            setSpriteVisible(sprFondGrille,false)
            setSpriteActive(sprFondGrille,false)
        else
            sprFondGrille = 0
        endif
        // positionnement des logos des bonus et scores
        //      9 lignes de boutons, 10 pixels de marge en haut et bas et entre deux boutons
        remstart
			t = (ecran_hauteur - 10*2) / 9
			if (t > 80+10)
				t = 80
			elseif (t > 50+10)
				t = 50
			else
				t = (t*50)/60
			endif
        remend
        t = case_hauteur*grille_hauteur / 9
		remstart
        do
			print(case_hauteur)
			print(grille_hauteur)
			print(t)
			sync()
		loop
		remend
        for i = 0 to 8
            setSpriteSize(sprJeu[i],t,t)
            setSpritePosition(sprJeu[i],10,grille_marge_haut+i*t)
            if (txtJeu[i] <> 0)
                setTextFontImage(txtJeu[i],imgFontDorsa)
                setTextSize(txtJeu[i],t)
                setTextPosition(txtJeu[i],10+t,grille_marge_haut+i*t)
            endif
            remstart
            do
                print(ecran_hauteur)
                print(t)
                print(i)
                print(i*t*1.2)
                print((i*t*12)/10)
                print(10+1.2*t)
                print(10+(12*t)/10)
                sync()
                if (getPointerPressed() = 1)
                    exit
                endif
            loop
            remend
        next i
        setSpriteSize(sprJeu[9],t,t)
        setSpritePosition(sprJeu[9],10*2+getSpriteWidth(sprJeu[8]),GetSpriteY(sprJeu[8]))
        theme_choisi$ = nom_image$
        theme_en_cours$ = nom_image$
    endif
endfunction

function ecran_jeu_solo()
	c as integer = 0
    choix_theme(theme_choisi$)
    rem initialisation de la partie
    bonus_ajouter_score(0-score)
    score_temp = score
    setTextString(txtJeu[jeuScoreID],str(score_temp))
    niveau_de_jeu = 1
    bonus_ajouter_score_mult(1-score_mult)
    bonus_ajouter_vies(0-nb_vies)
    nb_couleurs = nb_couleurs_min
    grille_initialise()
    clic_x1 = -1
    clic_y1 = -1
    clic_x2 = -1
    clic_y2 = -1
    sens_x = 0
    sens_y = -1
    // affichage des éléments du jeu
    if (sprFondGrille > 0)
        setSpriteVisible(sprFondGrille,true)
    endif
    for i = 0 to 9
        setSpriteVisible(sprJeu[i],true)
        if (txtJeu[i] <> 0) then setTextVisible(txtJeu[i],true)
    next i
    setSpriteColorAlpha(sprJeu[jeuAideID],255-127*aide_onoff)
    // rechargement de la partie s'il y en avait une
    _load_jeu_solo()
    // suite du fonctionnement
    grille_remplissage(false)
    // affichage des écrans d'aide en début de partie
    if (aide_onoff = true) and (score = 0)
        if (imgModeDejeu[0] = 0) then imgModeDejeu[0] = loadImage("classic-100x100.png")
        if (imgModeDejeu[1] = 0) then imgModeDejeu[1] = loadImage("mixte-100x100.png")
        if (imgModeDejeu[2] = 0) then imgModeDejeu[2] = loadImage("master-100x100.png")
        aide_num = 0
        sortie = false
        repeat
            select aide_num
                case 0
                    btnClique = fenetre_texte("Bidioo est un jeu de réflexion.",0,"Pour faire un maximum de points, associez des motifs identiques par 3 ou plus en ligne ou en colonne.",false,true,false,true)
                endcase
                case 1
                    select mode_de_jeu
                        case 1
                            btnClique = fenetre_texte("La partie qui commence est en mode CLASSIC.",imgModeDejeu[0],"Cliquez sur une case pour la sélectionner, puis cliquer sur une case adjacente pour les inverser.",false,true,true,true)
                        endcase
                        case 2
                            btnClique = fenetre_texte("La partie qui commence est en mode MIXTE.",imgModeDejeu[1],"Cliquez sur une case pour la sélectionner, puis cliquer sur une case adjacente pour les inverser."+chr(10)+"Vous pouvez aussi cliquer sur une case et glisser votre doigt pour déplacer toute sa ligne ou sa colonne d'un cran.",false,true,true,true)
                        endcase
                        case 3
                            btnClique = fenetre_texte("La partie qui commence est en mode MASTER.",imgModeDejeu[2],"Cliquez sur une case puis faites glisser votre doigt horizontalement ou verticalement pour déplacer sa ligne ou sa colonne d'un cran.",false,true,true,true)
                        endcase
                    endselect
                endcase
                case 2
                    btnClique = fenetre_texte("Lorsque vous êtes coincé, vous pouvez utiliser l'un des bonus disponibles à gauche de votre écran.",0,"Les bonus se gagnent en associant plus de 3 motifs ensemble. Faites des combinaisons !",false,true,true,true)
                endcase
                case 3
                    btnClique = fenetre_texte("",imgVies,"Lorsque vous faites un mouvement sans regrouper de motifs, vous perdez un coeur."+chr(10)+"La partie s'arrête lorsque vous n'en avez plus.",false,true,true,true)
                endcase
                case 4
                    btnClique = fenetre_texte("",imgPause,"Met la partie en pause."+chr(10)+"Vous pouvez la reprendre quand vous voulez en relançant le jeu.",false,true,true,true)
                endcase
                case 5
                    btnClique = fenetre_texte("",imgAide,"Active ou désactive cette aide au démarrage d'une partie et en cours de jeu.",false,true,true,true)
                endcase
                case 6
                    btnClique = fenetre_texte("Vous êtes prêt ?",0,"C'est à vous de jouer... et que le meilleur gagne !",true,true,true,false)
                endcase
                case default
                    btnClique = 0
                endcase
            endselect
            select btnClique
                case 0
                    // Cancel
                    sortie = true
                endcase
                case 1
                    // Ok
                    sortie = true
                endcase
                case 2
                    // Next
                    inc aide_num
                endcase
                case 3
                    // Previous
                    dec aide_num
                endcase
            endselect
        until (sortie = true)
    endif
    rem boucle de jeu
    fin_de_partie = false
    sortie = false
    niveau_clic = 0
    repeat
        for i = 0 to grille_hauteur*grille_largeur-1
            grillebis[i] = grille[i].couleur
        next i
        if (score_temp <> score)
            if (score_temp <= score-10000)
                inc score_temp,10000
            elseif (score_temp <= score-1000)
                inc score_temp,1000
            elseif (score_temp <= score-100)
                inc score_temp,100
            elseif (score_temp <= score-10)
                inc score_temp,10
            elseif (score_temp <= score-1)
                inc score_temp,1
            elseif (score_temp > score)
                dec score_temp
            endif
            setTextString(txtJeu[jeuScoreID],str(score_temp))
        endif
        if (getPointerState() = 1)
            if (animation_bouee_onoff = true) then bonus_action_bouees_anime(false)
            sprite = getSpriteHit(screenToWorldX(getPointerX()),screenToWorldY(getPointerY()))
            if (sprite = sprJeu[jeuBombesID])
                // gestion du bonus "bombe": explosion de plusieurs cases aléatoirement
                setSpriteColorAlpha(sprite,128)
                sync()
                if (nb_bombes > 0)
                    bonus_retirer_bombes(1)
                    bonus_action_bombe()
                    grille_remplissage(true)
                else
                    // bonus inaccessible => proposer d'en acheter ou émettre un signal sonore
                    bonus_ajouter_bombes(iap_acheter_bonus(sprite,iapBombes,10,"bombe"))
                endif
                // on a fait l'inversion, on libère le clic
                while (getPointerState() = 1)
                    sync()
                endwhile
                // on réinitialise également le niveau de clic
                niveau_clic = 0
                setSpriteColorAlpha(sprite,255)
            elseif (sprite = sprJeu[jeuMelangesID])
                // gestion du bonus "mélange": mélange de la grille sous forme de swap en escargot
                setSpriteColorAlpha(sprite,128)
                sync()
                if (nb_melanges > 0)
                    bonus_retirer_melanges(1)
                    bonus_action_melange()
                    grille_remplissage(true)
                else
                    // bonus inaccessible => proposer d'en acheter ou émettre un signal sonore
                    bonus_ajouter_melanges(iap_acheter_bonus(sprite,iapMelanges,10,"ventilo"))
                endif
                // on a fait l'inversion, on libère le clic
                while (getPointerState() = 1)
                    sync()
                endwhile
                // on réinitialise également le niveau de clic
                niveau_clic = 0
                setSpriteColorAlpha(sprite,255)
            elseif (sprite = sprJeu[jeuSwapID])
                // gestion du bonus "swap": repeint toutes les cases de la grille en faisant des inversions de couleur
                setSpriteColorAlpha(sprite,128)
                sync()
                if (nb_swap > 0)
                    bonus_retirer_swap(1)
                    bonus_action_swap()
                    grille_remplissage(true)
                else
                    // bonus inaccessible => proposer d'en acheter ou émettre un signal sonore
                    bonus_ajouter_swap(iap_acheter_bonus(sprite,iapSwap,10,"rouleau"))
                endif
                // on a fait l'inversion, on libère le clic
                while (getPointerState() = 1)
                    sync()
                endwhile
                // on réinitialise également le niveau de clic
                niveau_clic = 0
                setSpriteColorAlpha(sprite,255)
            elseif (sprite = sprJeu[jeuSupprID])
                // gestion du bonus "suppr": supprime la couleur la plus représentée dans la grille
                setSpriteColorAlpha(sprite,128)
                sync()
                if (nb_suppr > 0)
                    bonus_retirer_suppr(1)
                    bonus_action_suppr()
                    grille_remplissage(true)
                else
                    // bonus inaccessible => proposer d'en acheter ou émettre un signal sonore
                    bonus_ajouter_suppr(iap_acheter_bonus(sprite,iapSuppr,10,"poubelle"))
                endif
                // on a fait l'inversion, on libère le clic
                while (getPointerState() = 1)
                    sync()
                endwhile
                // on réinitialise également le niveau de clic
                niveau_clic = 0
                setSpriteColorAlpha(sprite,255)
            elseif (sprite = sprJeu[jeuBoueesID])
                // gestion du bonus "bouee": propose un mouvement à faire mais si rien n'est dispo déclenche l'action d'un autre bonus au hasard
                setSpriteColorAlpha(sprite,128)
                sync()
                if (nb_bouees > 0)
                    bonus_retirer_bouees(1)
                    bonus_action_bouees()
                    while (getPointerState() = 1)
                        sync()
                    endwhile
                else
                    // bonus inaccessible => proposer d'en acheter ou émettre un signal sonore
                    bonus_ajouter_bouees(iap_acheter_bonus(sprite,iepBouees,10,"bouée"))
                endif
                // on a fait l'inversion, on libère le clic
                while (getPointerState() = 1)
                    sync()
                endwhile
                // on réinitialise également le niveau de clic
                niveau_clic = 0
                setSpriteColorAlpha(sprite,255)
            elseif (sprite = sprJeu[jeuAideID])
                // gestion du bonus "aide": passe le jeu en mode assistance
                aide_onoff = 1-aide_onoff
                _param_save()
                setSpriteColorAlpha(sprJeu[jeuAideID],255-127*aide_onoff)
                if (son_onoff = true) then playSound(sndClicOption,80,0)
                sync()
                // on a fait l'inversion, on libère le clic
                while (getPointerState() = 1)
                    sync()
                endwhile
                // on réinitialise également le niveau de clic
                niveau_clic = 0
            elseif (sprite = sprJeu[jeuPauseID])
                // gestion du bonus "pause": quitte la partie en permettant d'y revenir après
                setSpriteColorAlpha(sprite,128)
                if (son_onoff = true) then playSound(sndClicOption,80,0)
                sync()
                _save_jeu_solo()
                sortie = true
                // on a fait l'inversion, on libère le clic
                while (getPointerState() = 1)
                    sync()
                endwhile
                // on réinitialise également le niveau de clic
                niveau_clic = 0
                setSpriteColorAlpha(sprite,255)
            else
                select niveau_clic
                    case 0:
                        // premier appui sur la grille, on sélectionne le point d'origine
                        sprite = getSpriteHitGroup(1,screenToWorldX(getPointerX()),screenToWorldY(getPointerY()))
                        if (sprite > 0)
                            if (son_onoff = true) then playSound(sndClic,80,0)
                            clic_x1 = grille_indice_x(getSpriteDepth(sprite)-8000)
                            clic_y1 = grille_indice_y(getSpriteDepth(sprite)-8000)
                            niveau_clic = 1
                            setSpriteColorAlpha(sprite,128)
                        endif
                    endcase
                    case 2:
                        // swap entre deux cases adjacentes
                        if (mode_de_jeu = 1) or (mode_de_jeu = 2)
                            sprite = getSpriteHitGroup(1,screenToWorldX(getPointerX()),screenToWorldY(getPointerY()))
                            if (sprite > 0)
                                if (son_onoff = true) then playSound(sndClic,80,0)
                                clic_x2 = grille_indice_x(getSpriteDepth(sprite)-8000)
                                clic_y2 = grille_indice_y(getSpriteDepth(sprite)-8000)
                                sens_x = clic_x2 - clic_x1
                                sens_y = clic_y2 - clic_y1
                                if ((clic_x1 = clic_x2) and (abs(sens_y)=1)) or ((clic_y1 = clic_y2) and (abs(sens_x)=1))
                                    i1 = grille_indice(clic_x1,clic_y1)
                                    i2 = grille_indice(clic_x2,clic_y2)
                                    c = grille[i1].couleur
                                    grille[i1].couleur = grille[i2].couleur
                                    setSpriteImage(grille[i1].sprite,couleurs[grille[i1].couleur])
                                    grille[i2].couleur = c
                                    setSpriteImage(grille[i2].sprite,couleurs[c])
                                    setSpriteColorAlpha(grille[i1].sprite,128)
                                    setSpriteColorAlpha(grille[i2].sprite,128)
                                    sync()
                                    sleep(50)
                                    setSpriteColorAlpha(grille[i1].sprite,255)
                                    setSpriteColorAlpha(grille[i2].sprite,255)
                                    if (grille_collisions(true) = true)
                                        grille_remplissage(true)
                                    else
                                        fin_de_partie = perdre_une_vie()
                                    endif
                                    // on a fait l'inversion, on libère le clic
                                    niveau_clic = 0
                                    while (getPointerState() = 1)
                                        sync()
                                    endwhile
                                elseif (clic_x1 = clic_x2) and (clic_y1 = clic_y2)
                                    // on est sur la même case, on repasse en mode 1
                                    niveau_clic = 1
                                else
                                    // on a cliqué ailleurs, on prend cette nouvelle case comme point d'origine (idem cas niveau_clic=0)
                                    setSpriteColorAlpha(grille[grille_indice(clic_x1,clic_y1)].sprite,255)
                                    setSpriteColorAlpha(sprite,128)
                                    clic_x1 = clic_x2
                                    clic_y1 = clic_y2
                                    niveau_clic = 1
                                endif
                            endif
                        endif
                    endcase
                endselect
            endif
        elseif (getPointerState() = 0)
            select niveau_clic
                case 1:
                    sprite = getSpriteHitGroup(1,screenToWorldX(getPointerX()),screenToWorldY(getPointerY()))
                    if (sprite > 0)
                        clic_x2 = grille_indice_x(getSpriteDepth(sprite)-8000)
                        clic_y2 = grille_indice_y(getSpriteDepth(sprite)-8000)
                        if (clic_x1 = clic_x2) and (clic_y1 = clic_y2)
                            if (mode_de_jeu = 1) or (mode_de_jeu = 2)
                                // si on est sur la même case, on part sur le principe de l'inversion de deux billes (ou on désactive la case)
                                niveau_clic = 2
                            else
                                niveau_clic = 0
                                setSpriteColorAlpha(sprite,255)
                            endif
                        elseif (clic_x1 = clic_x2) or (clic_y1 = clic_y2)
                            setSpriteColorAlpha(grille[grille_indice(clic_x1,clic_y1)].sprite,255)
                            if (mode_de_jeu = 2) or (mode_de_jeu = 3)
                                // si on est sur une case différente, on regarde si elle est sur la même ligne ou même colonne et on déclenche le mouvement de la ligne
                                if (clic_x1 > clic_x2)
                                    sens_x = -1
                                elseif (clic_x1 < clic_x2)
                                    sens_x = 1
                                else
                                    sens_x = 0
                                endif
                                if (clic_y1 > clic_y2)
                                    sens_y = -1
                                elseif (clic_y1 < clic_y2)
                                    sens_y = 1
                                else
                                    sens_y = 0
                                endif
                                grille_ligne_bouge(clic_x1,clic_y1,sens_x,sens_y)
                                if (grille_collisions(true) = true)
                                    grille_remplissage(true)
                                else
                                    fin_de_partie = perdre_une_vie()
                                endif
                            endif
                            niveau_clic = 0
                        else
                            // on désactive la sélection : le doigt a été relaché ailleurs
                            niveau_clic = 0
                            setSpriteColorAlpha(grille[grille_indice(clic_x1,clic_y1)].sprite,255)
                        endif
                    endif
                endcase
            endselect
        endif
        if (getRawKeyState(27) = 1)
            repeat
                sync()
            until (getRawKeyState(27) <> 1)
            sortie = true
        endif
        bonus_action_bouees_anime(animation_bouee_onoff)
        sync()
        for i = 0 to grille_hauteur*grille_largeur-1
            if (grillebis[i] <> grille[i].couleur)
                _save_jeu_solo()
                exit
            endif
        next i
    until (fin_de_partie = true) or (sortie = true)
    if (fin_de_partie = true) and (1 = getFileExists("game.dat")) then deleteFile("game.dat")
    grille_initialise()
endfunction

function perdre_une_vie()
    if (son_onoff = true) then playSound(sndBonusVies,80,0)
    if (nb_vies > 0)
        fin_de_partie = false
        bonus_retirer_vies(1)
    else
        bonus_ajouter_vies(iap_acheter_vie(sprJeu[jeuViesID],iapVies,10,"coeur"))
        if (nb_vies < 1)
            fin_de_partie = true
            enregistrement_du_score()
        endif
    endif
endfunction fin_de_partie

function grille_initialise()
    // effacement des cases de la grille
    for x = 0 to grille_largeur-1
        for y = 0 to grille_hauteur-1
            grille[grille_indice(x,y)].couleur = -1
            case_desactive(x,y)
        next y
    next x
    // effacement du fond de la grille
    if (sprFondGrille > 0)
        setSpriteVisible(sprFondGrille,false)
    endif
    // effacement des boutons liés au jeu
    for i = 0 to 9
        setSpriteVisible(sprJeu[i],false)
        if (txtJeu[i] <> 0) then setTextVisible(txtJeu[i],false)
    next i
endfunction

function grille_indice(x,y)
    if (x > grille_largeur-1)
        x = grille_largeur-1
    endif
    if (x < 0)
        x = 0
    endif
    if (y > grille_hauteur-1)
        y = grille_hauteur-1
    endif
    if (y < 0)
        y = 0
    endif
    result = x+y*grille_largeur
endfunction result

function grille_indice_x(i)
    result = mod(i, grille_largeur)
endfunction result

function grille_indice_y(i)
    result = i / grille_largeur
endfunction result

function grille_remplissage(jeu_en_cours)
    repeat
        immobile = true
        if (sens_x = 1)
            // le remplissage se fait de la gauche vers la droite
            for x = 0 to grille_largeur-1
                for y = grille_hauteur-1 to 0 step -1
                    immobile = grille_cellule_swap(x,y,immobile)
                next y
            next x
        elseif (sens_x = -1)
            // le remplissage se fait de la droite vers la gauche
            for x = 0 to grille_largeur-1
                for y = 0 to grille_hauteur-1
                    immobile = grille_cellule_swap(x,y,immobile)
                next y
            next x
        elseif (sens_y = 1)
            // le remplissage se fait du bas vers le haut
            for y = 0 to grille_hauteur-1
                for x = grille_largeur-1 to 0 step -1
                    immobile = grille_cellule_swap(x,y,immobile)
                next x
            next y
        else
            // le remplissage se fait du haut vers le bas
            for y = 0 to grille_hauteur-1
                for x = 0 to grille_largeur-1
                    immobile = grille_cellule_swap(x,y,immobile)
                next x
            next y
        endif
        if (immobile = false)
            sync()
            sleep(50)
        endif
        if (grille_collisions(jeu_en_cours) = true)
            immobile = false
        endif
    until immobile = true
endfunction

function case_desactive(x,y)
    i = grille_indice(x,y)
    grille[i].couleur = -1
    setSpriteVisible(grille[i].sprite,false)
    setSpriteActive(grille[i].sprite,false)
endfunction

function grille_cellule_swap(x,y,immobile)
    i = grille_indice(x,y)
    if (grille[i].couleur < 0)
        if (x-sens_x >= 0) and (y-sens_y >= 0) and (x-sens_x <= grille_largeur-1) and (y-sens_y <= grille_hauteur-1)
            grille[i].couleur = grille[grille_indice(x-sens_x,y-sens_y)].couleur
            case_desactive(x-sens_x,y-sens_y)
        else
            grille[i].couleur = random(0,nb_couleurs-1)
        endif
        if (grille[i].couleur > -1)
            setSpriteImage(grille[i].sprite,couleurs[grille[i].couleur])
            setSpriteVisible(grille[i].sprite,true)
            setSpriteActive(grille[i].sprite,true)
        endif
        immobile = false
    endif
endfunction immobile

function grille_collisions(jeu_en_cours)
    nb_points = 0
    nb_cases = 0
    collision = false
    for x = 0 to grille_largeur-1
        for y = 0 to grille_hauteur-1-2
            i = grille_indice(x,y)
            if (grille[i].couleur <> -1) and (grille[i].couleur = grille[grille_indice(x,y+1)].couleur) and (grille[i].couleur = grille[grille_indice(x,y+2)].couleur)
                grille_collisions_validee(grille[i].couleur,x,y,jeu_en_cours)
                collision = true
            endif
        next y
    next x
    for y = 0 to grille_hauteur-1
        for x = 0 to grille_largeur-1-2
            i = grille_indice(x,y)
            if (grille[i].couleur <> -1) and (grille[i].couleur = grille[grille_indice(x+1,y)].couleur) and (grille[i].couleur = grille[grille_indice(x+2,y)].couleur)
                grille_collisions_validee(grille[i].couleur,x,y,jeu_en_cours)
                collision = true
            endif
        next x
    next y
    if (collision = true) and (jeu_en_cours = true)
        // modification du niveau en fonction du score :
        if (score >= 1000*niveau_de_jeu*niveau_de_jeu)
            bonus_ajouter_niveau_de_jeu(1)
        endif
        // attribution d'un bonus en fonction du nombre de cases détruites
        okbonus = false
        if (nb_cases > 10) and (random(0,5) < 3)
            bonus_ajouter_vies(1)
            okbonus = true
        elseif (nb_cases > 5) and (random(0,5) < 3)
            bonus_ajouter_bouees(1)
            okbonus = true
        elseif (nb_cases > 3)
            select (random(0,15))
                case 0:
                    bonus_ajouter_bombes(1)
                    okbonus = true
                endcase
                case 1:
                    bonus_ajouter_melanges(1)
                    okbonus = true
                endcase
                case 2:
                    bonus_ajouter_swap(1)
                    okbonus = true
                endcase
                case 3:
                    bonus_ajouter_suppr(1)
                    okbonus = true
                endcase
                case 4:
                    if (score_mult < niveau_de_jeu)
                        bonus_ajouter_score_mult(1)
                        okbonus = true
                    endif
                endcase
            endselect
        endif
        if ((son_onoff = true) and (okbonus = true)) then playSound(sndBonusEnPlus,80,0)
        sync()
        sleep(50)
    endif
endfunction collision

function grille_collisions_validee(couleur,x,y,jeu_en_cours)
    if (x >= 0) and (x <= grille_largeur-1) and (y >= 0) and (y <= grille_hauteur-1)
        if (grille[grille_indice(x,y)].couleur = couleur)
            if (jeu_en_cours = true)
                inc nb_points
                inc nb_cases
                bonus_ajouter_score(nb_points*score_mult)
                if (son_onoff = true) then playSound(sndCaseEnMoins,80,0)
            endif
            case_desactive(x,y)
            grille_collisions_validee(couleur,x-1,y,jeu_en_cours)
            grille_collisions_validee(couleur,x+1,y,jeu_en_cours)
            grille_collisions_validee(couleur,x,y-1,jeu_en_cours)
            grille_collisions_validee(couleur,x,y+1,jeu_en_cours)
        endif
    endif
endfunction

function grille_ligne_bouge(x,y,sens_x,sens_y)
	c as integer = 0
    if (sens_x = 0)
        // deplacement d'une colonne
        if (sens_y = 1)
            // le remplissage se fait du bas vers le haut
            c = grille[grille_indice(x,grille_hauteur-1)].couleur
            for y = grille_hauteur-1 to 1 step -1
                i = grille_indice(x,y)
                grille[i].couleur = grille[grille_indice(x,y-1)].couleur
                setSpriteImage(grille[i].sprite,couleurs[grille[i].couleur])
            next y
            grille[grille_indice(x,0)].couleur = c
            setSpriteImage(grille[grille_indice(x,0)].sprite,couleurs[c])
        elseif (sens_y = -1)
            // le remplissage se fait du haut vers le bas
            c = grille[grille_indice(x,0)].couleur
            for y = 0 to grille_hauteur-1-1
                i = grille_indice(x,y)
                grille[i].couleur = grille[grille_indice(x,y+1)].couleur
                setSpriteImage(grille[i].sprite,couleurs[grille[i].couleur])
            next y
            grille[grille_indice(x,grille_hauteur-1)].couleur = c
            setSpriteImage(grille[grille_indice(x,grille_hauteur-1)].sprite,couleurs[c])
        endif
    elseif (sens_y = 0)
        // deplacement d'une ligne
        if (sens_x = 1)
            // le remplissage se fait de la gauche vers la droite
            c = grille[grille_indice(grille_largeur-1,y)].couleur
            for x = grille_largeur-1 to 1 step -1
                i = grille_indice(x,y)
                grille[i].couleur = grille[grille_indice(x-1,y)].couleur
                setSpriteImage(grille[i].sprite,couleurs[grille[i].couleur])
            next x
            grille[grille_indice(0,y)].couleur = c
            setSpriteImage(grille[grille_indice(0,y)].sprite,couleurs[c])
        elseif (sens_x = -1)
            // le remplissage se fait de la droite vers la gauche
            c = grille[grille_indice(0,y)].couleur
            for x = 0 to grille_largeur-1-1
                i = grille_indice(x,y)
                grille[i].couleur = grille[grille_indice(x+1,y)].couleur
                setSpriteImage(grille[i].sprite,couleurs[grille[i].couleur])
            next x
            grille[grille_indice(grille_largeur-1,y)].couleur = c
            setSpriteImage(grille[grille_indice(grille_largeur-1,y)].sprite,couleurs[c])
        endif
    endif
    sync()
    sleep(50)
endfunction

function ecran_jeu_duo()
endfunction

function ecran_jeu_reseau()
endfunction

function ecran_credits()
	fenetre_texte("",0,"Développement :"+chr(10)+"Patrick Prémartin avec AGK2"+chr(10)+chr(10)+"Graphisme :"+chr(10)+"kolopach (Fotolia.com)"+chr(10)+"Laz'e-Pete (Fotolia.com)"+chr(10)+"David Gervais"+chr(10)+"Patrick Prémartin"+chr(10)+chr(10)+"Musique :"+chr(10)+"Virginia Culp"+chr(10)+chr(10)+"Bruitages :"+chr(10)+"Mark Sheeky (TGC) & co"+chr(10)+chr(10)+"(c) Olf Software 2013-2015",true,false,false,false)
remstart
    if (imgUp = 0) then imgUp = loadImage("up.png")
    if (imgAGK = 0) then imgAGK = loadImage("Made-With-AGK-White-128px.png")
    if (imgGAMOLF = 0) then imgGAMOLF = loadImage("gamolf-150x150.png")
    // positionnement et affichage du titre
    titre_largeur = 3*ecran_largeur/4
    titre_hauteur = ecran_hauteur/4
    titre_x = (ecran_largeur-getSpriteWidth(sprTitreJeu))/2
    titre_y = (ecran_hauteur/4)/3
    setSpriteSize(sprTitreJeu,titre_largeur,titre_hauteur)
    setSpritePosition(sprTitreJeu,titre_x,titre_y)
    setSpriteVisible(sprTitreJeu,true)
    // positionnement du bouton de retour au menu
    if (ecran_hauteur/4 > 50)
        taille_bouton = 50
    else
        taille_bouton = ecran_hauteur*0.2
    endif
    addVirtualButton(1,ecran_largeur-taille_bouton,ecran_hauteur-taille_bouton,taille_bouton)
    setVirtualButtonImageUp(1,imgUp)
    setVirtualButtonAlpha(1,255)
    addVirtualButton(2,ecran_largeur-taille_bouton,ecran_hauteur-taille_bouton*2.5,taille_bouton)
    setVirtualButtonImageUp(2,imgAGK)
    setVirtualButtonAlpha(2,255)
    addVirtualButton(3,ecran_largeur-taille_bouton,ecran_hauteur-taille_bouton*4,taille_bouton)
    setVirtualButtonImageUp(3,imgGAMOLF)
    setVirtualButtonAlpha(3,255)
    espacement = 5
    nombre_de_lignes = 0
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("Developpement : Patrick Premartin")
    positionner_texte(textes[nombre_de_lignes],getSpriteY(sprTitreJeu)+getSpriteHeight(sprTitreJeu))
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("")
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("Graphisme : kolopach & Laz'e-Pete (Fotolia.com), David Gervais, Patrick Prémartin")
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("")
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("Musique : Virginia Culp")
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("")
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("Bruitages : Mark Sheeky (TGC) & co")
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("")
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("(c) Olf Software 2013")
    positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
    repeat
        sync()
        if (getVirtualButtonPressed(2) = 1)
            if (son_onoff = true) then playSound(sndClic,80,0)
            openBrowser("http://www.appgamekit.com")
        elseif (getVirtualButtonPressed(3) = 1)
            if (son_onoff = true) then playSound(sndClic,80,0)
            openBrowser("http://www.gamolf.fr")
        endif
    until (getVirtualButtonPressed(1) = 1)
    if (son_onoff = true) then playSound(sndClic,80,0)
    // réinitialisation de l'affichage
    deleteVirtualButton(1)
    deleteVirtualButton(2)
    deleteVirtualButton(3)
    setSpriteVisible(sprTitreJeu,false)
    for i = 1 to nombre_de_lignes
        deleteText(textes[i])
    next i
remend
endfunction

function ecran_options()
    // chargement initial des images si elles ne le sont pas encore
    if (imgUp = 0) then imgUp = loadImage("up.png")
    if (imgMusic = 0) then imgMusic = loadImage("musique.png")
    if (imgSon = 0) then imgSon = loadImage("micro.png")
    if (imgModeDejeu[0] = 0) then imgModeDejeu[0] = loadImage("classic-100x100.png")
    if (imgModeDejeu[1] = 0) then imgModeDejeu[1] = loadImage("mixte-100x100.png")
    if (imgModeDejeu[2] = 0) then imgModeDejeu[2] = loadImage("master-100x100.png")
    for i = 0 to theme_nb-1
        if (theme_images[i] = 0)
            if (getFileExists(theme_liste$[i]+"-0.png") = 1)
                theme_images[i] = loadImage(theme_liste$[i]+"-0.png")
            elseif (getFileExists(theme_liste$[i]+"-0.jpg") = 1)
                theme_images[i] = loadImage(theme_liste$[i]+"-0.jpg")
            endif
        endif
    next i
    dim theme_sprite[theme_nb] as integer
    dim choix_mode_de_jeu[3] as integer
    // positionnement et affichage du titre
    titre_largeur = 3*ecran_largeur/4
    titre_hauteur = ecran_hauteur/4
    titre_x = (ecran_largeur-getSpriteWidth(sprTitreJeu))/2
    titre_y = (ecran_hauteur/4)/3
    setSpriteSize(sprTitreJeu,titre_largeur,titre_hauteur)
    setSpritePosition(sprTitreJeu,titre_x,titre_y)
    setSpriteVisible(sprTitreJeu,true)
    // positionnement du bouton de retour au menu
    if (ecran_hauteur/4 > getImageHeight(imgUp))
        taille_bouton = getImageHeight(imgUp)
    else
        taille_bouton = ecran_hauteur/4
    endif
    addVirtualButton(1,ecran_largeur-taille_bouton/2-10,ecran_hauteur-taille_bouton/2-10,taille_bouton*0.9)
    setVirtualButtonImageUp(1,imgUp)
    setVirtualButtonAlpha(1,255)
    espacement = 10
    nombre_de_lignes = 0
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("Choisissez votre ambiance de jeu :")
    positionner_texte(textes[nombre_de_lignes],getSpriteY(sprTitreJeu)+getSpriteHeight(sprTitreJeu))
    theme_i = 0
    for i = 0 to theme_nb-1
        theme_sprite[i] = createSprite(theme_images[i])
        setSpriteDepth(theme_sprite[i],getSpriteDepth(theme_sprite[i])+1)
        setSpritePosition(theme_sprite[i],(i+1)*ecran_largeur/(theme_nb+1)-taille_bouton/2,getTextY(textes[nombre_de_lignes])+getTextTotalHeight(textes[nombre_de_lignes])+espacement)
        setSpriteSize(theme_sprite[i],-1,taille_bouton*0.9)
        setSpriteVisible(theme_sprite[i],true)
        setSpriteActive(theme_sprite[i],true)
        if (theme_choisi$ = theme_liste$[i])
            setSpriteColorAlpha(theme_sprite[i],128)
            theme_i = i
        else
            setSpriteColorAlpha(theme_sprite[i],255)
        endif
    next i
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("Choisissez votre mode de jeu :")
    positionner_texte(textes[nombre_de_lignes],getSpriteY(theme_sprite[0])+getSpriteHeight(theme_sprite[0])+espacement*2)
    choix_i = 0
    for i = 0 to 2
        choix_mode_de_jeu[i] = createSprite(imgModeDejeu[i])
        setspriteDepth(choix_mode_de_jeu[i],getSpriteDepth(choix_mode_de_jeu[i])+1)
        setSpritePosition(choix_mode_de_jeu[i],(i+1)*ecran_largeur/(3+1)-taille_bouton/2,getTextY(textes[nombre_de_lignes])+getTextTotalHeight(textes[nombre_de_lignes])+espacement)
        setSpriteSize(choix_mode_de_jeu[i],-1,taille_bouton*0.9)
        setSpriteVisible(choix_mode_de_jeu[i],true)
        setSpriteActive(choix_mode_de_jeu[i],true)
        if (mode_de_jeu = i+1)
            setSpriteColorAlpha(choix_mode_de_jeu[i],128)
            choix_i = i
        else
            setSpriteColorAlpha(choix_mode_de_jeu[i],255)
        endif
    next i
    // affichage des boutons de musique on/off et bruitage on/off
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("Environnement sonore :")
    positionner_texte(textes[nombre_de_lignes],getSpriteY(choix_mode_de_jeu[0])+getSpriteHeight(choix_mode_de_jeu[0])+espacement*2)
    sprMusic = createSprite(imgMusic)
    setSpriteDepth(sprMusic,getSpriteDepth(sprMusic)+1)
    setSpritePosition(sprMusic,ecran_largeur/3-taille_bouton/2,getTextY(textes[nombre_de_lignes])+getTextTotalHeight(textes[nombre_de_lignes])+espacement)
    setSpriteSize(sprMusic,taille_bouton,taille_bouton)
    setSpriteVisible(sprMusic,true)
    setSpriteActive(sprMusic,true)
    setSpriteColorAlpha(sprMusic,255-127*music_onoff)
    sprSon = createSprite(imgSon)
    setSpriteDepth(sprSon,getSpriteDepth(sprSon)+1)
    setSpritePosition(sprSon,2*ecran_largeur/3-taille_bouton/2,getTextY(textes[nombre_de_lignes])+getTextTotalHeight(textes[nombre_de_lignes])+espacement)
    setSpriteSize(sprSon,taille_bouton,taille_bouton)
    setSpriteVisible(sprSon,true)
    setSpriteActive(sprSon,true)
    setSpriteColorAlpha(sprSon,255-127*son_onoff)
    // décalage des textes en background au cas où une fenêtre d'infos doive s'afficher
    for i = 1 to nombre_de_lignes
        setTextDepth(textes[i],getTextDepth(textes[i])+10)
    next i
    // traitement des options disponibles à l'écran
    destination = 0
    repeat
        sync()
        if (getPointerPressed() = 1)
            x = screenToWorldX(getPointerX())
            y = screenToWorldY(getPointerY())
            for i = 0 to theme_nb-1
                if (getSpriteHitTest(theme_sprite[i],x,y) = 1)
                    setSpriteColorAlpha(theme_sprite[theme_i],255)
                    theme_i = i
                    setSpriteColorAlpha(theme_sprite[theme_i],128)
                    theme_choisi$ = theme_liste$[theme_i]
                    _param_save()
                    if (son_onoff = true) then playSound(sndClicOption,80,0)
                endif
            next i
            for i = 0 to 2
                if (getSpriteHitTest(choix_mode_de_jeu[i],x,y) = 1)
                    setSpriteColorAlpha(choix_mode_de_jeu[choix_i],255)
                    choix_i = i
                    setSpriteColorAlpha(choix_mode_de_jeu[choix_i],128)
                    mode_de_jeu = i+1
                    _param_save()
                    if (son_onoff = true) then playSound(sndClicOption,80,0)
                    if (aide_onoff = true)
                        select mode_de_jeu
                            case 1
                                fenetre_texte("Mode de jeu CLASSIC",imgModeDejeu[0],"Associez les cases deux par deux pour regrouper au moins 3 motifs identiques.",true,false,false,false)
                            endcase
                            case 2
                                fenetre_texte("Mode de jeu MIXTE",imgModeDejeu[1],"Associez les cases deux par deux ou déplacer les lignes et les colonnes pour regrouper au moins 3 motifs identiques.",true,false,false,false)
                            endcase
                            case 3
                                fenetre_texte("Mode de jeu MASTER",imgModeDejeu[2],"Déplacez les lignes et les colonnes pour regrouper au moins 3 motifs identiques.",true,false,false,false)
                            endcase
                        endselect
                    endif
                endif
            next i
            if (getSpriteHitTest(sprMusic,x,y) = 1)
                music_onoff = 1-music_onoff
                _param_save()
                setSpriteColorAlpha(sprMusic,255-127*music_onoff)
                if (son_onoff = true) then playSound(sndClicOption,80,0)
                lancer_musique(music_onoff)
            elseif (getSpriteHitTest(sprSon,x,y) = 1)
                son_onoff = 1-son_onoff
                _param_save()
                setSpriteColorAlpha(sprSon,255-127*son_onoff)
                if (son_onoff = true) then playSound(sndClicOption,80,0)
                if (son_onoff = false)
                    // au cas où, on s'assure que tous les sons sont bien coupés
                    stopSound(sndClicOption)
                    stopSound(sndClicBonus0)
                    stopSound(sndBonusEnPlus)
                    stopSound(sndBonusBombes)
                    stopSound(sndBonusMelanges)
                    stopSound(sndBonusSwap)
                    stopSound(sndBonusSuppr)
                    stopSound(sndBonusBouees)
                    stopSound(sndBonusVies)
                    stopSound(sndFinDePartie)
                    stopSound(sndClic)
                    stopSound(sndCaseEnMoins)
                endif
            endif
        endif
    until (getVirtualButtonPressed(1) = 1)
    if (son_onoff = true) then playSound(sndClic,80,0)
    // réinitialisation de l'affichage
    deleteVirtualButton(1)
    setSpriteVisible(sprTitreJeu,false)
    for i = 1 to nombre_de_lignes
        deleteText(textes[i])
    next i
    for i = 0 to theme_nb-1
        deleteSprite(theme_sprite[i])
    next i
    for i = 0 to 2
        deleteSprite(choix_mode_de_jeu[i])
    next i
    deleteSprite(sprMusic)
    deleteSprite(sprSon)
endfunction

function ecran_scores()
    if (imgUp = 0) then imgUp = loadImage("up.png")
    if (imgGCScore = 0) then imgGCScore = loadImage("graphique.png")
    if (imgReussites = 0) then imgReussites = loadImage("badges.png")
    // positionnement et affichage du titre
    titre_largeur = 3*ecran_largeur/4
    titre_hauteur = ecran_hauteur/4
    titre_x = (ecran_largeur-getSpriteWidth(sprTitreJeu))/2
    titre_y = (ecran_hauteur/4)/3
    setSpriteSize(sprTitreJeu,titre_largeur,titre_hauteur)
    setSpritePosition(sprTitreJeu,titre_x,titre_y)
    setSpriteVisible(sprTitreJeu,true)
    // positionnement du bouton de retour au menu
    if (ecran_hauteur/4 > GetImageHeight(imgUp))
        taille_bouton = GetImageHeight(imgUp)
    else
        taille_bouton = ecran_hauteur/4
    endif
    // bouton Sortie / Retour au menu
    addVirtualButton(1,ecran_largeur-taille_bouton/2-10,ecran_hauteur-taille_bouton/2-10,taille_bouton*0.9)
    setVirtualButtonImageUp(1,imgUp)
    setVirtualButtonAlpha(1,255)
    // bouton Achievements de Apple Game Center / affichage des badges en local si pas de Game Center
    addVirtualButton(3,ecran_largeur-taille_bouton/2-10,ecran_hauteur-taille_bouton/2-taille_bouton-10,taille_bouton*0.9)
    setVirtualButtonImageUp(3,imgReussites)
    setVirtualButtonAlpha(3,255)
    if (gamecenter_onoff = true)
        // bouton Leaderboards de Apple Game Center
        addVirtualButton(2,ecran_largeur-taille_bouton/2-10,ecran_hauteur-taille_bouton/2-taille_bouton*2-10,taille_bouton*0.9)
        setVirtualButtonImageUp(2,imgGCScore)
        setVirtualButtonAlpha(2,255)
    endif
    // chargement des scores
    _scores_load()
    espacement = 5
    nombre_de_lignes = 0
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("Classement")
    positionner_texte(textes[nombre_de_lignes],getSpriteY(sprTitreJeu)+getSpriteHeight(sprTitreJeu))
    setTextSize(textes[nombre_de_lignes],getTextSize(textes[nombre_de_lignes])*2)
    nb_carac = 30
    i = 1
    repeat
        if (meilleursScores[i].score > 0)
            inc nombre_de_lignes
            textes[nombre_de_lignes] = createText(meilleursScores[i].pseudo$+spaces(nb_carac-len(meilleursScores[i].pseudo$)-len(str(meilleursScores[i].score)))+str(meilleursScores[i].score))
            positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
        elseif (meilleursScores[i].niveau > 0)
            inc nombre_de_lignes
            textes[nombre_de_lignes] = createText(meilleursScores[i].pseudo$+spaces(nb_carac-len(meilleursScores[i].pseudo$)-len(str(meilleursScores[i].niveau)))+str(meilleursScores[i].niveau))
            positionner_texte(textes[nombre_de_lignes],getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1])+espacement)
        endif
        inc i
    until (i >  nbMeilleursScoresMax) or (getTextY(textes[nombre_de_lignes])+getTextTotalHeight(textes[nombre_de_lignes])*4 > ecran_hauteur)
    for i = 1 to nombre_de_lignes
        setTextDepth(textes[i],getTextDepth(textes[i])+10)
    next i
    // attente d'un clic pour revenir au menu
    destination = 0
    repeat
		remstart
		print(ecran_largeur)
		print(ecran_hauteur)
		print(taille_bouton)
		remend
        sync()
        if (getVirtualButtonPressed(3) = 1)
            if (son_onoff = true) then playSound(sndClic,80,0)
            if (gamecenter_onoff = true)
                gameCenterAchievementsShow()
            else
                fenetre_badges()
            endif
        elseif (gamecenter_onoff = true)
            if (getVirtualButtonPressed(2) = 1)
                if (son_onoff = true) then playSound(sndClic,80,0)
                gameCenterShowLeaderBoard("bidioo"+str(mode_de_jeu))
            endif
        endif
    until (getVirtualButtonPressed(1) = 1)
    if (son_onoff = true) then playSound(sndClic,80,0)
    // réinitialisation de l'affichage
    deleteVirtualButton(1)
    deleteVirtualButton(3)
    if (gamecenter_onoff = true)
        deleteVirtualButton(2)
    endif
    setSpriteVisible(sprTitreJeu,false)
    for i = 1 to nombre_de_lignes
        deleteText(textes[i])
    next i
endfunction

rem ********************
rem * chargement des 20 meilleurs scores
rem ********************
function _scores_load()
    for i = 1 to nbMeilleursScoresMax
        meilleursScores[i].pseudo$ = ""
        meilleursScores[i].niveau = 0
        meilleursScores[i].score = 0
        meilleursScores[i].transmis$ = "N"
    next i
    score1 as tscore
    score2 as tscore
    if (1 = getFileExists("scores.dat"))
        f = openToRead("scores.dat")
        while (0 = FileEOF(f))
            ch$ = readLine(f)
            if (4 = CountStringTokens(ch$,"|"))
                score1.pseudo$ = getStringToken(ch$,"|",1)
                score1.niveau = val(getStringToken(ch$,"|",2))
                score1.score = val(getStringToken(ch$,"|",3))
                score1.transmis$ = getStringToken(ch$,"|",4)
                phase = 1
                for i = 1 to nbMeilleursScoresMax
                    if (phase = 1) and ((meilleursScores[i].score < score1.score) or ((meilleursScores[i].score = score1.score) and (meilleursScores[i].niveau < score1.niveau)))
                        score2 = meilleursScores[i]
                        meilleursScores[i] = score1
                        phase = 2
                    elseif (phase = 2)
                        score1 = score2
                        score2 = meilleursScores[i]
                        meilleursScores[i] = score1
                    endif
                next i
            endif
        endwhile
        closeFile(f)
    endif
endfunction

rem ********************
rem * enregistrement du score de la partie qui vient de se terminer
rem ********************
function _scores_save(pseudo$,niveau,score)
    if (gamecenter_onoff = true) and (getGameCenterLoggedIn())
        gameCenterSubmitScore(score,"bidioo"+str(mode_de_jeu))
    endif
    if (pseudo$ <> "") and (niveau > 0)
        f = openToWrite("scores.dat",1)
        writeLine(f,left(pseudo$,20)+"|"+str(niveau)+"|"+str(score)+"|N")
        closeFile(f)
    endif
endfunction

rem ********************
rem * positionnement des textes et paramétrage standard de ceux-ci
rem ********************
function positionner_texte(id,y)
    // mode plein écran
    x = getVirtualWidth()/2
    l = getVirtualWidth()
    if (sprFenetre > 0)
        if (getSpriteVisible(sprFenetre) = true)
            // mode fenêtre
            x = (fenText_x1+fenText_x2)/2
            l = fenText_x2-fenText_x1
        endif
    endif
    setTextPosition(id,x,y)
    setTextAlignment(id,1)
    setTextSize(id,20)
    setTextMaxWidth(id,l)
    setTextColor(id,0,0,0,255)
endfunction

function bonus_ajouter_vies(nb)
    inc nb_vies,nb
    if (nb_vies < 1)
        nb_vies = 0
    endif
    setTextString(txtJeu[jeuViesID],str(nb_vies))
endfunction

function bonus_retirer_vies(nb)
    dec nb_vies,nb
    if (nb_vies < 1)
        nb_vies = 0
    endif
    setTextString(txtJeu[jeuViesID],str(nb_vies))
endfunction

function bonus_ajouter_bombes(nb)
    inc nb_bombes,nb
    if (nb_bombes < 1)
        nb_bombes = 0
    endif
    setTextString(txtJeu[jeuBombesID],str(nb_bombes))
    _param_save()
    if (aide_onoff = true) and (nb_bombes = 1) then fenetre_texte("Vous gagnez une bombe.",imgBombes,"Les bombes détruisent des cases au hasard. C'est bien pratique pour débloquer une partie difficile.",true,false,false,false)
endfunction

function bonus_retirer_bombes(nb)
    dec nb_bombes,nb
    if (nb_bombes < 1)
        nb_bombes = 0
    endif
    setTextString(txtJeu[jeuBombesID],str(nb_bombes))
    _param_save()
endfunction

function bonus_ajouter_melanges(nb)
    inc nb_melanges,nb
    if (nb_melanges < 1)
        nb_melanges = 0
    endif
    setTextString(txtJeu[jeuMelangesID],str(nb_melanges))
    _param_save()
    if (aide_onoff = true) and (nb_melanges = 1) then fenetre_texte("Vous gagnez un ventilo.",imgMelanges,"Les ventilos mélangent les cases du jeu. Ils peuvent donner un coup de frais à votre partie.",true,false,false,false)
endfunction

function bonus_retirer_melanges(nb)
    dec nb_melanges,nb
    if (nb_melanges < 1)
        nb_melanges = 0
    endif
    setTextString(txtJeu[jeuMelangesID],str(nb_melanges))
    _param_save()
endfunction

function bonus_ajouter_swap(nb)
    inc nb_swap,nb
    if (nb_swap < 1)
        nb_swap = 0
    endif
    setTextString(txtJeu[jeuSwapID],str(nb_swap))
    _param_save()
    if (aide_onoff = true) and (nb_swap = 1) then fenetre_texte("Vous gagnez un rouleau.",imgSwap,"Les rouleaux repeignent la grille. Ils vous donnent une chance de relancer le jeu.",true,false,false,false)
endfunction

function bonus_retirer_swap(nb)
    dec nb_swap,nb
    if (nb_swap < 1)
        nb_swap = 0
    endif
    setTextString(txtJeu[jeuSwapID],str(nb_swap))
    _param_save()
endfunction

function bonus_ajouter_suppr(nb)
    inc nb_suppr,nb
    if (nb_suppr < 1)
        nb_suppr = 0
    endif
    setTextString(txtJeu[jeuSupprID],str(nb_suppr))
    _param_save()
    if (aide_onoff = true) and (nb_suppr = 1) then fenetre_texte("Vous gagnez une poubelle.",imgSuppr,"Vous êtes coincé ? Un motif pollue votre jeu ? Supprimez toutes le motif le plus utilisé grâce à la poubelle.",true,false,false,false)
endfunction

function bonus_retirer_suppr(nb)
    dec nb_suppr,nb
    if (nb_suppr < 1)
        nb_suppr = 0
    endif
    setTextString(txtJeu[jeuSupprID],str(nb_suppr))
    _param_save()
endfunction

function bonus_ajouter_score_mult(nb)
    inc score_mult,nb
    if (score_mult < 1)
        score_mult = 1
    endif
    setTextString(txtJeu[jeuScoreMultID],str(score_mult)+":"+str(niveau_de_jeu))
endfunction

function bonus_retirer_score_mult(nb)
    dec score_mult,nb
    if (score_mult < 1)
        score_mult = 1
    endif
    setTextString(txtJeu[jeuScoreMultID],str(score_mult)+":"+str(niveau_de_jeu))
endfunction

function bonus_ajouter_score(nb)
    inc score,nb
    if (score < 1)
        score = 0
    endif
    // setTextString(txtJeu[jeuScoreID],str(score))
endfunction

function bonus_retirer_score(nb)
    dec score,nb
    if (score < 1)
        score = 0
    endif
    // setTextString(txtJeu[jeuScoreID],str(score))
endfunction

function bonus_ajouter_bouees(nb)
    inc nb_bouees,nb
    if (nb_bouees < 1)
        nb_bouees = 0
    endif
    setTextString(txtJeu[jeuBoueesID],str(nb_bouees))
    _param_save()
    if (aide_onoff = true) and (nb_bouees = 1) then fenetre_texte("Vous gagnez une bouée.",imgBouee,"Les bouées vous montrent le chemin à suivre... et lorsqu'il n'y en a plus, elles en créent un de façon à ne jamais vous bloquer !",true,false,false,false)
endfunction

function bonus_retirer_bouees(nb)
    dec nb_bouees,nb
    if (nb_bouees < 1)
        nb_bouees = 0
    endif
    setTextString(txtJeu[jeuBoueesID],str(nb_bouees))
    _param_save()
endfunction

function bonus_ajouter_niveau_de_jeu(nb)
    inc niveau_de_jeu,nb
    if (niveau_de_jeu < 1)
        niveau_de_jeu = 1
    endif
    bonus_ajouter_vies(1)
    bonus_ajouter_score_mult(1-score_mult)
    nb_couleurs = niveau_de_jeu + nb_couleurs_min
    if (nb_couleurs > nb_couleurs_max)
        nb_couleurs = nb_couleurs_max
    elseif (nb_couleurs > (grille_largeur*grille_hauteur)/5)
        nb_couleurs = (grille_largeur*grille_hauteur)/5
    endif
    fenetre_texte("Niveau "+str(niveau_de_jeu),0,"Vous venez de franchir un nouveau palier. Félicitations.",true,false,false,false)
    select niveau_de_jeu
        case 2:
            if (reussite_n1[mode_de_jeu-1] = false) then fenetre_texte("Niveau "+str(niveau_de_jeu),getImgBadge(5*(mode_de_jeu-1)),"Vous finissez le niveau 1 pour la première fois, ça mérite bien une récompense !",true,false,false,false)
            if (gamecenter_onoff = true) then gameCenterSubmitAchievement("m"+str(mode_de_jeu)+"n1",100)
            reussite_n1[mode_de_jeu-1] = true
            _param_save()
        endcase
        case 4:
            if (reussite_n3[mode_de_jeu-1] = false) then fenetre_texte("Niveau "+str(niveau_de_jeu),getImgBadge(1+5*(mode_de_jeu-1)),"Vous finissez le niveau 3 pour la première fois. Bravo, continuez !",true,false,false,false)
            if (gamecenter_onoff = true) then gameCenterSubmitAchievement("m"+str(mode_de_jeu)+"n3",100)
            reussite_n3[mode_de_jeu-1] = true
            _param_save()
        endcase
        case 6:
            if (reussite_n5[mode_de_jeu-1] = false) then fenetre_texte("Niveau "+str(niveau_de_jeu),getImgBadge(2+5*(mode_de_jeu-1)),"Vous finissez le niveau 5 pour la première fois... et croyez moi, d'autres ont abandonné avant ! Bravo.",true,false,false,false)
            if (gamecenter_onoff = true) then gameCenterSubmitAchievement("m"+str(mode_de_jeu)+"n5",100)
            reussite_n5[mode_de_jeu-1] = true
            _param_save()
        endcase
        case 9:
            if (reussite_n8[mode_de_jeu-1] = false) then fenetre_texte("Niveau "+str(niveau_de_jeu),getImgBadge(3+5*(mode_de_jeu-1)),"Bravo pour votre persévérance. Vous venez de finir le niveau 8. Le prochain badge sera au niveau 16. Bon courage ;-)",true,false,false,false)
            if (gamecenter_onoff = true) then gameCenterSubmitAchievement("m"+str(mode_de_jeu)+"n8",100)
            reussite_n8[mode_de_jeu-1] = true
            _param_save()
        endcase
        case 16:
            if (reussite_n8[mode_de_jeu-1] = false) then fenetre_texte("Niveau "+str(niveau_de_jeu),getImgBadge(4+5*(mode_de_jeu-1)),"Vous avez passé le niveau 15. Vous êtes parmi les meilleurs joueur mondiaux ! Encore bravo.",true,false,false,false)
            if (gamecenter_onoff = true) then gameCenterSubmitAchievement("m"+str(mode_de_jeu)+"n15",100)
            reussite_n15[mode_de_jeu-1] = true
            _param_save()
        endcase
    endselect
endfunction

function bonus_retirer_niveau_de_jeu(nb)
    dec niveau_de_jeu,nb
    if (niveau_de_jeu < 1)
        niveau_de_jeu = 1
    endif
endfunction

rem ********************
rem * chargement des paramètres de l'application
rem ********************
function _param_load()
    music_onoff = true
    son_onoff = true
    nb_bombes = 0
    nb_melanges = 0
    nb_swap = 0
    nb_suppr = 0
    nb_bouees = 0
    theme_choisi$ = "kolopach"
    nb_couleurs_max = 9
    mode_de_jeu = 2
    pseudo$ = ""
    for i = 0 to 2
        reussite_n1[i] = false
        reussite_n3[i] = false
        reussite_n5[i] = false
        reussite_n8[i] = false
        reussite_n15[i] = false
    next i
    aide_onoff = true
    nb_lancements = 0
    if (1 = getFileExists("nblanc.dat"))
        //log$ = log$ + "settings.dat present"+chr(10)
        f = openToRead("nblanc.dat")
        nb_lancements = val(readLine(f))
        closeFile(f)
    endif
    f = openToWrite("nblanc.dat",0)
    writeLine(f,str(nb_lancements+1))
    closeFile(f)

    //log$=""
    if (1 = getFileExists("settings.dat"))
        //log$ = log$ + "settings.dat present"+chr(10)
        f = openToRead("settings.dat")
        while (0 = fileEOF(f))
            ch$ = readLine(f)
            //log$ = log$ + ch$ + chr(10)
            //log$ = log$ + "count : " + str(countStringTokens(ch$,"=")) + chr(10)
            if (2 = countStringTokens(ch$,"="))
                key$ = getStringToken(ch$,"=",1)
                //log$ = log$ + "cle = " + key$ + chr(10)
                value$ = getStringToken(ch$,"=",2)
                //log$ = log$ + "valeur = " + value$ + chr(10)
                if (key$ = "music_onoff")
                    music_onoff = val(value$)
                    if (music_onoff <> false) then music_onoff = true
                elseif (key$ = "son_onoff")
                    son_onoff = val(value$)
                    if (son_onoff <> false) then son_onoff = true
                elseif (key$ = "aide_onoff")
                    aide_onoff = val(value$)
                    if (aide_onoff <> false) then aide_onoff = true
                elseif (key$ = "nb_bombes")
                    nb_bombes = val(value$)
                    setTextString(txtJeu[jeuBombesID],str(nb_bombes))
                elseif (key$ = "nb_melanges")
                    nb_melanges = val(value$)
                    setTextString(txtJeu[jeuMelangesID],str(nb_melanges))
                elseif (key$ = "nb_swap")
                    nb_swap = val(value$)
                    setTextString(txtJeu[jeuSwapID],str(nb_swap))
                elseif (key$ = "nb_suppr")
                    nb_suppr = val(value$)
                    setTextString(txtJeu[jeuSupprID],str(nb_suppr))
                elseif (key$ = "nb_bouees")
                    nb_bouees = val(value$)
                    setTextString(txtJeu[jeuBoueesID],str(nb_bouees))
                elseif (key$ = "theme_choisi")
                    theme_choisi$ = value$
                    if (theme_choisi$ = "") then theme_choisi$ = "kolopach"
                elseif (key$ = "theme_nb_motifs")
                    nb_couleurs_max = val(value$)
                    if (nb_couleurs_max < 0) then nb_couleurs_max = 0
                elseif (key$ = "mode_de_jeu")
                    mode_de_jeu = val(value$)
                    if (mode_de_jeu < 1) then mode_de_jeu = 1
                    if (mode_de_jeu > 3) then mode_de_jeu = 3
                elseif (key$ = "pseudo")
                    pseudo$ = value$
                else
                    for i = 0 to 2
                        if (key$ = "badge_m"+str(i+1)+"n1")
                            reussite_n1[i] = val(value$)
                            if (reussite_n1[i] <> false) then reussite_n1[i] = true
                        elseif (key$ = "badge_m"+str(i+1)+"n3")
                            reussite_n3[i] = val(value$)
                            if (reussite_n3[i] <> false) then reussite_n3[i] = true
                        elseif (key$ = "badge_m"+str(i+1)+"n5")
                            reussite_n5[i] = val(value$)
                            if (reussite_n5[i] <> false) then reussite_n5[i] = true
                        elseif (key$ = "badge_m"+str(i+1)+"n8")
                            reussite_n8[i] = val(value$)
                            if (reussite_n8[i] <> false) then reussite_n8[i] = true
                        elseif (key$ = "badge_m"+str(i+1)+"n15")
                            reussite_n15[i] = val(value$)
                            if (reussite_n15[i] <> false) then reussite_n15[i] = true
                        endif
                    next i
                endif
            endif
        endwhile
        closeFile(f)
    //else
        //log$ = log$ + "settings.dat absent"+chr(10)
    endif
    //repeat
        //print(log$)
        //sync()
    //until (1 = getPointerPressed())
endfunction

rem ********************
rem * sauvegarde des paramètres de l'application
rem ********************
function _param_save()
    f = openToWrite("settings.dat",0)
    writeLine(f,"music_onoff="+str(music_onoff))
    writeLine(f,"son_onoff="+str(son_onoff))
    writeLine(f,"aide_onoff="+str(aide_onoff))
    writeLine(f,"nb_bombes="+str(nb_bombes))
    writeLine(f,"nb_melanges="+str(nb_melanges))
    writeLine(f,"nb_swap="+str(nb_swap))
    writeLine(f,"nb_suppr="+str(nb_suppr))
    writeLine(f,"nb_bouees="+str(nb_bouees))
    writeLine(f,"theme_choisi="+theme_choisi$)
    writeLine(f,"theme_nb_motifs="+str(nb_couleurs_max))
    writeLine(f,"mode_de_jeu="+str(mode_de_jeu))
    writeLine(f,"pseudo="+pseudo$)
    for i = 0 to 2
        writeLine(f,"badge_m"+str(i+1)+"n1="+str(reussite_n1[i]))
        writeLine(f,"badge_m"+str(i+1)+"n3="+str(reussite_n3[i]))
        writeLine(f,"badge_m"+str(i+1)+"n5="+str(reussite_n5[i]))
        writeLine(f,"badge_m"+str(i+1)+"n8="+str(reussite_n8[i]))
        writeLine(f,"badge_m"+str(i+1)+"n15="+str(reussite_n15[i]))
    next i
    closeFile(f)
endfunction

function _load_jeu_solo()
    if (1 = getFileExists("game.dat"))
        mj = -1
        gl = 0
        gh = 0
        th$ = ""
        sc = 0
        nj = 0
        sm = 0
        nv = 0
        dim gr[30*30] as integer
        for i = 0 to 30*30-1
            gr[i] = 0
        next i
        f = openToRead("game.dat")
        while (0 = fileEOF(f))
            ch$ = readLine(f)
            if (2 = countStringTokens(ch$,"="))
                key$ = getStringToken(ch$,"=",1)
                value$ = getStringToken(ch$,"=",2)
                if (key$ = "mj")
                    mj = val(value$)
                elseif (key$ = "gl")
                    gl = val(value$)
                elseif (key$ = "gh")
                    gh = val(value$)
                elseif (key$ = "th")
                    th$ = value$
                elseif (key$ = "sc")
                    sc = val(value$)
                elseif (key$ = "nj")
                    nj = val(value$)
                elseif (key$ = "sm")
                    sm = val(value$)
                elseif (key$ = "nv")
                    nv = val(value$)
                elseif (key$ = "gr")
                    nb = countStringTokens(value$,",")
                    for i = 0 to nb-1
                        gr[i] = val(getStringToken(value$,",",i+1))
                    next i
                endif
            endif
        endwhile
        closeFile(f)
        if (mode_de_jeu = mj) and (grille_largeur = gl) and (grille_hauteur = gh) and (theme_choisi$ = th$)
            bonus_ajouter_score(sc-score)
            score_temp = score
            setTextString(txtJeu[jeuScoreID],str(score_temp))
            niveau_de_jeu = nj
            bonus_ajouter_score_mult(sm-score_mult)
            bonus_ajouter_vies(nv-nb_vies)
            for i = 0 to grille_largeur*grille_hauteur-1
                grille[i].couleur = gr[i]
                setSpriteImage(grille[i].sprite,couleurs[grille[i].couleur])
                setSpriteVisible(grille[i].sprite,true)
                setSpriteActive(grille[i].sprite,true)
                setSpriteColorAlpha(grille[i].sprite,255)
            next i
            // recalcul du nombre de motifs disponibles
            nb_couleurs = niveau_de_jeu + nb_couleurs_min
            if (nb_couleurs > nb_couleurs_max)
                nb_couleurs = nb_couleurs_max
            elseif (nb_couleurs > (grille_largeur*grille_hauteur)/5)
                nb_couleurs = (grille_largeur*grille_hauteur)/5
            endif
        endif
    endif
endfunction

function _save_jeu_solo()
    f = openToWrite("game.dat",0)
    writeLine(f,"mj="+str(mode_de_jeu))
    writeLine(f,"gl="+str(grille_largeur))
    writeLine(f,"gh="+str(grille_hauteur))
    writeLine(f,"th="+theme_choisi$)
    writeLine(f,"sc="+str(score))
    writeLine(f,"nj="+str(niveau_de_jeu))
    writeLine(f,"sm="+str(score_mult))
    writeLine(f,"nv="+str(nb_vies))
    ch$ = ""
    for i = 0 to grille_largeur*grille_hauteur-1
        if (i > 0) then ch$ = ch$ + ","
        ch$ = ch$ + str(grille[i].couleur)
    next i
    writeLine(f,"gr="+ch$)
    closeFile(f)
endfunction

function bonus_action_melange_swap(x,y)
	c as integer = 0
    i1 = grille_indice(x,y)
    i2 = grille_indice(x-1+random(0,2),y-1+random(0,2))
    c = grille[i1].couleur
    grille[i1].couleur = grille[i2].couleur
    setSpriteImage(grille[i1].sprite,couleurs[grille[i1].couleur])
    grille[i2].couleur = c
    setSpriteImage(grille[i2].sprite,couleurs[c])
    sync()
    sleep(50)
endfunction

function bonus_action_melange_go(x,y,g,h,d,b,sx,sy)
    if (g <> d) and (h <> b)
        select sx
            case -1:
                for x = d to g+1 step -1
                    bonus_action_melange_swap(x,y)
                next x
                bonus_action_melange_go(g,y,g,h,d,b-1,0,-1)
            endcase
            case 1:
                for x = g to d-1
                    bonus_action_melange_swap(x,y)
                next x
                bonus_action_melange_go(d,y,g,h+1,d,b,0,1)
            endcase
        endselect
        select sy
            case -1:
                for y = b to h+1 step -1
                    bonus_action_melange_swap(x,y)
                next y
                bonus_action_melange_go(x,h,g+1,h,d,b,1,0)
            endcase
            case 1:
                for y = h to b-1
                    bonus_action_melange_swap(x,y)
                next y
                bonus_action_melange_go(x,b,g,h,d+1,b,-1,0)
            endcase
        endselect
    endif
endfunction

function bonus_action_melange()
    if (son_onoff = true) then playSound(sndBonusMelanges,80,1)
    bonus_action_melange_go(0,0,0,0,grille_largeur-1,grille_hauteur-1,1,0)
    if (son_onoff = true) then stopSound(sndBonusMelanges)
endfunction

function bonus_action_bombe()
    if (son_onoff = true) then playSound(sndBonusBombes,80,0)
    nb = grille_largeur*grille_hauteur / nb_couleurs
    if (nb < 5)
        nb = 5
    endif
    for i = 0 to nb
        case_desactive(random(0,grille_largeur-1),random(0,grille_hauteur-1))
    next i
    sync()
    sleep(500)
endfunction

function bonus_action_suppr()
    if (son_onoff = true) then playSound(sndBonusSuppr,80,0)
    dim c[50] as integer
    for i = 0 to nb_couleurs_max-1
        c[i] = 0
    next i
    for i = 0 to grille_largeur*grille_hauteur-1
        if (grille[i].couleur > -1)
            inc c[grille[i].couleur]
        endif
    next i
    id = 0
    for i = 1 to nb_couleurs_max-1
        if (c[i] > c[id])
            id = i
        endif
    next i
    for i = 0 to grille_largeur*grille_hauteur-1
        if (grille[i].couleur = id)
            case_desactive(grille_indice_x(i),grille_indice_y(i))
        endif
    next i
    sync()
    sleep(500)
endfunction

function bonus_action_swap()
    if (son_onoff = true) then playSound(sndBonusSwap,80,1)
    dim c[50] as integer
    for i = 0 to nb_couleurs_max-1
        c[i] = random(0,nb_couleurs_max-1)
    next i
    for i = 0 to grille_largeur*grille_hauteur-1
        grille[i].couleur = c[grille[i].couleur]
        setSpriteImage(grille[i].sprite,couleurs[grille[i].couleur])
        sync()
        sleep(50)
    next i
    if (son_onoff = true) then stopSound(sndBonusSwap)
endfunction

function bonus_action_bouees_test(x1,y1,x2,y2,x3,y3)
    ok = false
    if (x1 >= 0) and (x2 >= 0) and (x3 >= 0) and (y1 >= 0) and (y2 >= 0) and (y3 >= 0) and (x1 < grille_largeur) and (x2 < grille_largeur) and (x3 < grille_largeur) and (y1 < grille_hauteur) and (y2 < grille_hauteur) and (y3 < grille_hauteur) and (grille[grille_indice(x1,y1)].couleur = grille[grille_indice(x2,y2)].couleur) and (grille[grille_indice(x1,y1)].couleur = grille[grille_indice(x3,y3)].couleur)
        ok = true
    endif
endfunction ok

function bonus_action_bouees()
    if (son_onoff = true) then playSound(sndBonusBouees,80,1)
    // recherche de combinaisons disponibles ne fonction du mode de jeu
    x1 = 0
    y1 = 0
    x2 = 0
    y2 = 0
    x3 = 0
    y3 = 0
    sortie = false
    trouve = false
    phase = 0
    num = 0
    nb = 0
    repeat
        i = 0
        sortie2 = false
        repeat
            select i
                case 0:
                    // deux horizontaux, angle haut droite, tous modes de jeu
                    x2 = x1+1
                    y2 = y1
                    x3 = x1+2
                    y3 = y1-1
                endcase
                case 1:
                    // deux horizontaux, angle bas droite, tous modes de jeu
                    x2 = x1+1
                    y2 = y1
                    x3 = x1+2
                    y3 = y1+1
                endcase
                case 2:
                    // deux horizontaux, angle haut gauche, tous modes de jeu
                    x2 = x1-1
                    y2 = y1
                    x3 = x1-2
                    y3 = y1-1
                endcase
                case 3:
                    // deux horizontaux, angle bas gauche, tous modes de jeu
                    x2 = x1-1
                    y2 = y1
                    x3 = x1-2
                    y3 = y1+1
                endcase
                case 4:
                    // deux verticaux, angle bas gauche, tous modes de jeu
                    x2 = x1
                    y2 = y1+1
                    x3 = x1-1
                    y3 = y1+2
                endcase
                case 5:
                    // deux verticaux, angle bas droite, tous modes de jeu
                    x2 = x1
                    y2 = y1+1
                    x3 = x1+1
                    y3 = y1+2
                endcase
                case 6:
                    // deux verticaux, angle haut gauche, tous modes de jeu
                    x2 = x1
                    y2 = y1-1
                    x3 = x1-1
                    y3 = y1-2
                endcase
                case 7:
                    // deux verticaux, angle haut droite, tous modes de jeu
                    x2 = x1
                    y2 = y1-1
                    x3 = x1+1
                    y3 = y1-2
                endcase
                case 8:
                    // trois motifs en triangle, pointe en haut, tous modes de jeu
                    x2 = x1+1
                    y2 = y1-1
                    x3 = x1+2
                    y3 = y1
                endcase
                case 9:
                    // trois motifs en triangle, pointe en bas, tous modes de jeu
                    x2 = x1+1
                    y2 = y1+1
                    x3 = x1+2
                    y3 = y1
                endcase
                case 10:
                    // trois motifs en triangle, pointe à gauche, tous modes de jeu
                    x2 = x1-1
                    y2 = y1+1
                    x3 = x1
                    y3 = y1+2
                endcase
                case 11:
                    // trois motifs en triangle, pointe à droite, tous modes de jeu
                    x2 = x1+1
                    y2 = y1+1
                    x3 = x1
                    y3 = y1+2
                endcase
                case 12:
                    // deux horizontaux, motif de droite séparé d'une case, mode switch de jeu entre deux cases
                    if ((mode_de_jeu = 1) or (mode_de_jeu = 2))
                        x2 = x1+1
                        y2 = y1
                        x3 = x1+3
                        y3 = y1
                    else
                        x2 = -1
                    endif
                endcase
                case 13:
                    // deux horizontaux, motif de gauche séparé d'une case, mode switch de jeu entre deux cases
                    if ((mode_de_jeu = 1) or (mode_de_jeu = 2))
                        x2 = x1-1
                        y2 = y1
                        x3 = x1-3
                        y3 = y1
                    else
                        x2 = -1
                    endif
                endcase
                case 14:
                    // deux verticaux, motif du haut séparé d'une case, mode switch de jeu entre deux cases
                    if ((mode_de_jeu = 1) or (mode_de_jeu = 2))
                        x2 = x1
                        y2 = y1-1
                        x3 = x1
                        y3 = y1-3
                    else
                        x2 = -1
                    endif
                endcase
                case 15:
                    // deux verticaux, motif du bas séparé d'une case, mode switch de jeu entre deux cases
                    if ((mode_de_jeu = 1) or (mode_de_jeu = 2))
                        x2 = x1
                        y2 = y1+1
                        x3 = x1
                        y3 = y1+3
                    else
                        x2 = -1
                    endif
                endcase
                case 16:
                    // mode de jeu ligne, deux verticaux en haut, complément en bas
                    if ((mode_de_jeu = 2) or (mode_de_jeu = 3)) and (y1 = 0)
                        x2 = x1
                        y2 = y1+1
                        x3 = x1
                        y3 = grille_hauteur-1
                    else
                        x2 = -1
                    endif
                endcase
                case 17:
                    // mode de jeu ligne, deux verticaux en bas, complément en haut
                    if ((mode_de_jeu = 2) or (mode_de_jeu = 3)) and (y1 = 0)
                        x2 = x1
                        y2 = grille_hauteur-2
                        x3 = x1
                        y3 = grille_hauteur-1
                    else
                        x2 = -1
                    endif
                endcase
                case 18:
                    // mode de jeu ligne, deux horizontaux à gauche, complément à droite
                    if ((mode_de_jeu = 2) or (mode_de_jeu = 3)) and (x1 = 0)
                        x2 = x1+1
                        y2 = y1
                        x3 = grille_largeur-1
                        y3 = y1
                    else
                        x2 = -1
                    endif
                endcase
                case 19:
                    // mode de jeu ligne, deux horizontaux à droite, complément à gauche
                    if ((mode_de_jeu = 2) or (mode_de_jeu = 3)) and (x1 = 0)
                        x2 = grille_largeur-2
                        y2 = y1
                        x3 = grille_largeur-1
                        y3 = y1
                    else
                        x2 = -1
                    endif
                endcase
                case 20:
                    // mode de jeu ligne, deux horizontaux en haut, complément en bas à gauche
                    if ((mode_de_jeu = 2) or (mode_de_jeu = 3)) and (y1 = 0)
                        x2 = x1+1
                        y2 = y1
                        x3 = x1-1
                        y3 = grille_hauteur-1
                    else
                        x2 = -1
                    endif
                endcase
                case 21:
                    // mode de jeu ligne, deux horizontaux en haut, complément en bas à droite
                    if ((mode_de_jeu = 2) or (mode_de_jeu = 3)) and (y1 = 0)
                        x2 = x1+1
                        y2 = y1
                        x3 = x1+2
                        y3 = grille_hauteur-1
                    else
                        x2 = -1
                    endif
                endcase
                case 22:
                    // mode de jeu ligne, deux horizontaux en bas, complément en haut à gauche
                    if ((mode_de_jeu = 2) or (mode_de_jeu = 3)) and (y1 = 0)
                        x2 = x1+1
                        y2 = grille_hauteur-1
                        x3 = x1+2
                        y3 = grille_hauteur-1
                    else
                        x2 = -1
                    endif
                endcase
                case 23:
                    // mode de jeu ligne, deux horizontaux en bas, complément en haut à droite
                    if ((mode_de_jeu = 2) or (mode_de_jeu = 3)) and (y1 = 0)
                        x2 = x1-1
                        y2 = grille_hauteur-1
                        x3 = x1-2
                        y3 = grille_hauteur-1
                    else
                        x2 = -1
                    endif
                endcase
                case 24:
                    // mode de jeu ligne, deux verticaux à gauche, complément en haut à droite
                    if ((mode_de_jeu = 2) or (mode_de_jeu = 3)) and (x1 = 0)
                        x2 = x1
                        y2 = y1+1
                        x3 = grille_largeur-1
                        y3 = y1-1
                    else
                        x2 = -1
                    endif
                endcase
                case 25:
                    // mode de jeu ligne, deux verticaux à gauche, complément en bas à droite
                    if ((mode_de_jeu = 2) or (mode_de_jeu = 3)) and (x1 = 0)
                        x2 = x1
                        y2 = y1+1
                        x3 = grille_largeur-1
                        y3 = y1+2
                    else
                        x2 = -1
                    endif
                endcase
                case 26:
                    // mode de jeu ligne, deux verticaux à droite, complément en haut à gauche
                    if ((mode_de_jeu = 2) or (mode_de_jeu = 3)) and (x1 = grille_largeur-1)
                        x2 = x1
                        y2 = y1+1
                        x3 = 0
                        y3 = y1-1
                    else
                        x2 = -1
                    endif
                endcase
                case 27:
                    // mode de jeu ligne, deux verticaux à droite, complément en bas à gauche
                    if ((mode_de_jeu = 2) or (mode_de_jeu = 3)) and (x1 = grille_largeur-1)
                        x2 = x1
                        y2 = y1+1
                        x3 = 0
                        y3 = y1+2
                    else
                        x2 = -1
                    endif
                endcase
                case 28:
                    // mode de jeu ligne, deux verticaux à gauche, complément au milieu à droite
                    if ((mode_de_jeu = 2) or (mode_de_jeu = 3)) and (x1 = 0)
                        x2 = grille_largeur-1
                        y2 = y1+1
                        x3 = x1
                        y3 = y1+2
                    else
                        x2 = -1
                    endif
                endcase
                case 29:
                    // mode de jeu ligne, deux verticaux à droite, complément au milieu à gauche
                    if ((mode_de_jeu = 2) or (mode_de_jeu = 3)) and (x1 = grille_largeur-1)
                        x2 = 0
                        y2 = y1+1
                        x3 = x1
                        y3 = y1+2
                    else
                        x2 = -1
                    endif
                endcase
                case 30:
                    // mode de jeu ligne, deux horizontaux en haut, complément en bas au milieu
                    if ((mode_de_jeu = 2) or (mode_de_jeu = 3)) and (y1 = 0)
                        x2 = x1+1
                        y2 = y1
                        x3 = x1+2
                        y3 = grille_hauteur-1
                    else
                        x2 = -1
                    endif
                endcase
                case 31:
                    // mode de jeu ligne, deux horizontaux en bas, complément en haut au milieu
                    if ((mode_de_jeu = 2) or (mode_de_jeu = 3)) and (y1 = grille_hauteur-1)
                        x2 = x1+1
                        y2 = 0
                        x3 = x1+2
                        y3 = y1
                    else
                        x2 = -1
                    endif
                endcase
                case default :
                    sortie2 = true
                endcase
            endselect
            if (sortie2 = false)
                trouve = bonus_action_bouees_test(x1,y1,x2,y2,x3,y3)
                sortie2 = trouve
            endif
            inc i
        until (sortie2 = true)
        // sortie de boucle ou progression en fonction du cas
        if (trouve = true)
            select phase
                case 0:
                    // comptage des combinaisons possibles pour choix de l'un d'entre elles au hasard
                    inc nb
                endcase
                case 1:
                    // si c'est la bonne combinaison, on sort et on l'affiche
                    inc nb
                    if (nb >= num)
                        sortie = true
                    endif
                endcase
                case default:
                    // cas impossible, mais sait on jamais...
                    sortie = true
                endcase
            endselect
        endif
        if (sortie = false)
            inc x1
            if (x1 > grille_largeur-1)
                x1 = 0
                inc y1
                if (y1 > grille_hauteur-1)
                    if (phase = 0)
                        x1 = 0
                        y1 = 0
                        num = random(1,nb)
                        nb = 0
                        phase = 1
                    else
                        sortie = true
                    endif
                endif
            endif
        endif
    until (sortie = true)
    if (trouve = true)
        bonus_action_bouees_anime(true)
    else
        // aucune combinaison n'est disponible, on déclenche un bonus parmi les autres
        select random(0,3)
            case 0:
                bonus_action_melange()
            endcase
            case 1:
                bonus_action_bombe()
            endcase
            case 2:
                bonus_action_swap()
            endcase
            case 3:
                bonus_action_suppr()
            endcase
        endselect
        // on remplit la grille au cas où des pièces en auraient été retirées (ce qui est un peu le but des bonus précédents)
        grille_remplissage(true)
        // on recherche une combinaison puisque c'était la demande du joueur :-)
        bonus_action_bouees()
    endif
endfunction

function bonus_action_bouees_anime(go)
    if (go = animation_bouee_onoff)
        if (go = true)
            alpha = getSpriteColorAlpha(grille[grille_indice(x1,y1)].sprite)+animation_bouee_sens
            if (alpha > 255)
                animation_bouee_sens = -3
                alpha = 255
            elseif (alpha < 0)
                animation_bouee_sens = 3
                alpha = 0
            endif
            setSpriteColorAlpha(grille[grille_indice(x1,y1)].sprite,alpha)
            setSpriteColorAlpha(grille[grille_indice(x2,y2)].sprite,alpha)
            setSpriteColorAlpha(grille[grille_indice(x3,y3)].sprite,alpha)
        endif
    else
        if (go = true)
            // lancement de l'animation
            animation_bouee_sens = 3
            animation_bouee_onoff = true
            setSpriteColorAlpha(grille[grille_indice(x1,y1)].sprite,128)
            setSpriteColorAlpha(grille[grille_indice(x2,y2)].sprite,128)
            setSpriteColorAlpha(grille[grille_indice(x3,y3)].sprite,128)
        else
            // arrêt de l'animation
            animation_bouee_onoff = false
            setSpriteColorAlpha(grille[grille_indice(x1,y1)].sprite,255)
            setSpriteColorAlpha(grille[grille_indice(x2,y2)].sprite,255)
            setSpriteColorAlpha(grille[grille_indice(x3,y3)].sprite,255)
            if (son_onoff = true) then stopSound(sndBonusBouees)
        endif
    endif
endfunction

function lancer_musique(onoff)
    if (onoff = true) and (sonMusique <> 0)
        playMusic(sonMusique,true)
        setMusicSystemVolume(70)
    else
        stopMusic()
    endif
endfunction

function getImgBadge(num)
    if (imgBadge[num] = 0)
        niv = mod(num, 5)
        mj = num / 5
        select niv
            case 0:
                if (mj = 0) then imgBadge[num] = loadImage("classic1-100x100.png")
                if (mj = 1) then imgBadge[num] = loadImage("mixte1-100x100.png")
                if (mj = 2) then imgBadge[num] = loadImage("master1-100x100.png")
            endcase
            case 1:
                if (mj = 0) then imgBadge[num] = loadImage("classic3-100x100.png")
                if (mj = 1) then imgBadge[num] = loadImage("mixte3-100x100.png")
                if (mj = 2) then imgBadge[num] = loadImage("master3-100x100.png")
            endcase
            case 2:
                if (mj = 0) then imgBadge[num] = loadImage("classic5-100x100.png")
                if (mj = 1) then imgBadge[num] = loadImage("mixte5-100x100.png")
                if (mj = 2) then imgBadge[num] = loadImage("master5-100x100.png")
            endcase
            case 3:
                if (mj = 0) then imgBadge[num] = loadImage("classic8-100x100.png")
                if (mj = 1) then imgBadge[num] = loadImage("mixte8-100x100.png")
                if (mj = 2) then imgBadge[num] = loadImage("master8-100x100.png")
            endcase
            case 4:
                if (mj = 0) then imgBadge[num] = loadImage("classic15-100x100.png")
                if (mj = 1) then imgBadge[num] = loadImage("mixte15-100x100.png")
                if (mj = 2) then imgBadge[num] = loadImage("master15-100x100.png")
            endcase
        endselect
    endif
    idImage = imgBadge[num]
endfunction idImage

function fenetre_badges()
    fenetre_ouvrir(true,false,false,false)
    dim sprBadge[5*3] as integer
    for i = 0 to 5*3-1
        sprBadge[i] = 0
    next i
    for i = 0 to 2
		num = i*5
		sprBadge[num] = createSprite(getImgBadge(num))
		if (reussite_n1[i])
			SetSpriteColorAlpha(sprBadge[num],255)
		else
			SetSpriteColorAlpha(sprBadge[num],64)
		endif
		num = i*5+1
		sprBadge[num] = createSprite(getImgBadge(num))
		if (reussite_n3[i])
			SetSpriteColorAlpha(sprBadge[num],255)
		else
			SetSpriteColorAlpha(sprBadge[num],64)
		endif
		num = i*5+2
		sprBadge[num] = createSprite(getImgBadge(num))
		if (reussite_n5[i])
			SetSpriteColorAlpha(sprBadge[num],255)
		else
			SetSpriteColorAlpha(sprBadge[num],64)
		endif
		num = i*5+3
		sprBadge[num] = createSprite(getImgBadge(num))
		if (reussite_n8[i])
			SetSpriteColorAlpha(sprBadge[num],255)
		else
			SetSpriteColorAlpha(sprBadge[num],64)
		endif
		num = i*5+4
		sprBadge[num] = createSprite(getImgBadge(num))
		if (reussite_n15[i])
			SetSpriteColorAlpha(sprBadge[num],255)
		else
			SetSpriteColorAlpha(sprBadge[num],64)
		endif
remstart
        if (reussite_n1[i])
            num = i*5
            sprBadge[num] = createSprite(getImgBadge(num))
        endif
        if (reussite_n3[i])
            num = i*5+1
            sprBadge[num] = createSprite(getImgBadge(num))
        endif
        if (reussite_n5[i])
            num = i*5+2
            sprBadge[num] = createSprite(getImgBadge(num))
        endif
        if (reussite_n8[i])
            num = i*5+3
            sprBadge[num] = createSprite(getImgBadge(num))
        endif
        if (reussite_n15[i])
            num = i*5+4
            sprBadge[num] = createSprite(getImgBadge(num))
        endif
remend
    next i
    x = 0
    y = 0
    for i = 0 to 5*3-1
        if (sprBadge[i] <> 0)
            setSpriteSize(sprBadge[i],getSpriteWidth(sprBadge[i])*fenetreRatio#*0.8,getSpriteHeight(sprBadge[i])*fenetreRatio#*0.8)
            setSpritePosition(sprBadge[i],fenText_x1+x,fenText_y1+y)
            x = x + getSpriteWidth(sprBadge[i])+5
            if (x > fenText_x2 - fenText_x1 - getSpriteWidth(sprBadge[i]))
                x = 0
                y = y + getSpriteHeight(sprBadge[i])+5
            endif
            setSpriteActive(sprBadge[i],false)
            setSpriteVisible(sprBadge[i],true)
        endif
    next i
    sortie = false
    repeat
        sync()
        if (getPointerPressed() = 1)
            if (1 = getSpriteHitTest(sprOk,screenToWorldX(getPointerX()),screenToWorldY(getPointerY())))
                if (son_onoff = true) then playSound(sndClic,80,0)
                sortie = true
            endif
        endif
    until (sortie = true)
    for i = 0 to 5*3-1
        if (sprBadge[i] <> 0)
            deleteSprite(sprBadge[i])
        endif
    next i
    fenetre_fermer()
endfunction

function enregistrement_du_score()
    if (son_onoff = true) then playSound(sndFinDePartie,80,0)
    fenetre_ouvrir(true,true,false,false)
    espacement = 10
    nombre_de_lignes = 0
    inc nombre_de_lignes
    if (score > 1)
        textes[nombre_de_lignes] = createText("Votre score : "+chr(10)+str(score)+" points")
    elseif (score = 1)
        textes[nombre_de_lignes] = createText("Seulement 1 point ???")
    else
        textes[nombre_de_lignes] = createText("Votre score est nul !!!")
    endif
    positionner_texte(textes[nombre_de_lignes],espacement+fenText_y1)
    inc nombre_de_lignes
    textes[nombre_de_lignes] = createText("Mettez votre nom :")
    positionner_texte(textes[nombre_de_lignes],2*espacement+getTextY(textes[nombre_de_lignes-1])+getTextTotalHeight(textes[nombre_de_lignes-1]))
    chxPseudo = createEditBox()
    setEditBoxTextSize(chxPseudo,20)
    setEditBoxMaxChars(chxPseudo,20)
    setEditBoxSize(chxPseudo,fenText_x2-fenText_x1,20)
    setEditBoxPosition(chxPseudo,fenText_x1+(fenText_x2-fenText_x1-getEditBoxWidth(chxPseudo))/2,espacement+getTextY(textes[nombre_de_lignes])+getTextTotalHeight(textes[nombre_de_lignes]))
    setEditBoxText(chxPseudo,pseudo$)
    sortie = false
    repeat
        sync()
        if (getPointerPressed() = 1)
            if (1 = getSpriteHitTest(sprCancel,screenToWorldX(getPointerX()),screenToWorldY(getPointerY())))
                if (son_onoff = true) then playSound(sndClic,80,0)
                setEditBoxText(chxPseudo,"")
                sortie = true
            elseif (1 = getSpriteHitTest(sprOk,screenToWorldX(getPointerX()),screenToWorldY(getPointerY()))) and (getEditBoxText(chxPseudo) <> "")
                if (son_onoff = true) then playSound(sndClic,80,0)
                sortie = true
            endif
        endif
    until (sortie = true)
    psd$ = getEditBoxText(chxPseudo)
    if (psd$ <> "")
        pseudo$ = psd$
        _scores_save(pseudo$,niveau_de_jeu,score)
        _param_save()
    endif
    deleteEditBox(chxPseudo)
    for i = 1 to nombre_de_lignes
        deleteText(textes[i])
    next i
    fenetre_fermer()
endfunction

function iap_acheter(idSpr,idIap,nb,nom_bonus$,fin_de_partie)
    enplus = 0
    if (iap_onoff = true)
        // achats inApp possibles, on active le bouton cliqué
        setSpriteColoralpha(idSpr,128)
        // afficher la fenêtre de blabla, attendre la confirmation de la volonté d'acheter puis lancer IAP ou sortir en retournant 0
        fenetre_ouvrir(true,true,false,false)
        espacement = 10
        nombre_de_lignes = 0
        inc nombre_de_lignes
        textes[nombre_de_lignes] = createText("Vous n'avez plus de "+nom_bonus$+".")
        positionner_texte(textes[nombre_de_lignes],espacement+fenText_y1)
        sprBonus = cloneSprite(idspr)
        setSpritePosition(sprBonus,fenText_x1+(fenText_x2-fenText_x1-getSpriteWidth(sprBonus))/2,espacement+getTextY(textes[nombre_de_lignes])+getTextTotalHeight(textes[nombre_de_lignes]))
        setSpriteActive(sprBonus,false)
        setSpriteVisible(sprBonus,true)
        setSpriteColorAlpha(sprBonus,255)
        inc nombre_de_lignes
        if (fin_de_partie = false)
            textes[nombre_de_lignes] = createText("Validez pour en acheter "+str(nb)+".")
        else
            textes[nombre_de_lignes] = createText("Achetez 10 coeurs ou la partie s'arrête maintenant.")
        endif
        positionner_texte(textes[nombre_de_lignes],espacement+getSpriteY(sprBonus)+getSpriteHeight(sprBonus))
        sortie = false
        repeat
            sync()
            if (getPointerPressed() = 1)
                if (1 = getSpriteHitTest(sprCancel,screenToWorldX(getPointerX()),screenToWorldY(getPointerY())))
                    if (son_onoff = true) then playSound(sndClic,80,0)
                    sortie = true
                elseif (1 = getSpriteHitTest(sprOk,screenToWorldX(getPointerX()),screenToWorldY(getPointerY())))
                    if (son_onoff = true) then playSound(sndClic,80,0)
                    sortie = true
                    setSpriteColorAlpha(sprOk,128)
                    // Procédure d'achat inApp
                    inAppPurchaseActivate(idIap)
                    while (getInAppPurchaseState() = 0)
                        sync()
                    endwhile
                    if (getInAppPurchaseAvailable(idIap) = 1)
                        enplus = nb
                    endif
                    setSpriteColorAlpha(sprOk,255)
                endif
            endif
        until (sortie = true)
        // retour à la normale
        setSpriteColoralpha(idSpr,255)
        deleteSprite(sprBonus)
        for i = 1 to nombre_de_lignes
            deleteText(textes[i])
        next i
        fenetre_fermer()
    else
        if (son_onoff = true) then playSound(sndClicBonus0,80,0)
    endif
endfunction enplus

function iap_acheter_bonus(idSpr,idIap,nb,nom_bonus$)
    enplus = iap_acheter(idSpr,idIap,nb,nom_bonus$,false)
endfunction enplus

function iap_acheter_vie(idSpr,idIap,nb,nom_bonus$)
    enplus = iap_acheter(idSpr,idIap,nb,nom_bonus$,true)
endfunction enplus

function fenetre_ouvrir(ok_onoff,cancel_onoff,previous_onoff,next_onoff)
    // background de la fenêtre
    if (imgFenetre = 0)
        imgFenetre = loadImage("fenetre.png")
        sprFenetre = createSprite(imgFenetre)
        if (ecran_hauteur < getImageHeight(imgFenetre))
            fenetreRatio# = (ecran_hauteur-20.0) / getImageHeight(imgFenetre)
        else
            fenetreRatio# = 1
        endif
        setSpriteSize(sprFenetre,getImageWidth(imgFenetre)*fenetreRatio#,getImageHeight(imgFenetre)*fenetreRatio#)
        setSpritePosition(sprFenetre,(ecran_largeur-getSpriteWidth(sprFenetre))/2,(ecran_hauteur-getSpriteHeight(sprFenetre))/2)
        setSpriteActive(sprFenetre,false)
        fenText_x1 = (50+10)*fenetreRatio#+getSpriteX(sprFenetre)
        fenText_y1 = 120*fenetreRatio#+getSpriteY(sprFenetre)
        fenText_x2 = (450-10)*fenetreRatio#+getSpriteX(sprFenetre)
        fenText_y2 = 460*fenetreRatio#+getSpriteY(sprFenetre)
        fenBtn_x1 = 110*fenetreRatio#+getSpriteX(sprFenetre)
        fenBtn_y1 = 480*fenetreRatio#+getSpriteY(sprFenetre)
        fenBtn_x2 = 390*fenetreRatio#+getSpriteX(sprFenetre)
        fenBtn_y2 = 550*fenetreRatio#+getSpriteY(sprFenetre)
        fenStop_x1 = 400*fenetreRatio#+getSpriteX(sprFenetre)
        fenStop_y1 = 50*fenetreRatio#+getSpriteY(sprFenetre)
        fenStop_x2 = 450*fenetreRatio#+getSpriteX(sprFenetre)
        fenStop_y2 = 90*fenetreRatio#+getSpriteY(sprFenetre)
    endif
    setSpriteVisible(sprFenetre,true)
    setSpriteActive(sprFenetre,true)
    // boutons ok, suivant et précédent en bas de la fenêtre
    nb_boutons_bas = 0
    if (previous_onoff = true)
        inc nb_boutons_bas
        if (imgPrevious = 0)
            imgPrevious = loadImage("precedent.png")
            sprPrevious = createSprite(imgPrevious)
            setSpriteSize(sprPrevious,getImageWidth(imgPrevious)*fenetreRatio#,getImageHeight(imgPrevious)*fenetreRatio#)
            setSpriteActive(sprPrevious,false)
            setSpriteColorAlpha(sprPrevious,255)
        endif
    endif
    if (ok_onoff = true)
        inc nb_boutons_bas
        if (imgOk = 0)
            imgOk = loadImage("ok.png")
            sprOk = createSprite(imgOk)
            setSpriteSize(sprOk,getImageWidth(imgOk)*fenetreRatio#,getImageHeight(imgOk)*fenetreRatio#)
            setSpriteActive(sprOk,false)
            setSpriteColorAlpha(sprOk,255)
        endif
    endif
    if (next_onoff = true)
        inc nb_boutons_bas
        if (imgNext = 0)
            imgNext = loadImage("suivant.png")
            sprNext = createSprite(imgNext)
            setSpriteSize(sprNext,getImageWidth(imgNext)*fenetreRatio#,getImageHeight(imgNext)*fenetreRatio#)
            setSpriteActive(sprNext,false)
            setSpriteColorAlpha(sprNext,255)
        endif
    endif
    btn_num = 0
    if (previous_onoff = true)
        inc btn_num
        setSpritePosition(sprPrevious,fenBtn_x1+btn_num*(fenBtn_x2-fenBtn_x1-getSpriteWidth(sprPrevious))/(nb_boutons_bas+1),fenBtn_y1+(fenBtn_y2-fenBtn_y1-getSpriteHeight(sprPrevious))/2)
        setSpriteVisible(sprPrevious,true)
        setSpriteActive(sprPrevious,true)
    endif
    if (ok_onoff = true)
        inc btn_num
        setSpritePosition(sprOk,fenBtn_x1+btn_num*(fenBtn_x2-fenBtn_x1-getSpriteWidth(sprOk))/(nb_boutons_bas+1),fenBtn_y1+(fenBtn_y2-fenBtn_y1-getSpriteHeight(sprOk))/2)
        setSpriteVisible(sprOk,true)
        setSpriteActive(sprOk,true)
    endif
    if (next_onoff = true)
        inc btn_num
        setSpritePosition(sprNext,fenBtn_x1+btn_num*(fenBtn_x2-fenBtn_x1-getSpriteWidth(sprNext))/(nb_boutons_bas+1),fenBtn_y1+(fenBtn_y2-fenBtn_y1-getSpriteHeight(sprNext))/2)
        setSpriteVisible(sprNext,true)
        setSpriteActive(sprNext,true)
    endif
    // bouton cancel en haut à droite de la fenêtre
    if (cancel_onoff = true)
        if (imgCancel = 0)
            imgCancel = loadImage("cancel.png")
            sprCancel = createSprite(imgCancel)
            setSpriteSize(sprCancel,getImageWidth(imgCancel)*fenetreRatio#,getImageHeight(imgCancel)*fenetreRatio#)
            setSpriteActive(sprCancel,false)
            setSpriteColorAlpha(sprCancel,255)
        endif
        setSpritePosition(sprCancel,fenStop_x1+(fenStop_x2-fenStop_x1-getSpriteWidth(sprCancel))/2,fenStop_y1+(fenStop_y2-fenStop_y1-getSpriteHeight(sprCancel))/2)
        setSpriteVisible(sprCancel,true)
        setSpriteActive(sprCancel,true)
    endif
endfunction

function fenetre_fermer()
    setSpriteVisible(sprFenetre,false)
    setSpriteActive(sprFenetre,false)
    if (sprOk <> 0)
        setSpriteVisible(sprOk,false)
        setSpriteActive(sprOk,false)
    endif
    if (sprCancel <> 0)
        setSpriteVisible(sprCancel,false)
        setSpriteActive(sprCancel,false)
    endif
    if (sprNext <> 0)
        setSpriteVisible(sprNext,false)
        setSpriteActive(sprNext,false)
    endif
    if (sprPrevious <> 0)
        setSpriteVisible(sprPrevious,false)
        setSpriteActive(sprPrevious,false)
    endif
    // on attend que le clic ou l'appuit soit relaché avant de rendre la main
    while (getPointerState() = 1)
        sync()
    endwhile
endfunction

function fenetre_texte(texte1$,idImage,texte2$,btnOk,btnCancel,btnPrevious,btnNext)
    fenetre_ouvrir(btnOk,btnCancel,btnPrevious,btnNext)
    espacement = 10
    y = espacement+fenText_y1
    if (texte1$ <> "")
        txt1 = createText(texte1$)
        positionner_texte(txt1,y)
        y = y+espacement+getTextTotalHeight(txt1)
    endif
    if (idImage > 0)
        sprImage = createSprite(idImage)
        setSpriteSize(sprImage,getSpriteWidth(sprImage)*fenetreRatio#,getSpriteHeight(sprImage)*fenetreRatio#)
        setSpritePosition(sprImage,fenText_x1+(fenText_x2-fenText_x1-getSpriteWidth(sprImage))/2,y)
        setSpriteActive(sprImage,false)
        setSpriteVisible(sprImage,true)
        setSpriteColorAlpha(sprImage,255)
        y = y+espacement+getSpriteHeight(sprImage)
    endif
    if (texte2$ <> "")
        txt2 = createText(texte2$)
        positionner_texte(txt2,y)
        y = y+espacement+getTextTotalHeight(txt2)
    endif
    btnClique = 0
    sortie = false
    repeat
        sync()
        if (getPointerPressed() = 1)
            if (sprCancel > 0)
                if (1 = getSpriteActive(sprCancel)) and (1 = getSpriteHitTest(sprCancel,screenToWorldX(getPointerX()),screenToWorldY(getPointerY())))
                    sortie = true
                    btnClique = 0
                    if (son_onoff = true) then playSound(sndClic,80,0)
                endif
            endif
            if (sprOk > 0)
                if (1 = getSpriteActive(sprOk)) and (1 = getSpriteHitTest(sprOk,screenToWorldX(getPointerX()),screenToWorldY(getPointerY())))
                    sortie = true
                    btnClique = 1
                    if (son_onoff = true) then playSound(sndClic,80,0)
                endif
            endif
            if (sprNext > 0)
                if (1 = getSpriteActive(sprNext)) and (1 = getSpriteHitTest(sprNext,screenToWorldX(getPointerX()),screenToWorldY(getPointerY())))
                    sortie = true
                    btnClique = 2
                    if (son_onoff = true) then playSound(sndClic,80,0)
                endif
            endif
            if (sprPrevious > 0)
                if (1 = getSpriteActive(sprPrevious)) and (1 = getSpriteHitTest(sprPrevious,screenToWorldX(getPointerX()),screenToWorldY(getPointerY())))
                    sortie = true
                    btnClique = 3
                    if (son_onoff = true) then playSound(sndClic,80,0)
                endif
            endif
        endif
    until (sortie = true)
    if (texte1$ <> "") then deleteText(txt1)
    if (idImage > 0) then deleteSprite(sprImage)
    if (texte2$ <> "") then deleteText(txt2)
    fenetre_fermer()
endfunction btnClique
