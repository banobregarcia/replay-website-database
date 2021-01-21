--Contraintes d’intégrité
--Réaliser les différentes contraintes d'intégrité spécifiées dans le sujet du projet (contraintes statiques et contraintes dynamiques).
alter SESSION set NLS_DATE_FORMAT = 'DD-MM-YYYY HH24:MI:SS';
set serveroutput on

CREATE OR REPLACE TRIGGER ajoutVideoFav
AFTER INSERT ON USER_FAVORIS_VIDEO
FOR EACH ROW
BEGIN
    INSERT INTO SUGGESTIONS(idUser,idVideo,typeSug) VALUES (:new.idUser,:new.idVideo,'FV');
END;
/

INSERT INTO USER_FAVORIS_VIDEO(idUser,idVideo) VALUES (1,1);

CREATE OR REPLACE TRIGGER deleteVideoFav
BEFORE DELETE ON USER_FAVORIS_VIDEO
FOR EACH ROW
BEGIN
    DELETE FROM SUGGESTIONS WHERE :old.idUser = idUser AND :old.idVideo = idVideo;
END;
/

DELETE FROM USER_FAVORIS_VIDEO WHERE idUser = 1 AND idVideo = 1;

CREATE OR REPLACE PROCEDURE ajoutSugg_NW(id_User UTILISATEUR.idUser%TYPE)
IS
    CURSOR sug_new IS SELECT UAE.idUser, VE.idVideo, VND.dateSortie
        FROM USER_ABONNE_EMISSION UAE, VIDEO_NEW_DISPONIBILITE VND,VIDEO_EMISSION VE
        WHERE UAE.idEmission = VE.idEmission AND VE.idVideo = VND.idVideo AND UAE.idUser = id_User AND VND.dateSortie >= sysdate;
BEGIN
    FOR uplet IN sug_new LOOP
        INSERT INTO SUGGESTIONS(idUser,idVideo,typeSug) VALUES (uplet.idUser,uplet.idVideo,'NW');
    END LOOP;
END;
/

EXEC ajoutSugg_NW(5);

--J'ai décidé que les vidéos proches à la fin sont celles qui ont leur date de fin entre sysdate et sysdate+2
CREATE OR REPLACE PROCEDURE ajoutSugg_FD(id_User UTILISATEUR.idUser%TYPE)
IS
    CURSOR sug_end IS SELECT UAE.idUser, VE.idVideo, VED.dateFin
        FROM USER_ABONNE_EMISSION UAE, VIDEO_END_DISPONIBILITE VED,VIDEO_EMISSION VE
        WHERE UAE.idEmission = VE.idEmission AND VE.idVideo = VED.idVideo AND UAE.idUser = id_User AND VED.dateFin > sysdate AND VED.dateFin < sysdate +2;
BEGIN
    FOR uplet IN sug_end LOOP
        INSERT INTO SUGGESTIONS(idUser,idVideo,typeSug) VALUES (uplet.idUser,uplet.idVideo,'FD');
    END LOOP;
END;
/

--test
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,1,1,sysdate-1);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,1,2,sysdate-2);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,3,12,sysdate-3);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,5,24,sysdate-1);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,5,25,sysdate-2);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,5,26,sysdate-3);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,5,27,sysdate-4);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,5,30,sysdate-5);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (1,5,29,sysdate-1);

INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (2,1,1,sysdate-1);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (2,1,2,sysdate-2);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (2,3,12,sysdate-3);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (2,5,24,sysdate-4);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (2,5,25,sysdate-5);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (2,5,26,sysdate-1);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (2,5,27,sysdate-3);

EXEC ajoutSugg_FD(1);



1. Un utilisateur aura un maximum de 300 vidéos en favoris;

CREATE OR REPLACE TRIGGER maxFav
BEFORE INSERT OR UPDATE
ON USER_FAVORIS_VIDEO
FOR EACH ROW
DECLARE
    nrow Integer;
BEGIN
    SELECT count(*) INTO nrow
    FROM USER_FAVORIS_VIDEO
    WHERE :new.idUser=USER_FAVORIS_VIDEO.idUser;

    IF nrow >= 300
    THEN
        RAISE_APPLICATION_ERROR(-20001, 'Maximum de 300 vidéos en favoris atteint');
    END IF;
END;
/

