PROMPT CREATE_TRANSLATION_NEW

CREATE TABLE TRANSLATION_NEW AS
    SELECT cast( rownum  as number(24) ) id_translation, t.*
      FROM (SELECT 
      cast( code_translation as varchar2(200 char) )  code_translation
      ,
       max(CASE            WHEN id_language =  1 THEN             desc_translation       else ''        END) DESC_LANG_1,
       max(case            WHEN id_language =  2 THEN             desc_translation       else ''        end ) DESC_LANG_2,
       max(case            WHEN id_language =  3 THEN             desc_translation       else ''        end ) DESC_LANG_3,
       max(case            WHEN id_language =  4 THEN             desc_translation       else ''        end ) DESC_LANG_4,
       max(case            WHEN id_language =  5 THEN             desc_translation       else ''        end ) DESC_LANG_5,
       max(case            WHEN id_language =  6 THEN             desc_translation       else ''        end ) DESC_LANG_6,
       max(case            WHEN id_language =  7 THEN             desc_translation       else ''        end ) DESC_LANG_7,
       max(case            WHEN id_language =  8 THEN             desc_translation       else ''        end ) DESC_LANG_8,
       max(case            WHEN id_language =  9 THEN             desc_translation       else ''        end ) DESC_LANG_9,
       max(case            WHEN id_language = 10 THEN             desc_translation       else ''        end ) DESC_LANG_10,
       max(case            WHEN id_language = 11 THEN             desc_translation       else ''        end ) DESC_LANG_11,
       max(case            WHEN id_language = 12 THEN             desc_translation       else ''        end ) DESC_LANG_12,
       max(case            WHEN id_language = 13 THEN             desc_translation       else ''        end ) DESC_LANG_13,
       max(case            WHEN id_language = 14 THEN             desc_translation       else ''        end ) DESC_LANG_14,
       max(case            WHEN id_language = 15 THEN             desc_translation       else ''        end ) DESC_LANG_15,
       max(case            WHEN id_language = 16 THEN             desc_translation       else ''        end ) DESC_LANG_16,
       max(case            WHEN id_language = 17 THEN             desc_translation       else ''        end ) DESC_LANG_17
  FROM translation
 group by code_translation) t
 /
 
PROMPT CREATE PRIMARY KEY  TRNSLTN_PK 
ALTER TABLE TRANSLATION_NEW ADD CONSTRAINT TRNSLTN_PK PRIMARY KEY( CODE_TRANSLATION ) USING INDEX TABLESPACE INDEX_L;


PROMPT GIVING PRIVILEDGES TO NEW TABLE
declare

l_GRANT_SQL  constant varchar2(1000 char) := 'GRANT :1 ON :2 TO :3';
L_TABLE      constant varchar2(0050 char) := 'TRANSLATION';
L_PRIV       varchar2(0050 char);
L_GRANTEE    varchar2(0050 char) ;
l_obj				 varchar2(0050 char) ;
L_SQL        VARCHAR2(1000);

cursor c_privs is
    select * from all_tab_privs where table_name = L_TABLE and grantee != 'ALERT';

begin

-- privilegios para nova tabela

		<<LOOP_THRU_PRIVS>>
		for prv in c_privs loop
		  
				L_GRANTEE := PRV.GRANTEE;
				L_PRIV    := PRV.PRIVILEGE;
				
			  L_SQL := L_GRANT_SQL;
		
		    L_SQL := REPLACE ( L_SQL, ':1', L_PRIV );
		    L_SQL := REPLACE ( L_SQL, ':2', 'TRANSLATION_NEW' );
		    L_SQL := REPLACE ( L_SQL, ':3', L_GRANTEE );
		
			  DBMS_OUTPUT.PUT_LINE( L_SQL  );
		
		
		    EXECUTE IMMEDIATE L_SQL;
		end loop LOOP_THRU_PRIVS;
  
end;
/


PROMPT RENAME OLD TRANSLATION
ALTER TABLE ALERT.TRANSLATION RENAME TO TRANSLATION_BCK_2604;

PROMPT RENAME NEW TRANSLATION
ALTER TABLE TRANSLATION_NEW RENAME TO TRANSLATION;

PROMPT CREATE TYPE T_SEARCH
CREATE OR REPLACE TYPE T_SEARCH AS OBJECT
(
CODE_TRANSLATION VARCHAR2(4000),
DESC_TRANSLATION VARCHAR2(4000),
POSITION         NUMBER,
RELEVANCE        NUMBER(24, 23)
);
/

PROMPT CREATE TABLE_T_SEARCH;
CREATE OR REPLACE TYPE TABLE_T_SEARCH AS TABLE OF T_SEARCH;
/

