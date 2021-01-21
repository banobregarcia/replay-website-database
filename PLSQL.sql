alter SESSION set NLS_DATE_FORMAT = 'DD-MM-YYYY HH24:MI:SS';
set serveroutput on

--1. Définir une fonction qui convertit au format json les informations d’une vidéo.
create or replace FUNCTION to_json (id_Video VIDEO.idVideo%TYPE)
RETURN nvarchar2
IS
        msg nvarchar2(500);
        uplet VIDEO%ROWTYPE;
BEGIN   
	IF id_Video < 0 THEN
		RAISE_APPLICATION_ERROR(-20000,'Numero identifiant incorrect ') ;
	END IF;

	SELECT * INTO UPLET FROM VIDEO
	WHERE idVideo = id_Video;
        
	IF SQL%NOTFOUND then
	RAISE_APPLICATION_ERROR(-20000,'aucune video correspond a l identifiant ') ;
	ELSE 
 		msg := '[{' || CHR(10) || CHR(9) || '"idEmsission": "' || uplet.idEmission || '", '
		|| CHR(10) || CHR(9) || '"idVideo": "' || uplet.idVideo || '", '
		|| CHR(10) || CHR(9) || '"nomVideo": "' || uplet.nomVideo || '", '
		|| CHR(10) || CHR(9) || '"Description": "' || uplet.descript || '", '
		|| CHR(10) || CHR(9) || '"Durée": "' || uplet.duree || '", '
		|| CHR(10) || CHR(9) || '"Première Diffussion": "' || uplet.anneepremierediff || '", '
		|| CHR(10) || CHR(9) || '"Pays": "' || uplet.pays || '", '
		|| CHR(10) || CHR(9) || '"Multilangue": "' || uplet.multilangue || '", '
		|| CHR(10) || CHR(9) || '"FormatImage": "' || uplet.formatImage || '"}]' || u'\000A';
	END IF;
        
        return  msg ;
END;
/

select to_json(2) from dual;

--Line feed	CHR(10)
--Tab	 CHR(9)

--2. Définir une procédure qui généra un texte initial de la newsletter en y ajoutant la liste de toute les sortie de la semaine.
CREATE OR REPLACE PROCEDURE newsletter
IS
    CURSOR newsletter IS SELECT V.IDEMISSION IDEMISSION,
    V.IDVIDEO IDVIDEO,
    V.NOMVIDEO NOMVIDEO,
    V.DESCRIPT DESCRIPT,
    V.DUREE DUREE,
    V.ANNEEPREMIEREDIFF ANNEEPREMIEREDIFF,
    V.PAYS PAYS,
    V.MULTILANGUE MULTILANGUE,
    V.FORMATIMAGE FORMATIMAGE,
    VD.DATESORTIE DATESORTIE
    FROM VIDEO V, VIDEO_NEW_DISPONIBILITE VD WHERE V.idVideo = VD.idVideo
    AND VD.dateSortie > sysdate AND VD.dateSortie <= sysdate+7;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Bienvenu(e) chez Fotflix, ta page de rédiffussion des émissions préferée! '||'Voici la liste des sorties de cette semaine: ');
    FOR uplet IN newsletter LOOP
      DBMS_OUTPUT.PUT_LINE(uplet.idVideo || ' ' ||uplet.nomVideo|| ' ' ||uplet.descript|| ' ' ||
      uplet.anneepremierediff|| ' ' ||uplet.duree|| ' ' ||uplet.pays|| ' ' ||uplet.multilangue|| ' ' ||uplet.formatimage|| ' ' ||uplet.dateSortie);
    END LOOP;
END;
/

--test
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,1,1,sysdate+1);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,1,2,sysdate+2);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,3,12,sysdate+3);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,5,24,sysdate+1);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,5,25,sysdate+2);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,5,26,sysdate+3);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,5,27,sysdate+4);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,5,30,sysdate+5);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,5,29,sysdate+1);

EXEC newsletter;

--3. Générer la liste des vidéos populaires, conseillé pour un utilisateur, c’est à dire en fonction des catégories de vidéos qu’il suit.

CREATE OR REPLACE PROCEDURE popular (id_User UTILISATEUR.idUser%TYPE)
IS
    CURSOR pop IS  SELECT nomCategorie,  idVideo, idEmission, nomVideo, descript, nbVisionnages FROM (
    SELECT C.nomCategorie nomCategorie,  VE.idVideo idVideo, VE.idEmission idEmission, V.nomVideo nomVideo, V.descript descript, count(H.idVideo) AS nbVisionnages
    FROM USER_AIME_CATEGORIE UAC, VIDEO_EMISSION VE, EMISSION E, HISTORIQUE H, CATEGORIE C, VIDEO V
    WHERE H.dateRep between SYSDATE - 15 AND SYSDATE
    AND UAC.idCategorie = C.idCategorie
    AND VE.idVideo = V.idVideo
    AND UAC.idUser = id_User
    AND UAC.idCategorie = E.idCategorie
    AND E.idEmission = VE.idEmission
    AND VE.idVideo = H.idVideo
    GROUP BY C.nomCategorie, VE.IdVideo, VE.idEmission, V.nomVideo, V.descript
    ORDER BY nbVisionnages desc
) WHERE ROWNUM < 5; --On rajoute que les 4 plus populaires
BEGIN  
    FOR uplet IN pop LOOP
        DBMS_OUTPUT.PUT_LINE(uplet.nomCategorie ||' IdVideo: '|| uplet.IdVideo ||' idEmission: '|| uplet.idEmission ||' nomVideo: '|| uplet.nomVideo 
        ||' Description: '|| uplet.descript ||' Nb de vues ces deux dernières semaines: '||uplet.nbVisionnages);
         INSERT INTO SUGGESTIONS(idUser,idVideo,typeSug) VALUES (id_User,uplet.idVideo,'PP');
    END LOOP;
END;
/

EXEC popular(7);
SHOW ERRORS;