--Pour tester j'ai mis 5 au lieu de 300 dans le Trigger
INSERT INTO USER_FAVORIS_VIDEO(idUser,idVideo) VALUES (1,13);
INSERT INTO USER_FAVORIS_VIDEO(idUser,idVideo) VALUES (1,14);
INSERT INTO USER_FAVORIS_VIDEO(idUser,idVideo) VALUES (1,15);
INSERT INTO USER_FAVORIS_VIDEO(idUser,idVideo) VALUES (1,1);
INSERT INTO USER_FAVORIS_VIDEO(idUser,idVideo) VALUES (1,2);
INSERT INTO USER_FAVORIS_VIDEO(idUser,idVideo) VALUES (1,3);

2. Si une diffusion d’une émission est ajoutée, les dates de disponibilités seront mises à jour. La nouvelle date de fin de disponibilité sera la date de la dernière diffusion plus 14 jours;

--Quand on rajoute une prémière diffussion disponible inmédiament et pendant 7 jours
CREATE OR REPLACE TRIGGER ajoutVideo
AFTER INSERT
ON VIDEO
FOR EACH ROW
BEGIN
    INSERT INTO VIDEO_EMISSION(idEmission,idVideo) VALUES (:new.idEmission,:new.idVideo);
    INSERT INTO VIDEO_NEW_DISPONIBILITE(idVideo,dateSortie) VALUES (:new.idVideo,sysdate); 
    INSERT INTO VIDEO_END_DISPONIBILITE(idVideo,dateFin) VALUES(:new.idVideo,sysdate+7);
END;
/

--test
INSERT INTO VIDEO(idEmission,idVideo,nomVideo,descript,duree,anneepremierediff,pays) VALUES (5,31,'Se va a armar la de dios','Episodio 8 de la temporada 1',54,2017,'España');

ALTER TRIGGER ajoutVideo DISABLE;

CREATE OR REPLACE TRIGGER ajoutDiff
BEFORE INSERT OR UPDATE
ON VIDEO_NEW_DISPONIBILITE
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO VIDEO_END_DISPONIBILITE(idVideo,dateFin) VALUES(:new.idVideo, :new.dateSortie+7);
    END IF;
    IF UPDATING THEN
        UPDATE VIDEO_END_DISPONIBILITE SET dateFin = :new.dateSortie+14 WHERE idVideo = :new.idVideo;
    END IF;
END;
/

--test
INSERT INTO VIDEO_NEW_DISPONIBILITE VALUES (1,to_date('2020-12-20 00:43:07','YYYY-MM-DD HH24:MI:SS'));
UPDATE VIDEO_NEW_DISPONIBILITE SET dateSortie = to_date('2020-12-21 00:43:07','YYYY-MM-DD HH24:MI:SS') WHERE idVideo = 1;
DELETE FROM VIDEO_NEW_DISPONIBILITE WHERE idVideo = 1;

3. La suppression d’une vidéo entraînera son archivage dans une tables des vidéos qui ne sont plus accessibles par le site de replay;

CREATE OR REPLACE TRIGGER deleteVideo
BEFORE DELETE
ON VIDEO
FOR EACH ROW
BEGIN
	INSERT INTO ARCHIVE_VIDEO(idEmission,idVideo,nomVideo,descript,duree,anneepremierediff,pays,multilangue,formatImage,dateDelete)
	VALUES(:old.idEmission,:old.idVideo,:old.nomVideo,:old.descript,:old.duree,:old.anneepremierediff,:old.pays,:old.multilangue,:old.formatImage, SYSDATE);
END;
/

--test
DELETE FROM VIDEO WHERE idVideo = 4;

4. Afin de limiter le spam de visionnage, un utilisateur ne pourra pas lancer plus de 3 visionnages par minutes.

CREATE OR REPLACE TRIGGER spam
BEFORE INSERT ON HISTORIQUE
FOR EACH ROW
DECLARE
    CURSOR cursor_spam IS SELECT * FROM HISTORIQUE WHERE :new.idUser =idUser and (:new.dateRep-dateRep)<1/(24*60);
    compt_v number := 1;
BEGIN
    FOR nb_videos IN cursor_spam 
    LOOP
    compt_v := compt_v +1;
    END LOOP;
    if (compt_v > 3)
    THEN
		RAISE_APPLICATION_ERROR(-20004, 'Atteint le nombre maximun de vissionnages par minute');
    ELSE
        DBMS_OUTPUT.PUT_LINE(compt_v||' vidéos regardées dans la minute');
    END IF;
END;
/

ALTER TRIGGER spam ENABLE;

--test
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (2,1,1,sysdate);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (2,1,2,sysdate);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (2,3,12,sysdate);
INSERT INTO HISTORIQUE(idUser,idEmission,IdVideo,dateRep) VALUES (2,5,24,sysdate);

