/*-- Last Change Revision: $Rev: 2028529 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:20 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_translation IS
    /***
    WARNING: stub package for PRD 
    ***/

    PROCEDURE set_read_translation
    (
        i_code        IN translation.code_translation%TYPE,
        i_table_name  IN user_tables.table_name%TYPE,
        i_val         IN sys_domain.val%TYPE DEFAULT NULL,
        i_software    IN software.id_software%TYPE DEFAULT NULL,
        i_institution IN software.id_software%TYPE DEFAULT NULL
    );

    PROCEDURE set_read_translation
    (
        i_codes       IN table_varchar,
        i_table_name  IN user_tables.table_name%TYPE,
        i_software    IN software.id_software%TYPE DEFAULT NULL,
        i_institution IN software.id_software%TYPE DEFAULT NULL
    );
    PRAGMA RESTRICT_REFERENCES(DEFAULT, RNDS, RNPS, WNDS, WNPS);
END pk_backoffice_translation;
/
