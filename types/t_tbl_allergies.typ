DECLARE
    PROCEDURE run_ddl(i_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE i_sql;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('WARNING - ' || replace(SRCSTR => SQLERRM, OLDSUB => 'ORA-', NEWSUB => '') || '; ' || i_sql || ';');
    END run_ddl;

BEGIN

    run_ddl(i_sql => 'DROP TYPE t_tbl_allergies');
		run_ddl(i_sql => 'DROP TYPE t_rec_allergy');
		
		run_ddl(i_sql => '	
		CREATE OR REPLACE TYPE t_rec_allergy force AS OBJECT
		(
				id_allergy number(12),
				id_pat_allergy number(24),
				id_episode number(24) ,
				allergen varchar2(4000 CHAR),
				type_reaction varchar2(800 CHAR),
				onset number(4),
				dt_pat_allergy varchar2(800 CHAR),
				flg_type varchar2(1 CHAR),
				flg_status varchar2(1 CHAR),
				status_desc  VARCHAR2(4000 CHAR),
				rank number(6),
				status_string VARCHAR2(800 CHAR),
				id_allergy_severity number(24),
				severity varchar2(4000 CHAR),
				status_color VARCHAR2(8 CHAR),
				free_text varchar2(200 CHAR),
				with_notes varchar2(4000 CHAR),
				cancelled_with_notes varchar2(4000 CHAR),
				title_notes varchar2(4000 CHAR),
				allergy  varchar2(4000 CHAR),
				desc_speciality VARCHAR2(200 CHAR),
				nick_name varchar2(800 CHAR),
				type varchar2(800 CHAR),
				status varchar2(800 CHAR),
				hour_target number(4),
				viewer_category varchar2(5 CHAR),
				viewer_category_desc varchar2(4000 CHAR),
				viewer_id_prof number(24),
				viewer_id_epis number(24),
				viewer_date varchar2(800 CHAR),
				notes varchar2(4000 CHAR),
				reviewed number(24),
				symptoms varchar2(1000 CHAR),
				flg_type_rep varchar2(1 CHAR),
				flg_source_rep varchar2(1 CHAR),
				id_allergy_parent     number(12) ,
				allergy_parent_desc     VARCHAR2(4000 CHAR),
				severity_desc           VARCHAR2(4000 CHAR),
				severity_alert_desc     VARCHAR2(4000 CHAR),
				id_symptoms             table_varchar,
				id_content_symptoms     table_varchar,
				symptoms_desc           table_varchar,
				symptoms_alert_desc     table_varchar,
				id_drug_ingredient    VARCHAR2(1000 CHAR),
				drug_ingredient_desc  VARCHAR2(4000 CHAR),
				start_date_app_format VARCHAR2(100 CHAR),
				start_date VARCHAR2(100 CHAR),
				id_content VARCHAR2(200 CHAR),
				id_content_parent VARCHAR2(200 CHAR),
				update_time timestamp(6) with local time zone      
				
		)');
			
		run_ddl(i_sql => ' CREATE OR REPLACE TYPE t_tbl_allergies IS TABLE OF t_rec_allergy ');
		
END;
/