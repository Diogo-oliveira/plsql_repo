/*-- Last Change Revision: $Rev: 2028702 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:25 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_gen_area_rank IS

    -- Author  : JOAO.RIBEIRO
    -- Created : 04-11-2008 14:27:42
    -- Purpose : Viewer order algorithms (base struture)

    FUNCTION get_rank
    (
        i_institution IN gen_area_rank.id_institution%TYPE,
        i_area        IN gen_area_rank.area%TYPE,
        i_values      IN table_varchar,
        o_rank_value  OUT gen_area_rank.rank_value%TYPE,
        o_rank_order  OUT gen_area_rank.rank_order%TYPE
    ) RETURN BOOLEAN;
		
		FUNCTION get_rank
    (
        i_institution             IN gen_area_rank.id_institution%TYPE,
        i_area                    IN gen_area_rank.area%TYPE,
        i_values_varch            IN table_varchar,
				i_values_numb             IN table_number,
				i_values_tstz             IN table_timestamp_tz,
		    o_rank_value              OUT gen_area_rank.rank_value%TYPE,
        o_rank_order              OUT gen_area_rank.rank_order%TYPE
    ) RETURN BOOLEAN;
		
    FUNCTION get_rank
    (
        i_institution  IN gen_area_rank.id_institution%TYPE,
        i_area         IN gen_area_rank.area%TYPE,
        i_values_varch IN table_varchar,
        i_values_numb  IN table_number,
        i_values_tstz  IN table_timestamp_tz
        
    ) RETURN rank_values_type;

    g_package_name VARCHAR2(50);
	g_exception exception;

END pk_gen_area_rank;
/
