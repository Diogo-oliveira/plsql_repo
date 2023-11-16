CREATE OR REPLACE VIEW V_DEATH_FETALS_PIVOT AS
SELECT *  FROM TABLE
( PIVOT(
       'select id_Death_registry,  d.internal_name, xvalue
        FROM V_DEATH_FETALS_RAW  d'
       )
);
