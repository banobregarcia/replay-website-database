1. Nombre de visionnages de vidéos par catégories de vidéos, 
pour les visionnages de moins de deux semaines;

SELECT C.nomCategorie, count(H.idVideo) AS nbVisionnages
FROM HISTORIQUE H, CATEGORIE C, VIDEO V, EMISSION E
WHERE H.dateRep between SYSDATE-15 AND SYSDATE
AND H.idVideo = V.idVideo
AND V.idEmission = E.idEmission
AND C.idCategorie = E.idCategorie
GROUP BY C.nomCategorie;

2. Par utilisateur, le nombre d abonnement, de favoris et de vidéos visionnées;

WITH abonnements AS (
SELECT COUNT(*)-1 AS nb_abonnement, U.idUser
    FROM USER_ABONNE_EMISSION UAE
             RIGHT OUTER JOIN UTILISATEUR U
             ON U.idUser = UAE.idUser
             WHERE UAE.idUser IS NULL
             GROUP BY U.idUser
    UNION
SELECT count(*) AS nb_abonnement, U.idUser
FROM UTILISATEUR U, USER_ABONNE_EMISSION UAE
WHERE U.idUser = UAE.idUser
GROUP BY U.idUser
),

videosvus AS (
SELECT COUNT(*)-1 AS nb_videos_vues, U.idUser
    FROM HISTORIQUE H
            RIGHT OUTER JOIN UTILISATEUR U
            ON U.idUser = H.idUser
            WHERE H.idUser IS NULL
            GROUP BY U.idUser
    UNION
SELECT count(*) AS nb_videos_vues,  U.idUser
FROM HISTORIQUE H, UTILISATEUR U
WHERE H.idUser = U.idUser
GROUP BY U.idUser
),

videosfavoris AS (
SELECT COUNT(*)-1 AS nb_videos_fav, U.idUser
    FROM USER_FAVORIS_VIDEO UFV
            RIGHT OUTER JOIN UTILISATEUR U
            ON U.idUser = UFV.idUser
            WHERE UFV.idUser IS NULL
            GROUP BY U.idUser
    UNION
SELECT count(*) AS nb_videos_fav, U.idUser
FROM UTILISATEUR U, USER_FAVORIS_VIDEO UFV
WHERE U.idUser = UFV.idUser
GROUP BY U.idUser
)

SELECT ab.idUser, nb_abonnement, nb_videos_fav, nb_videos_vues
FROM abonnements ab, videosvus vv, videosfavoris vf
WHERE ab.idUser = vv.idUser
AND ab.idUser = vf.idUser
AND vv.idUser = vf.idUser
ORDER BY idUser;
            
3.Pour chaque vidéo, le nombre de visionnages par des utilisateurs français, le nombre de
visionnage par des utilisateurs allemands, la différence entre les deux, triés par valeur
absolue de la différence entre les deux;

WITH vissionnages AS (
SELECT COUNT(*)-1 AS nb_videos_vues,  V.idVideo
FROM HISTORIQUE H
        RIGHT OUTER JOIN VIDEO V
        ON V.idVideo = H.idVideo
        WHERE H.idVideo IS NULL
        GROUP BY V.idVideo
UNION
SELECT count(*) AS nb_videos_vues,  V.idVideo
FROM HISTORIQUE H
    INNER JOIN VIDEO V
    ON V.idVideo = H.idVideo
    GROUP BY V.idVideo
),

vissionnages_allemands AS (
SELECT COUNT(*)-1 AS nb_videos_vues_de, V.idVideo
    FROM HISTORIQUE H
             RIGHT OUTER JOIN VIDEO V
             ON V.idVideo = H.idVideo
             WHERE H.idVideo IS NULL
             GROUP BY V.idVideo
    UNION
SELECT count(*) AS nb_videos_vues_de, V.idVideo
FROM VIDEO V, HISTORIQUE H, UTILISATEUR U
WHERE V.idVideo =H.idVideo
AND H.idUser = U.idUser
AND U.nationalite LIKE 'Germany'
GROUP BY V.idVideo
),

vissionnages_francais AS (
SELECT COUNT(*)-1 AS nb_videos_vues_fr, V.idVideo
    FROM HISTORIQUE H
             RIGHT OUTER JOIN VIDEO V
             ON V.idVideo = H.idVideo
             WHERE H.idVideo IS NULL
             GROUP BY V.idVideo
    UNION
SELECT count(*) AS nb_videos_vues_fr, V.idVideo
FROM VIDEO V, HISTORIQUE H, UTILISATEUR U
WHERE V.idVideo =H.idVideo
AND H.idUser = U.idUser
AND U.nationalite LIKE 'France'
GROUP BY V.idVideo
)

SELECT AAA.idVideo, viewsDE, viewsFR, ABS(viewsDE - viewsFR) as DIFF FROM (
SELECT V.idVideo, nvl(nb_videos_vues_de,0) AS viewsDE, nvl(nb_videos_vues_fr,0) AS viewsFR
FROM vissionnages V
FULL JOIN vissionnages_allemands va ON V.idVideo = va.idVideo
FULL JOIN vissionnages_francais vf ON V.idVideo = vf.idVideo
ORDER BY V.idVideo
) AAA
ORDER BY DIFF;

4.Les 10 couples de vidéos apparaissant le plus souvent simultanément dans un historique de
visionnage d’utilisateur;

SELECT vissionnages, idVideo1, idVideo2 FROM (
    SELECT DISTINCT COUNT(*) AS vissionnages,hist1 AS idVideo1, hist2 AS idVideo2
    FROM (
        SELECT H1.idVideo AS hist1, H2.idVideo AS hist2
        FROM HISTORIQUE H1, HISTORIQUE H2
        WHERE H1.idVideo != H2.idVideo
        AND H1.dateRep = H2.dateRep
        AND H1.idVideo <= H2.idVideo
        )
    GROUP BY hist1,hist2
    ORDER BY vissionnages DESC
    ) 
 WHERE ROWNUM < 11;


